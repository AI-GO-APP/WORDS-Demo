-- ============================================================
-- 沃茲新創空間 - 加入「待確認」狀態 + 修 min(uuid) bug (Step 12)
-- ============================================================
-- 業務流程變更：
--   客戶下單 → status='pending_review'（待確認，等客服審核）
--   客服按「通過」→ status='pending'（待付款）
--   客戶付款 → status='paid'
--   客服確認入帳 → status='confirmed'
--   使用日結束 → status='completed'
--
-- 同時修補：calc_queue_position 用了 min(uuid)，PostgreSQL 不支援
-- ============================================================

-- ============================================================
-- A. 擴充 orders.status check 加入 pending_review
-- ============================================================
alter table public.orders drop constraint if exists orders_status_check;
alter table public.orders add constraint orders_status_check
  check (status in (
    'pending_review',  -- 新增：待客服確認
    'pending',         -- 待付款
    'paid',            -- 已付款（待客服確認入帳）
    'confirmed',       -- 已確認
    'completed',       -- 已完成
    'cancelled',       -- 已取消
    'refunded'         -- 已退款
  ));

-- 預設改成 pending_review（新訂單一定先進待確認）
alter table public.orders alter column status set default 'pending_review';

-- ============================================================
-- B. 修補 calc_queue_position：min(uuid) → order by + limit 1
--    順便把 pending_review 加入「佔位」狀態（避免別人搶同時段）
-- ============================================================
create or replace function public.calc_queue_position()
returns trigger
language plpgsql
as $$
declare
  v_existing_count int;
  v_first_order_id uuid;
begin
  -- 算同空間、同日、時段重疊的「活躍」訂單數
  select count(*)
    into v_existing_count
  from public.orders
  where space_id = new.space_id
    and booking_date = new.booking_date
    and status in ('pending_review','pending','paid','confirmed')
    and id <> new.id
    and (
      (new.start_time, new.end_time) overlaps (start_time, end_time)
    );

  -- 找最早送出申請的訂單 id（取代 min(id)）
  select id into v_first_order_id
  from public.orders
  where space_id = new.space_id
    and booking_date = new.booking_date
    and status in ('pending_review','pending','paid','confirmed')
    and id <> new.id
    and (
      (new.start_time, new.end_time) overlaps (start_time, end_time)
    )
  order by created_at asc
  limit 1;

  if v_existing_count = 0 then
    new.queue_position := 1;
    new.queue_status := 'active';
    new.queue_parent_id := null;
  else
    new.queue_position := v_existing_count + 1;
    new.queue_status := 'waiting';
    new.queue_parent_id := v_first_order_id;
  end if;

  return new;
end;
$$;

-- ============================================================
-- C. 修補 handle_order_confirmed：擴充取消同時段邏輯
--    當訂單 confirmed 時，把同時段「pending_review / pending」都取消
-- ============================================================
create or replace function public.handle_order_confirmed()
returns trigger
language plpgsql
as $$
begin
  if old.status <> 'confirmed' and new.status = 'confirmed' then
    update public.orders
    set status = 'cancelled',
        cancel_reason = '時段已被優先訂單確認，您的候補預約自動取消',
        cancelled_at = now()
    where space_id = new.space_id
      and booking_date = new.booking_date
      and status in ('pending_review','pending','paid')
      and id <> new.id
      and (
        (new.start_time, new.end_time) overlaps (start_time, end_time)
      );

    update public.customers
    set total_spent = total_spent + new.subtotal,
        total_orders = total_orders + 1,
        last_order_at = now()
    where id = new.customer_id;
  end if;

  return new;
end;
$$;

-- ============================================================
-- D. expire_unpaid_orders：保留原邏輯，只取消 status='pending'（待付款）
--    pending_review 不會被自動逾期取消（要客服處理）
-- ============================================================
-- 原 function 已是這樣，不用改

-- ============================================================
-- ✅ 完成
-- 跑完後：
-- 1. 新訂單會自動是 pending_review
-- 2. calc_queue_position 不再炸
-- 3. 客服在 admin 點「通過」會把狀態改 pending（自己手動 update）
-- ============================================================
