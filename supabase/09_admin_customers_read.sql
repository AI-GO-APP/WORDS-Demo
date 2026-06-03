-- ============================================================
-- 沃茲新創空間 - Admin: 開放 customers 讀取（demo 用）
-- ============================================================
-- 補 10_admin_policies.sql 沒覆蓋到的：customers 表 admin 讀取
--
-- ⚠️ 注意：customers 含個資（email/phone/line_id），
-- ⚠️ production 上必須收回，改用 service_role 或 authenticated + admin role
-- ============================================================

drop policy if exists "admin read all customers" on public.customers;
create policy "admin read all customers"
  on public.customers for select
  using (true);

-- 也順手開 addresses 讀（admin 可能要看客戶地址）
drop policy if exists "admin read all addresses" on public.addresses;
create policy "admin read all addresses"
  on public.addresses for select
  using (true);

-- point_transactions / stored_value_transactions 也讓 admin 看
drop policy if exists "admin read all point_transactions" on public.point_transactions;
create policy "admin read all point_transactions"
  on public.point_transactions for select
  using (true);

drop policy if exists "admin read all stored_value_transactions" on public.stored_value_transactions;
create policy "admin read all stored_value_transactions"
  on public.stored_value_transactions for select
  using (true);

-- coupon_usage 也讓 admin 看
drop policy if exists "admin read all coupon_usage" on public.coupon_usage;
create policy "admin read all coupon_usage"
  on public.coupon_usage for select
  using (true);

-- ============================================================
-- ✅ 完成
-- ============================================================
