-- ============================================================
-- 沃茲新創空間 - Schema (Step 1/6)
-- ============================================================
-- 執行：Supabase Dashboard → SQL Editor → 全選貼上 → Run
-- 預估時間：10 秒
-- ============================================================

-- 啟用 UUID 擴充
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ============================================================
-- 1. venues（場館主表）
-- ============================================================
create table public.venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text unique,
  district text,
  address text,
  description text,
  image_url text,
  status text not null default 'active' check (status in ('active','inactive')),
  sort_order int default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.venues is '場館主表（如：勤美館、站前館）';

-- ============================================================
-- 2. spaces（空間，場館的子表）
-- ============================================================
create table public.spaces (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues(id) on delete cascade,
  name text not null,
  capacity int not null default 0,
  description text,
  image_url text,
  status text not null default 'active' check (status in ('active','inactive')),
  sort_order int default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.spaces is '空間（場館內可單獨租借的房間/區域）';

-- ============================================================
-- 3. prices（空間價格，1:1 關聯到 space）
-- ============================================================
create table public.prices (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null unique references public.spaces(id) on delete cascade,

  -- 基本租金（per hour）
  weekday_hourly numeric(10,2) not null default 0,
  weekend_hourly numeric(10,2) not null default 0,

  -- 套裝方案（固定金額）
  weekday_half  numeric(10,2) default 0,
  weekday_full  numeric(10,2) default 0,
  weekend_half  numeric(10,2) default 0,
  weekend_full  numeric(10,2) default 0,

  -- 押金
  deposit numeric(10,2) not null default 0,

  -- 加購服務
  half_setup numeric(10,2) default 0,  -- 半自助配置
  full_setup numeric(10,2) default 0,  -- 全配置服務

  -- 人次費（分級，jsonb：[{label, threshold, price}]）
  headcount_tiers jsonb default '[]'::jsonb,

  -- 環境清潔費（兩種計法擇一）
  cleanup_tiers jsonb default '[]'::jsonb,
  cleanup_flat numeric(10,2),  -- 統一價（適用會議室/洽談室等）

  -- 版本控制（價格變更時建新版本）
  version int not null default 1,
  effective_from date,
  effective_until date,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.prices is '空間定價，每個空間一筆。價格變更時建議建新版本保留歷史';

-- ============================================================
-- 4. membership_tiers（會員等級定義）
-- ============================================================
create table public.membership_tiers (
  id uuid primary key default gen_random_uuid(),
  code text unique not null check (code in ('basic','silver','gold','vip','premium')),
  name text not null,                       -- 一般會員 / 小資會員 / 經濟會員 / 商務會員 / 高級會員
  threshold_amount numeric(10,2) not null,  -- 累積消費門檻
  discount_rate numeric(4,3) not null,      -- 折扣（1.00 = 原價、0.95 = 95 折）
  benefits jsonb default '[]'::jsonb,       -- 福利清單
  sort_order int not null,
  created_at timestamptz not null default now()
);

comment on table public.membership_tiers is '會員等級定義，5 級';

-- ============================================================
-- 5. customers（客戶）
-- ============================================================
create table public.customers (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users(id) on delete set null,
  name text not null,
  email text unique not null,
  phone text,
  line_id text,
  birthday date,
  gender text check (gender in ('male','female','other')),

  -- 等級
  tier_id uuid references public.membership_tiers(id),

  -- 累積數字（trigger 自動維護）
  total_spent numeric(12,2) not null default 0,
  total_orders int not null default 0,
  stored_value_balance numeric(10,2) not null default 0,
  loyalty_points int not null default 0,

  -- 通知偏好
  notify_line boolean default true,
  notify_email boolean default true,
  notify_marketing boolean default false,

  registered_at timestamptz not null default now(),
  last_order_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.customers is '客戶主表，搭配 auth.users 做登入';

-- ============================================================
-- 6. addresses（客戶地址）
-- ============================================================
create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  recipient_name text not null,
  phone text not null,
  zip_code text,
  address text not null,
  label text,  -- 例：家、公司、媽媽家
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.addresses is '客戶收件地址';

-- ============================================================
-- 7. orders（訂單，含候補順位機制）
-- ============================================================
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique not null,        -- WL26002001
  customer_id uuid not null references public.customers(id),
  space_id uuid not null references public.spaces(id),

  -- 預訂內容
  booking_date date not null,
  start_time time not null,
  end_time time not null,
  duration_hours numeric(4,2),
  is_holiday boolean not null default false,
  plan_type text not null check (plan_type in ('hourly','half_day','full_day')),
  plan_label text,                          -- 例：平日小時計費
  headcount text,                           -- 例：30 人以內
  cleanup_choice text,                      -- 例：30 人以內

  -- 金額明細
  base_amount   numeric(10,2) not null default 0,
  headcount_fee numeric(10,2) default 0,
  cleanup_fee   numeric(10,2) default 0,
  service_fee   numeric(10,2) default 0,    -- 半自助 / 全配置
  discount_amount numeric(10,2) default 0,  -- 優惠券折扣
  subtotal      numeric(10,2) not null,     -- 應付小計（不含押金）
  deposit       numeric(10,2) not null default 0,
  total_amount  numeric(10,2) not null,     -- subtotal + deposit
  paid_amount   numeric(10,2) not null default 0,

  -- 狀態
  status text not null default 'pending' check (status in (
    'pending','paid','confirmed','completed','cancelled','refunded'
  )),
  payment_status text not null default 'unpaid' check (payment_status in (
    'unpaid','paid','partial','refunded'
  )),
  payment_method text check (payment_method in ('transfer','credit_card','line_pay','cash','stored_value')),

  -- 沃茲特殊：候補順位
  queue_position int not null default 1,    -- 1 = 第一順位
  queue_parent_id uuid references public.orders(id),  -- 候補時指向同時段第 1 順位
  queue_status text default 'active' check (queue_status in ('active','waiting','promoted','released')),
  -- active = 目前可付款者；waiting = 候補中；promoted = 從候補升上來；released = 已釋出

  -- 匯款比對
  payment_account_last5 text,               -- 給客戶匯款用的專屬末五碼

  -- 優惠券
  coupon_id uuid,                           -- 後面 FK 在 coupons 表

  -- 時間戳
  paid_at timestamptz,
  confirmed_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancel_reason text,
  payment_due_at timestamptz,               -- 付款期限（3 天）

  -- Google Calendar 同步
  gcal_event_id text,

  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.orders is '訂單表，含候補順位機制（queue_position / queue_parent_id）';

-- ============================================================
-- 8. coupons（優惠券）
-- ============================================================
create table public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  discount_type text not null check (discount_type in ('percent','amount')),
  discount_value numeric(10,2) not null,
  min_order_amount numeric(10,2),
  max_discount_amount numeric(10,2),

  valid_from timestamptz,
  valid_until timestamptz,

  total_quantity int,
  used_count int not null default 0,
  per_customer_limit int default 1,

  applicable_venue_ids uuid[],
  applicable_space_ids uuid[],
  applicable_plan_types text[],

  status text not null default 'active' check (status in ('active','paused','expired','depleted')),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 補上 orders.coupon_id 的 FK
alter table public.orders add constraint orders_coupon_id_fkey
  foreign key (coupon_id) references public.coupons(id);

comment on table public.coupons is '優惠券主表（模板）';

-- ============================================================
-- 9. coupon_usage（優惠券使用紀錄）
-- ============================================================
create table public.coupon_usage (
  id uuid primary key default gen_random_uuid(),
  coupon_id uuid not null references public.coupons(id),
  customer_id uuid not null references public.customers(id),
  order_id uuid not null references public.orders(id),
  discount_applied numeric(10,2) not null,
  used_at timestamptz not null default now(),

  unique (coupon_id, customer_id, order_id)  -- 同一張券同一訂單只能用一次
);

comment on table public.coupon_usage is '優惠券使用流水';

-- ============================================================
-- 10. point_transactions（紅利點數流水）
-- ============================================================
create table public.point_transactions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id),
  order_id uuid references public.orders(id),
  type text not null check (type in ('earn','spend','expire','adjustment','birthday')),
  amount int not null,                      -- 正數 = 獲得、負數 = 消費
  balance_after int not null,
  description text,
  created_at timestamptz not null default now()
);

comment on table public.point_transactions is '紅利點數異動流水';

-- ============================================================
-- 11. stored_value_transactions（儲值流水）
-- ============================================================
create table public.stored_value_transactions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id),
  order_id uuid references public.orders(id),
  type text not null check (type in ('deposit','spend','refund','adjustment')),
  amount numeric(10,2) not null,            -- 正數 = 儲值入帳、負數 = 扣抵
  balance_after numeric(10,2) not null,
  description text,
  bank_transaction_id bigint,               -- 對到 bank_transactions
  created_at timestamptz not null default now()
);

comment on table public.stored_value_transactions is '儲值異動流水';

-- ============================================================
-- 12. import_batches（對帳單匯入批次）
-- ============================================================
create table public.import_batches (
  id text primary key,                      -- BATCH_20260602104703
  source_filename text not null,            -- CTWDATXQU_20260602103537.xls
  imported_by uuid references auth.users(id),
  imported_at timestamptz not null default now(),
  record_count int default 0,
  success_count int default 0,
  failed_count int default 0,
  notes text
);

comment on table public.import_batches is '銀行對帳單匯入批次';

-- ============================================================
-- 13. bank_transactions（銀行交易紀錄）
-- ============================================================
create table public.bank_transactions (
  id bigserial primary key,
  transaction_date timestamptz not null,
  summary text not null,                    -- ATM 跨行轉 / 匯款存入
  bank_code text,
  bank_name text,
  account_number text,
  account_last5 text,
  amount numeric(10,2) not null,
  match_status text not null default 'pending' check (match_status in (
    'success','pending','manual','failed'
  )),
  match_reason text,
  batch_id text references public.import_batches(id),
  source_file text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.bank_transactions is '銀行交易紀錄（每筆對帳單一行）';

-- ============================================================
-- 14. bank_transaction_orders（銀行交易 ↔ 訂單對應，多對多）
-- ============================================================
create table public.bank_transaction_orders (
  id uuid primary key default gen_random_uuid(),
  bank_transaction_id bigint not null references public.bank_transactions(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  matched_amount numeric(10,2) not null,
  match_type text not null check (match_type in ('auto','manual','supplement')),
  matched_at timestamptz not null default now(),

  unique (bank_transaction_id, order_id)
);

-- 補 stored_value FK
alter table public.stored_value_transactions add constraint stored_value_bank_tx_fkey
  foreign key (bank_transaction_id) references public.bank_transactions(id);

comment on table public.bank_transaction_orders is '銀行交易與訂單的對應，支援 1:多';

-- ============================================================
-- 15. venue_pages（CMS 場館介紹頁內容）
-- ============================================================
create table public.venue_pages (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues(id) on delete cascade,
  page_type text not null default 'venue-detail',
  content jsonb not null default '{}'::jsonb,
  -- content 範例：{
  --   hero_image, gallery: [], description, facilities: [],
  --   rules: [], faqs: [], seo: {title, description, keywords}
  -- }
  status text not null default 'draft' check (status in ('draft','published','archived')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.venue_pages is 'CMS 場館介紹頁內容（jsonb 儲存）';

-- ============================================================
-- 16. messages（LINE / Email / SMS 訊息紀錄）
-- ============================================================
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.customers(id),
  channel text not null check (channel in ('line','email','sms','in_app')),
  message_type text not null,               -- order_confirmation, payment_reminder, queue_promotion, ...
  subject text,
  content text,
  related_order_id uuid references public.orders(id),
  status text not null default 'pending' check (status in ('pending','sent','failed')),
  sent_at timestamptz,
  error_message text,
  created_at timestamptz not null default now()
);

comment on table public.messages is 'LINE/Email/SMS 推播紀錄';

-- ============================================================
-- 17. audit_logs（操作稽核）
-- ============================================================
create table public.audit_logs (
  id bigserial primary key,
  actor_id uuid,                            -- 操作者（auth.users.id）
  actor_type text default 'user',           -- user / system / admin
  action text not null,                     -- create / update / delete / status_change
  entity_type text not null,                -- order / customer / venue / ...
  entity_id text,
  changes jsonb,                            -- {before, after}
  ip_address text,
  user_agent text,
  created_at timestamptz not null default now()
);

create index idx_audit_entity on public.audit_logs(entity_type, entity_id);
create index idx_audit_actor on public.audit_logs(actor_id);

comment on table public.audit_logs is '系統操作稽核紀錄';

-- ============================================================
-- 18. system_settings（系統參數）
-- ============================================================
create table public.system_settings (
  key text primary key,
  value jsonb not null,
  description text,
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

comment on table public.system_settings is '系統可調整參數（末五碼長度、付款期限等）';

-- ============================================================
-- ✅ Schema 建立完成
-- 下一步：執行 02_indexes.sql 建立索引
-- ============================================================
