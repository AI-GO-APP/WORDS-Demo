# 沃茲新創空間｜Supabase 建表指南

> 完整資料庫 schema，從 0 建立到可上線。依檔案編號順序執行即可。

---

## 🚀 快速開始（10 分鐘）

### Step 1：建立 Supabase 專案
1. 到 [supabase.com](https://supabase.com) 註冊 / 登入
2. 點「New Project」
3. 填專案名稱：`words-live`
4. 設定資料庫密碼（記下來，後面要用）
5. 區域選「Northeast Asia (Tokyo)」（最近）
6. 等 2-3 分鐘建立完成

### Step 2：依序執行 SQL 檔案
進入 Supabase Dashboard → 左側 **SQL Editor** → 點「New Query」

依**這個順序**複製貼上執行：

| # | 檔案 | 用途 | 預估時間 |
|---|---|---|---|
| 1 | `01_schema.sql` | 建立所有資料表 | 10 秒 |
| 2 | `02_indexes.sql` | 建立索引（查詢加速）| 5 秒 |
| 3 | `03_triggers_functions.sql` | 建立觸發器、函式（自動更新時間、累積消費）| 5 秒 |
| 4 | `04_rls_policies.sql` | 啟用 RLS + 安全政策 | 10 秒 |
| 5 | `05_seed_data.sql` | 填入初始資料（5 場館、19 空間、會員等級）| 5 秒 |
| 6 | `06_storage_buckets.sql` | 建立儲存桶（場館圖片）| 5 秒 |

### Step 3：取得 API Keys
進 Dashboard → **Project Settings** → **API**，記下：
- `URL`：`https://xxx.supabase.co`
- `anon (public) key`：給前端用（公開）
- `service_role key`：給後端 admin 用（**絕對不能洩漏**）

### Step 4：驗證
進 Dashboard → **Table Editor** 看是否有 18 張表，且 `venues` 表已有 5 筆資料。

---

## 📋 完整資料表清單（18 張）

### 核心業務（必建）
| 表名 | 用途 | 對應前端頁面 |
|---|---|---|
| `venues` | 場館主表 | admin/venues.html |
| `spaces` | 空間（場館子表） | admin/venues.html |
| `prices` | 空間價格 | admin/pricing.html |
| `customers` | 客戶 | admin/customers.html、account.html |
| `addresses` | 客戶地址 | account.html?tab=address |
| `orders` | 訂單（含候補順位）| admin/orders.html、account.html?tab=orders |

### 會員系統
| 表名 | 用途 | 對應前端頁面 |
|---|---|---|
| `membership_tiers` | 會員等級定義 | account.html?tab=membership |
| `point_transactions` | 紅利點數流水 | account.html?tab=points |
| `stored_value_transactions` | 儲值流水 | 同上 |

### 優惠系統
| 表名 | 用途 | 對應前端頁面 |
|---|---|---|
| `coupons` | 優惠券主表 | （後台規劃中）|
| `coupon_usage` | 券使用紀錄 | account.html?tab=coupons |

### 匯款比對
| 表名 | 用途 | 對應前端頁面 |
|---|---|---|
| `bank_transactions` | 銀行交易紀錄 | admin/payments.html |
| `bank_transaction_orders` | 交易↔訂單對應 | 同上 |
| `import_batches` | 對帳單匯入批次 | 同上 |

### CMS / 通訊
| 表名 | 用途 | 對應前端頁面 |
|---|---|---|
| `venue_pages` | 場館介紹頁內容 | admin/venues.html → 頁面編輯 tab |
| `messages` | LINE/Email 訊息紀錄 | （後台規劃中）|

### 系統
| 表名 | 用途 |
|---|---|
| `audit_logs` | 操作稽核紀錄 |
| `system_settings` | 系統參數（末五碼長度、付款期限等）|

---

## 🔑 重要設計決策

### 1. 候補順位機制（沃茲特性）
- `orders.queue_position` 欄位記錄順位（1, 2, 3...）
- `orders.queue_parent_id` 同時段第 1 順位的 ID（其他候補指向它）
- 第 1 順位逾期 → 觸發器自動把第 2 順位升為第 1 順位 + 發 LINE 通知

### 2. 末五碼產生
- `orders.payment_account_last5` 用 PostgreSQL 函式自動產生（隨機 5 位數字）
- 確保同時段內不重複（避免比對混淆）

### 3. 帳戶累積數字快取
- `customers.total_spent / total_orders / loyalty_points / stored_value_balance` 都是 cache 欄位
- 用 trigger 在訂單付款 / 點數異動時自動更新
- 不每次查 SUM，效能好

### 4. 多租戶預留
- 暫不啟用 multi-tenant，未來如有需要可加 `tenant_id` 欄位
- 現階段全部資料屬於沃茲一家

### 5. 軟刪除
- 訂單、客戶採軟刪除（`deleted_at` 欄位），不真刪除
- 場館 / 空間 / 優惠券用 `status` enum 控制顯示

---

## 🧪 測試帳號

執行完 `05_seed_data.sql` 後，會自動建立：
- 5 個場館（勤美 / 忠明 / 文華 / 漢口 / 站前）
- 19 個空間
- 完整價目表
- 5 個會員等級
- 1 個測試客戶 Joanna（email: `joanna@urfit.com.tw`）

---

## ⚠️ 常見問題

### Q1: 跑 SQL 出現 "permission denied"？
A: 確認您是用「Service role」執行。SQL Editor 預設就是。

### Q2: 想 reset 重來怎麼辦？
A: 跑 `99_reset.sql`（會 DROP 所有表），然後重新執行 01-06。

### Q3: 如何加更多場館？
A: 直接到 Table Editor → `venues` → Insert Row，或從後台 `admin/venues.html` 新增（前提是已串接 Supabase API）。

### Q4: 怎麼接前端？
A: 用 supabase-js SDK，把 anon key 設到前端：
```js
const supabase = createClient(
  'https://xxx.supabase.co',
  'eyJhbGc...'  // anon key
);

// 查所有場館
const { data, error } = await supabase
  .from('venues')
  .select('*, spaces(*, prices(*))')
  .eq('status', 'active');
```

---

## 📞 接手交付清單

跑完所有 SQL 後，記得：
- [ ] 把 URL + anon key 加進前端 `data.js`
- [ ] 把 service_role key 設到後端 .env（不要進 git）
- [ ] 設 Storage 的 CORS（允許前端讀圖片）
- [ ] 在 Supabase Auth 設定登入提供者（Email、LINE Login）
- [ ] 設定 Email 範本（密碼重設、註冊驗證）
- [ ] 設定金流 Webhook URL（綠界 / 藍新會 POST 過來）
