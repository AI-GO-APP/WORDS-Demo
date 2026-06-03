-- ============================================================
-- 沃茲新創空間 - Admin Write Policies (Step 8)
-- ============================================================
-- 目的：開放 anon 對「設定類」表 CRUD（為 demo 用，無 admin auth）
--
-- ⚠️ 注意：這是 demo / 測試環境的設定
-- ⚠️ 正式上線前必須收回，改為「authenticated + role 檢查」
--
-- 開放寫入的表：
-- - venues, spaces, prices         （場館設定）
-- - membership_tiers                （會員等級）
-- - orders                          （訂單狀態變更）
-- - coupons                         （優惠券設定）
--
-- 仍然保持「不開放」的表（敏感資料）：
-- - customers                       （客戶資料只能本人改）
-- - bank_transactions               （金流資料）
-- - audit_logs                      （稽核資料）
-- - addresses, coupon_usage         （個人化資料）
-- ============================================================

-- ============================================================
-- A. 場館 / 空間 / 價格：anon 全 CRUD
-- ============================================================
drop policy if exists "admin all on venues" on public.venues;
create policy "admin all on venues"
  on public.venues for all
  using (true) with check (true);

drop policy if exists "admin all on spaces" on public.spaces;
create policy "admin all on spaces"
  on public.spaces for all
  using (true) with check (true);

drop policy if exists "admin all on prices" on public.prices;
create policy "admin all on prices"
  on public.prices for all
  using (true) with check (true);

-- ============================================================
-- B. 會員等級：anon 全 CRUD
-- ============================================================
drop policy if exists "admin all on membership_tiers" on public.membership_tiers;
create policy "admin all on membership_tiers"
  on public.membership_tiers for all
  using (true) with check (true);

-- ============================================================
-- C. 訂單：anon 可 UPDATE / DELETE（INSERT 已由客戶 policy 控制）
-- ============================================================
drop policy if exists "admin update on orders" on public.orders;
create policy "admin update on orders"
  on public.orders for update
  using (true) with check (true);

drop policy if exists "admin delete on orders" on public.orders;
create policy "admin delete on orders"
  on public.orders for delete
  using (true);

-- 為了 admin 能看到所有訂單（不只自己的），補一個 select policy
drop policy if exists "admin read all orders" on public.orders;
create policy "admin read all orders"
  on public.orders for select
  using (true);

-- ============================================================
-- D. 優惠券：anon 全 CRUD
-- ============================================================
drop policy if exists "admin all on coupons" on public.coupons;
create policy "admin all on coupons"
  on public.coupons for all
  using (true) with check (true);

-- ============================================================
-- ✅ Admin policies 設定完成
-- ============================================================
-- 跑完之後，admin 頁面（無 auth）可以對上述表 CRUD
-- 仍然受限的：customers / bank_transactions / addresses
-- ============================================================
