# 場館空間租借系統 — 資料庫總覽 v0.3

> 給主管確認用 ｜ 2026/05/20
> 對應檔案：`VENUE-ERD-v0.3.dbml`
> 前一版：`VENUE-ERD-v0.2.dbml`

---

## v0.3 主要調整（vs v0.2）

| # | 調整 | 原因 |
|---|---|---|
| 1 | `bookings` 改名為 **`orders`** | 避開 PostgreSQL 保留字 `order` |
| 2 | `events.booking_id` → **`events.order_id`** | 跟改名一致 |
| 3 | 計費系統重構：**時間 / 類型+金額 兩拆 + 組合** | 自由組合方案、加新方案不用動 schema |
| 4 | 新增 `plan_template_time`（純時段庫） | 共用時段定義 |
| 5 | `plan_items` 改名 `plan_template_items` | 連 plan_template + 含 type+name+price |
| 6 | `plan_template` 改成「組合表」 | space_id + time_id + item_id |
| 7 | `plans` 改 FK 為 `plan_template_id` + 加 `event_id` | 連結 plan_template 跟對應 event |
| 8 | `plan_item_type` 改名 `plan_template_item_type`（5 大類）| 細分由 name 表達 |
| 9 | 待定：order ↔ plans 是否要中介表 | 目前用 1:N 直接 FK |

---

## 系統概述

**沃茲新創空間** 場館租借系統，**13 張資料表 + 9 個 ENUM**，分 9 個模組。

---

## 📑 模組總覽

| 模組 | 表 |
|---|---|
| 1. 場館與空間 | `venues`, `spaces` |
| 2. 資源主表 | `resources`, `staff`, `customer` |
| 3. 會員等級 | `membership_tiers` |
| 4. 方案與計價 | `plan_template_time`, `plan_template_items`, `plan_template` |
| 5. 訂單 | `orders` |
| 6. 訂單明細 | `plans` |
| 7. 事件 | `events` |
| 8. 事件↔資源 | `event_resource` |
| 9. 稽核 | `event_log` |

---

# 🏷️ ENUMS（9 個）

## 1. `resource_type`
| 值 | 中文 |
|---|---|
| `staff` | 員工 |
| `customer` | 客戶 |
| `space` | 空間 |

## 2. `staff_type`（陣列）
| 值 | 中文 |
|---|---|
| `setup` | 場地佈置 |
| `service` | 專人服務 |

## 3. `event_type`（9 種）
| 值 | 中文 |
|---|---|
| `staff_availability` | 員工可上班時間 |
| `staff_shift_on_duty` | 排班上班 |
| `staff_shift_off_duty` | 排班休假 |
| `staff_shift_overtime` | 加班 |
| `booking_inquiry` | 訂單諮詢 |
| `booking_proposed_slot` | 候選時段 |
| `booking_rental` | 訂單主租借時段 |
| `booking_setup` | 場地佈置 |
| `booking_service` | 專人服務 |

## 4. `event_resource_role`
| 值 | 中文 |
|---|---|
| `performer` | 執行者（員工） |
| `subject` | 服務對象（客戶） |
| `location` | 地點資源（空間） |

## 5. `weekday`
| 值 | 中文 |
|---|---|
| `mon` ~ `sun` | 週一~週日 |

## 6. `plan_template_item_type` 🔄（取代 plan_item_type）

| 值 | 用途 | 細分（由 name 表達） |
|---|---|---|
| `rental` | 時段租金 | 平日小時/假日小時/平日夜間/假日夜間/平日半日/假日半日/平日全日/假日全日/歡樂時光... |
| `deposit` | 押金 | 押金（先收後退）|
| `headcount` | 人數費 | 人數費（15內）/ 人數費（16+）|
| `cleanup` | 環境維護 | 環境維護（15內）/ 環境維護（16+）|
| `service` | 專人服務 | 半自助服務 / 全配置服務 |

## 7. `booking_source`
| 值 | 中文 |
|---|---|
| `line_official` | LINE 官方 |
| `phone` | 電話 |
| `referral` | 介紹 |
| `walk_in` | 直接上門 |
| `website` | 官網 |
| `other` | 其他 |

## 8. `tier_qualification_type`
| 值 | 中文 |
|---|---|
| `stored_value` | 儲值金額 |
| `purchase_amount` | 累積消費金額 |

## 9. `log_type`
| 值 | 中文 |
|---|---|
| `insert` / `update` / `delete` | 操作類型 |

---

# 📚 13 張資料表詳細

## 1. `venues` — 場館主檔

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵 |
| `name` | text | ✓ | 場館名稱 |
| `address` | text | | 完整地址 |
| `phone` | text | | 場館電話 |
| `sort_order` | int | ✓ | 顯示順序 |
| `notes` | jsonb | | 備註 |
| `created_at` / `updated_at` / `deleted_at` | timestamptz | | 時間戳記 + 軟刪除 |

## 2. `spaces` — 空間（resources sub-table）

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵（同時 FK 到 resources.id） |
| `venue_id` | uuid | ✓ | 所屬場館 |
| `capacity` | int | | 最大容納人數 |
| `sort_order` | int | ✓ | 顯示順序 |
| `created_at` / `updated_at` / `deleted_at` | timestamptz | | 時間戳記 |

## 3. `resources` — 統一資源主表

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵 |
| `type` | enum | ✓ | 員工/客戶/空間 |
| `code` | text | ✓ | 代碼 |
| `name` | text | ✓ | 名稱 |
| `notes` | jsonb | | 備註 |
| `created_at` / `updated_at` / `deleted_at` | timestamptz | | 時間戳記 |

## 4. `staff` — 員工細節

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 同 resources.id |
| `phone` | text | | 員工電話 |
| `type` | `staff_type[]` | ✓ | 技能陣列 |
| `hired_at` | date | | 入職日期 |

## 5. `customer` — 客戶細節

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 同 resources.id |
| `phone` | text | ✓ | 客戶電話 |
| `line_id` | text | | LINE ID（唯一） |
| `line_name` | text | | LINE 顯示名 |
| `email` | text | ✓ | Email |

## 6. `membership_tiers` — 會員等級

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵 |
| `name` | text | ✓ | 等級名稱 |
| `sort_order` | int | ✓ | 排序（等級高低） |
| `qualification_type` | enum | ✓ | 判別條件類型 |
| `qualification_amount` | decimal | ✓ | 達標金額 |
| `discount_rate` | decimal | | 折扣乘數 |
| `notes` | jsonb | | 備註 |
| `created_at` / `updated_at` / `deleted_at` | timestamptz | | 時間戳記 |

## 7. `plan_template_time` 🆕 — 時段定義庫

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵 |
| `weekday` | enum | ✓ | 週一~週日 |
| `start_time` | time | ✓ | 開始時間 |
| `end_time` | time | ✓ | 結束時間 |
| `notes` | jsonb | | 備註 |
| `created_at` / `updated_at` | timestamptz | ✓ | 時間戳記 |

**範例資料**（純時段，與 space 無關）：

| weekday | start | end |
|---|---|---|
| mon | 08:00 | 09:00 |
| mon | 08:30 | 12:30（半日）|
| mon | 13:00 | 17:00（半日）|
| sat | 12:00 | 18:00（歡樂時光時段）|

## 8. `plan_template_items` 🆕 — 項目庫（取代 plan_items）

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵 |
| `type` | enum | ✓ | 5 大類 |
| `name` | text | ✓ | 細分名稱（自由文字）|
| `price` | decimal | ✓ | 價格 |
| `notes` | jsonb | | 備註 |
| `created_at` / `updated_at` / `deleted_at` | timestamptz | | 時間戳記 |

**範例資料**：

| type | name | price |
|---|---|---|
| rental | 平日小時 | 680 |
| rental | 假日小時 | 850 |
| rental | 平日夜間加成 | 1020 |
| rental | 假日半日 | 3300 |
| rental | 歡樂時光 | 6000 |
| rental | 平日小時 | 500（另一場館用）|
| deposit | 押金 | 3000 |
| headcount | 人數費（15 內） | 0 |
| headcount | 人數費（16+） | 500 |
| cleanup | 環境維護（15 內）| 500 |
| cleanup | 環境維護（16+）| 800 |
| service | 半自助服務 | 600 |
| service | 全配置服務 | 1000 |

> 同 type + 同 name 但不同 price 可多筆，對應不同場館。

## 9. `plan_template` 🔄 — 方案組合（重構）

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵 |
| `space_id` | uuid | ✓ | FK 至 resources.id (type=space) |
| `plan_template_time_id` | uuid | | FK 至 plan_template_time（附加項目可空）|
| `plan_template_item_id` | uuid | ✓ | FK 至 plan_template_items |
| `notes` | jsonb | | 備註 |
| `created_at` / `updated_at` / `deleted_at` | timestamptz | | 時間戳記 |

**範例資料**（勤美館的方案組合）：

| space | time | item |
|---|---|---|
| 勤美館 | mon 08-09 | rental 平日小時 $680 |
| 勤美館 | mon 13-17 | rental 平日半日 $2600 |
| 勤美館 | sat 12-18 | rental 歡樂時光 $6000 |
| 勤美館 | null | deposit 押金 $3000 |
| 勤美館 | null | headcount 人數費(15內) $0 |
| 勤美館 | null | headcount 人數費(16+) $500 |

## 10. `orders` 🔄 — 訂單主表（原 bookings 改名）

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵 |
| `customer_id` | uuid | ✓ | FK 至 resources.id (type=customer) |
| `space_id` | uuid | ✓ | FK 至 resources.id (type=space) |
| `source` | enum | | 訂單來源 |
| `total_price` | decimal | | 訂單總價（最終結算）|
| `notes` | jsonb | | 備註 |
| `created_at` / `updated_at` | timestamptz | ✓ | 時間戳記 |
| `created_by` | uuid | | 建單人（代下單時記錄員工）|
| `deleted_at` | timestamptz | | 軟刪除（取消訂單）|

> 確認狀態由 `events.booking_rental.confirmed_at` 表達。

## 11. `plans` 🔄 — 訂單計費明細（重構）

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵 |
| `order_id` | uuid | ✓ | FK 至 orders.id |
| `plan_template_id` | uuid | ✓ | FK 至 plan_template（含 time + item）|
| `event_id` | uuid | | FK 至 events.id（時段類有值；附加項目可空）|
| `unit_price` | decimal | ✓ | 單價快照（避免日後改價影響歷史訂單）|
| `notes` | jsonb | | 備註 |
| `created_at` / `updated_at` | timestamptz | ✓ | 時間戳記 |

> 訂單小計 = SUM(plans.unit_price)（不存欄位即時算）。

## 12. `events` 🔄 — 事件統一表（booking_id → order_id）

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵 |
| `type` | enum | ✓ | 事件類型（9 種） |
| `order_id` | uuid | | FK 至 orders.id（員工排班類事件可空） |
| `starts_at` / `ends_at` | timestamptz | ✓ | 時間範圍 |
| `confirmed_at` | timestamptz | | 確認時間（null=待確認 / 有值=已確認）|
| `notes` | jsonb | | 備註 |
| `created_at` / `updated_at` / `deleted_at` | timestamptz | | 時間戳記 |
| `created_by` | uuid | | 建立者 |

## 13. `event_resource` — 事件 × 資源（N:N）

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵 |
| `event_id` | uuid | ✓ | 事件 |
| `resource_id` | uuid | ✓ | 資源（員工/客戶/空間） |
| `role` | enum | ✓ | performer/subject/location |
| `notes` | jsonb | | 備註 |
| `created_at` | timestamptz | ✓ | 建立時間 |

## 14. `event_log` — 事件變動歷史

| 欄位 | 型別 | 必填 | 說明 |
|---|---|---|---|
| `id` | uuid | ✓ | 主鍵 |
| `event_id` | uuid | ✓ | 事件 |
| `type` | enum | ✓ | insert/update/delete |
| `old_values` / `new_values` | jsonb | | 變更前後 |
| `changed_by` | uuid | | 操作人 |
| `changed_at` | timestamptz | ✓ | 操作時間 |
| `notes` | jsonb | | 備註 |

---

# 🔑 核心設計亮點

## 1. 計費系統的「時間 / 類型+金額 / 組合」三表設計

```
plan_template_time   ← 時段庫（共用）
        +
plan_template_items  ← 項目+金額庫（共用）
        ↓
plan_template        ← 組合：space + time + item
```

**好處**：
- 加新方案（歡樂時光、會員專屬）只要加資料，不動 schema
- 不同場館同樣時段不同價：靠 plan_template_items 多筆表達
- time 跟 item 庫共用，後台維護乾淨

## 2. 訂單流程

```
1. 客戶下訂 → orders 新增
2. 建 events (type=booking_rental, order_id=訂單)
3. event_resource 記錄誰使用
4. 算錢 → plans（連 plan_template + event）
5. 客戶匯款 → events.booking_rental.confirmed_at = NOW()
```

## 3. 訂單狀態（不存 status / is_confirmed）

| 狀態 | 條件 |
|---|---|
| 待確認 | events.booking_rental.confirmed_at IS NULL |
| 已確認 | events.booking_rental.confirmed_at IS NOT NULL |
| 已取消 | orders.deleted_at IS NOT NULL |

## 4. 衝突偵測

```sql
SELECT e.* FROM events e
JOIN event_resource er ON er.event_id = e.id
WHERE er.resource_id = '空間ID' AND er.role = 'location'
  AND e.type = 'booking_rental'
  AND e.starts_at < ? AND e.ends_at > ?;
```

## 5. 會員等級即時算

`customer` 不 FK 到 `membership_tiers`，由系統 SUM(orders.total_price) 對照算。

## 6. 價格快照

`plans.unit_price` 從 `plan_template_items.price` 帶入。未來改價不影響歷史訂單。

## 7. 不存可算的欄位

- 訂單小計：SUM(plans.unit_price) 即時算
- 訂單狀態：從 events.confirmed_at 即時推

## 8. 軟刪除策略

`deleted_at IS NULL` 表示啟用。

---

# ⚠️ 待主管確認

**`orders` ↔ `plans` 中介表？**

目前用 1:N 直接 FK（`plans.order_id`），業務上夠用。

主管原始要求要有中介表（`order_plans`），但 1:N 中介表通常是 over-engineering。除非 plans 有「方案套裝可複用」的需求（→ N:N），否則不建議。

---

> 📝 對應 `VENUE-ERD-v0.3.dbml`（13 張表 + 9 個 ENUM）
> 舊版 `VENUE-ERD-v0.2.dbml` 保留作對照
