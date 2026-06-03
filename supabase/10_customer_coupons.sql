-- ============================================================
-- 沃茲新創空間 - Customer Coupons (Step 10)
-- ============================================================
-- 新表：客戶已兌換但尚未使用的優惠券
--
-- 業務流程：
--   1. Admin 在後台建立 coupons（優惠券樣板）
--   2. 客戶在前台輸入 code → 兌換 → 寫入 customer_coupons
--   3. 客戶結帳時可選用已兌換的券 → 折抵金額 → 寫入 coupon_usage 並標記 customer_coupons.used_at
-- ============================================================

-- ============================================================
-- A. 建立 customer_coupons 表
-- ============================================================
create table if not exists public.customer_coupons (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  coupon_id uuid not null references public.coupons(id) on delete cascade,
  claimed_at timestamptz not null default now(),
  used_at timestamptz,
  used_order_id uuid references public.orders(id) on delete set null,
  unique (customer_id, coupon_id)  -- 每張券每人只能兌換一次
);

comment on table public.customer_coupons is '客戶已兌換的優惠券（介於 coupons 樣板 和 coupon_usage 使用紀錄 之間）';

create index if not exists idx_customer_coupons_customer on public.customer_coupons(customer_id);
create index if not exists idx_customer_coupons_unused on public.customer_coupons(customer_id) where used_at is null;

-- ============================================================
-- B. RLS policies
-- ============================================================
alter table public.customer_coupons enable row level security;

drop policy if exists "customer read own coupons" on public.customer_coupons;
create policy "customer read own coupons"
  on public.customer_coupons for select
  using (
    customer_id in (select id from public.customers where auth_user_id = auth.uid())
  );

drop policy if exists "customer claim coupon" on public.customer_coupons;
create policy "customer claim coupon"
  on public.customer_coupons for insert
  with check (
    customer_id in (select id from public.customers where auth_user_id = auth.uid())
  );

-- Admin 可讀全部（demo 用）
drop policy if exists "admin read all customer_coupons" on public.customer_coupons;
create policy "admin read all customer_coupons"
  on public.customer_coupons for select
  using (true);

-- ============================================================
-- C. 兌換函式：客戶輸入 code → 寫入 customer_coupons
-- ============================================================
create or replace function public.claim_coupon_by_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_customer_id uuid;
  v_coupon record;
  v_now timestamptz := now();
begin
  -- 1. 取得當前用戶的 customer_id
  select id into v_customer_id
  from public.customers
  where auth_user_id = auth.uid();

  if v_customer_id is null then
    return jsonb_build_object('success', false, 'error', '請先登入');
  end if;

  -- 2. 查找優惠券
  select * into v_coupon
  from public.coupons
  where upper(code) = upper(p_code);

  if v_coupon.id is null then
    return jsonb_build_object('success', false, 'error', '找不到此優惠碼');
  end if;

  -- 3. 檢查狀態
  if v_coupon.status <> 'active' then
    return jsonb_build_object('success', false, 'error', '此優惠券已停用或失效');
  end if;

  -- 4. 檢查有效期
  if v_coupon.valid_from is not null and v_now < v_coupon.valid_from then
    return jsonb_build_object('success', false, 'error', '此優惠券尚未開始');
  end if;
  if v_coupon.valid_until is not null and v_now > v_coupon.valid_until then
    return jsonb_build_object('success', false, 'error', '此優惠券已過期');
  end if;

  -- 5. 檢查數量
  if v_coupon.total_quantity is not null and v_coupon.used_count >= v_coupon.total_quantity then
    return jsonb_build_object('success', false, 'error', '此優惠券已被兌換完畢');
  end if;

  -- 6. 檢查是否已兌換過
  if exists (
    select 1 from public.customer_coupons
    where customer_id = v_customer_id and coupon_id = v_coupon.id
  ) then
    return jsonb_build_object('success', false, 'error', '您已兌換過此優惠券');
  end if;

  -- 7. 寫入 customer_coupons
  insert into public.customer_coupons (customer_id, coupon_id)
  values (v_customer_id, v_coupon.id);

  -- 8. 累計 coupon.used_count（即「已兌換」數）
  update public.coupons
  set used_count = used_count + 1
  where id = v_coupon.id;

  return jsonb_build_object(
    'success', true,
    'coupon', jsonb_build_object(
      'id', v_coupon.id,
      'code', v_coupon.code,
      'name', v_coupon.name,
      'discount_type', v_coupon.discount_type,
      'discount_value', v_coupon.discount_value,
      'min_order_amount', v_coupon.min_order_amount,
      'valid_until', v_coupon.valid_until
    )
  );
end;
$$;

comment on function public.claim_coupon_by_code is '客戶用 code 兌換優惠券到自己帳號';

-- ============================================================
-- D. 給 authenticated 角色可以呼叫此函式
-- ============================================================
grant execute on function public.claim_coupon_by_code(text) to anon, authenticated;

-- ============================================================
-- ✅ 完成。前台用法：
--   const { data, error } = await supabaseClient.rpc('claim_coupon_by_code', { p_code: 'WELCOME200' });
--   if (data.success) { ... } else { alert(data.error); }
-- ============================================================
