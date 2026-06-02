-- ============================================================
-- 沃茲新創空間 - RLS Policies (Step 4/6)
-- ============================================================
-- Row Level Security：控制誰能讀寫哪些資料
-- 預設邏輯：
--   - 公開資料（venues/spaces/prices/coupons）：所有人可讀
--   - 客戶私人資料：只能本人讀寫
--   - 後台資料：只有 admin role 能存取（service_role）
-- ============================================================

-- ============================================================
-- 啟用所有表的 RLS
-- ============================================================
alter table public.venues enable row level security;
alter table public.spaces enable row level security;
alter table public.prices enable row level security;
alter table public.membership_tiers enable row level security;
alter table public.customers enable row level security;
alter table public.addresses enable row level security;
alter table public.orders enable row level security;
alter table public.coupons enable row level security;
alter table public.coupon_usage enable row level security;
alter table public.point_transactions enable row level security;
alter table public.stored_value_transactions enable row level security;
alter table public.import_batches enable row level security;
alter table public.bank_transactions enable row level security;
alter table public.bank_transaction_orders enable row level security;
alter table public.venue_pages enable row level security;
alter table public.messages enable row level security;
alter table public.audit_logs enable row level security;
alter table public.system_settings enable row level security;

-- ============================================================
-- 公開資料：所有人（含未登入）可讀
-- ============================================================
create policy "public read venues"
  on public.venues for select
  using (status = 'active' and deleted_at is null);

create policy "public read spaces"
  on public.spaces for select
  using (status = 'active' and deleted_at is null);

create policy "public read prices"
  on public.prices for select
  using (true);

create policy "public read membership tiers"
  on public.membership_tiers for select
  using (true);

create policy "public read venue_pages"
  on public.venue_pages for select
  using (status = 'published');

create policy "public read active coupons"
  on public.coupons for select
  using (status = 'active' and (valid_until is null or valid_until > now()));

-- ============================================================
-- 客戶私人資料：只能本人讀寫
-- 用 auth.uid() 對 customers.auth_user_id
-- ============================================================

-- customers
create policy "customer read own profile"
  on public.customers for select
  using (auth_user_id = auth.uid());

create policy "customer update own profile"
  on public.customers for update
  using (auth_user_id = auth.uid());

-- addresses
create policy "customer manage own addresses"
  on public.addresses for all
  using (
    customer_id in (select id from public.customers where auth_user_id = auth.uid())
  );

-- orders
create policy "customer read own orders"
  on public.orders for select
  using (
    customer_id in (select id from public.customers where auth_user_id = auth.uid())
  );

create policy "customer create own orders"
  on public.orders for insert
  with check (
    customer_id in (select id from public.customers where auth_user_id = auth.uid())
  );

create policy "customer update own pending orders"
  on public.orders for update
  using (
    customer_id in (select id from public.customers where auth_user_id = auth.uid())
    and status = 'pending'
  );

-- coupon_usage
create policy "customer read own coupon usage"
  on public.coupon_usage for select
  using (
    customer_id in (select id from public.customers where auth_user_id = auth.uid())
  );

-- point_transactions
create policy "customer read own points"
  on public.point_transactions for select
  using (
    customer_id in (select id from public.customers where auth_user_id = auth.uid())
  );

-- stored_value_transactions
create policy "customer read own stored value"
  on public.stored_value_transactions for select
  using (
    customer_id in (select id from public.customers where auth_user_id = auth.uid())
  );

-- messages
create policy "customer read own messages"
  on public.messages for select
  using (
    customer_id in (select id from public.customers where auth_user_id = auth.uid())
  );

-- ============================================================
-- 後台資料：只有 service_role（admin API）能存取
-- 注意：service_role 預設繞過 RLS，所以這些表「不另外加 policy 即可」
-- 對 anon / authenticated 自動拒絕
-- ============================================================
-- bank_transactions, bank_transaction_orders, import_batches,
-- audit_logs, system_settings 都不另外加 select policy → anon 看不到

-- ============================================================
-- ✅ RLS Policies 建立完成
-- 注意：admin 後台必須用 service_role key 連，才能繞過 RLS
-- 下一步：執行 05_seed_data.sql
-- ============================================================
