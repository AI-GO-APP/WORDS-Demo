-- ============================================================
-- 沃茲新創空間 - Triggers & Functions (Step 3/6)
-- ============================================================
-- 自動更新時間戳、累積數字維護、訂單編號 / 末五碼產生
-- ============================================================

-- ============================================================
-- A. 自動更新 updated_at（套用所有表）
-- ============================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare
  t text;
begin
  for t in
    select table_name from information_schema.columns
    where table_schema = 'public' and column_name = 'updated_at'
  loop
    execute format('
      drop trigger if exists trg_%I_updated_at on public.%I;
      create trigger trg_%I_updated_at before update on public.%I
        for each row execute function public.set_updated_at();
    ', t, t, t, t);
  end loop;
end$$;

-- ============================================================
-- B. 訂單編號產生（WL26XXXXXXX 格式）
-- ============================================================
create or replace function public.generate_order_number()
returns text
language plpgsql
as $$
declare
  yr text := to_char(now(), 'YY');
  seq int;
  new_num text;
begin
  -- 取得當年序號（從 1 開始）
  select coalesce(max(substring(order_number from 5)::int), 0) + 1
    into seq
  from public.orders
  where order_number like 'WL' || yr || '%';

  new_num := 'WL' || yr || lpad(seq::text, 7, '0');
  return new_num;
end;
$$;

-- 訂單建立時自動補 order_number
create or replace function public.fill_order_number()
returns trigger
language plpgsql
as $$
begin
  if new.order_number is null or new.order_number = '' then
    new.order_number := public.generate_order_number();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_orders_order_number on public.orders;
create trigger trg_orders_order_number
  before insert on public.orders
  for each row execute function public.fill_order_number();

-- ============================================================
-- C. 付款末五碼產生（隨機 5 位數字，同空間+日期+時段不重複）
-- ============================================================
create or replace function public.generate_payment_last5(
  p_space_id uuid, p_date date, p_start time, p_end time
)
returns text
language plpgsql
as $$
declare
  candidate text;
  attempts int := 0;
  conflict_count int;
begin
  loop
    attempts := attempts + 1;
    candidate := lpad((floor(random() * 100000))::text, 5, '0');

    -- 檢查同空間 + 同時段 + 同日的其他訂單是否已用此末五碼
    select count(*) into conflict_count
    from public.orders
    where space_id = p_space_id
      and booking_date = p_date
      and start_time = p_start
      and end_time = p_end
      and payment_account_last5 = candidate
      and status in ('pending','paid','confirmed');

    exit when conflict_count = 0 or attempts >= 20;
  end loop;

  return candidate;
end;
$$;

create or replace function public.fill_payment_last5()
returns trigger
language plpgsql
as $$
begin
  if new.payment_account_last5 is null then
    new.payment_account_last5 := public.generate_payment_last5(
      new.space_id, new.booking_date, new.start_time, new.end_time
    );
  end if;
  -- 預設付款期限 = 建立後 3 天
  if new.payment_due_at is null then
    new.payment_due_at := now() + interval '3 days';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_orders_payment_last5 on public.orders;
create trigger trg_orders_payment_last5
  before insert on public.orders
  for each row execute function public.fill_payment_last5();

-- ============================================================
-- D. 候補順位自動計算（建立訂單時依時段衝突排順位）
-- ============================================================
create or replace function public.calc_queue_position()
returns trigger
language plpgsql
as $$
declare
  v_existing_count int;
  v_first_order_id uuid;
begin
  -- 找同空間、同日、時段重疊的「待付款」訂單
  select count(*), min(id)
    into v_existing_count, v_first_order_id
  from public.orders
  where space_id = new.space_id
    and booking_date = new.booking_date
    and status in ('pending','paid','confirmed')
    and id <> new.id
    and (
      (new.start_time, new.end_time) overlaps (start_time, end_time)
    );

  if v_existing_count = 0 then
    -- 沒有衝突，第 1 順位
    new.queue_position := 1;
    new.queue_status := 'active';
    new.queue_parent_id := null;
  else
    -- 有衝突，加入候補
    new.queue_position := v_existing_count + 1;
    new.queue_status := 'waiting';
    new.queue_parent_id := v_first_order_id;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_orders_queue_position on public.orders;
create trigger trg_orders_queue_position
  before insert on public.orders
  for each row execute function public.calc_queue_position();

-- ============================================================
-- E. 訂單付款成功時 → 取消同時段其他候補
-- ============================================================
create or replace function public.handle_order_confirmed()
returns trigger
language plpgsql
as $$
begin
  -- 只在狀態從非 confirmed 改為 confirmed 時觸發
  if old.status <> 'confirmed' and new.status = 'confirmed' then
    -- 把同空間、同日、時段重疊的其他「pending」訂單全部取消
    update public.orders
    set status = 'cancelled',
        cancel_reason = '時段已被優先訂單確認，您的候補預約自動取消',
        cancelled_at = now()
    where space_id = new.space_id
      and booking_date = new.booking_date
      and status = 'pending'
      and id <> new.id
      and (
        (new.start_time, new.end_time) overlaps (start_time, end_time)
      );

    -- 累積客戶數字
    update public.customers
    set total_spent = total_spent + new.subtotal,
        total_orders = total_orders + 1,
        last_order_at = now()
    where id = new.customer_id;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_orders_confirmed on public.orders;
create trigger trg_orders_confirmed
  after update on public.orders
  for each row execute function public.handle_order_confirmed();

-- ============================================================
-- F. 訂單付款逾期 → 升等候補 #2（每天跑一次）
-- 用法：建立 pg_cron job 或在 Edge Function 排程
-- ============================================================
create or replace function public.expire_unpaid_orders()
returns void
language plpgsql
as $$
declare
  expired record;
  next_order record;
begin
  for expired in
    select * from public.orders
    where status = 'pending'
      and payment_due_at < now()
  loop
    -- 取消逾期訂單
    update public.orders
    set status = 'cancelled',
        cancel_reason = '逾期未付款，自動取消',
        cancelled_at = now()
    where id = expired.id;

    -- 找同時段下一個候補
    select * into next_order
    from public.orders
    where space_id = expired.space_id
      and booking_date = expired.booking_date
      and status = 'pending'
      and queue_status = 'waiting'
      and id <> expired.id
      and (
        (expired.start_time, expired.end_time) overlaps (start_time, end_time)
      )
    order by created_at asc
    limit 1;

    -- 升等候補
    if next_order.id is not null then
      update public.orders
      set queue_position = 1,
          queue_status = 'promoted',
          queue_parent_id = null,
          payment_due_at = now() + interval '3 days'
      where id = next_order.id;

      -- 標記後續候補位減 1
      update public.orders
      set queue_position = queue_position - 1
      where queue_parent_id = expired.id;
    end if;
  end loop;
end;
$$;

comment on function public.expire_unpaid_orders is '每天執行一次：取消逾期訂單 + 升等候補';

-- ============================================================
-- G. 紅利點數變動時 → 自動更新 customers.loyalty_points
-- ============================================================
create or replace function public.update_customer_points()
returns trigger
language plpgsql
as $$
begin
  update public.customers
  set loyalty_points = loyalty_points + new.amount
  where id = new.customer_id;
  return new;
end;
$$;

drop trigger if exists trg_point_tx on public.point_transactions;
create trigger trg_point_tx
  after insert on public.point_transactions
  for each row execute function public.update_customer_points();

-- ============================================================
-- H. 儲值變動時 → 自動更新 customers.stored_value_balance
-- ============================================================
create or replace function public.update_customer_stored_value()
returns trigger
language plpgsql
as $$
begin
  update public.customers
  set stored_value_balance = stored_value_balance + new.amount
  where id = new.customer_id;
  return new;
end;
$$;

drop trigger if exists trg_sv_tx on public.stored_value_transactions;
create trigger trg_sv_tx
  after insert on public.stored_value_transactions
  for each row execute function public.update_customer_stored_value();

-- ============================================================
-- I. 累積消費觸發升等檢查（客戶 total_spent 變動時）
-- ============================================================
create or replace function public.check_tier_upgrade()
returns trigger
language plpgsql
as $$
declare
  new_tier_id uuid;
begin
  -- 依累積消費找對應等級
  select id into new_tier_id
  from public.membership_tiers
  where threshold_amount <= new.total_spent
  order by threshold_amount desc
  limit 1;

  if new_tier_id is not null and new.tier_id is distinct from new_tier_id then
    update public.customers
    set tier_id = new_tier_id
    where id = new.id;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_customer_tier_check on public.customers;
create trigger trg_customer_tier_check
  after update of total_spent on public.customers
  for each row execute function public.check_tier_upgrade();

-- ============================================================
-- ✅ Triggers & Functions 建立完成
-- 下一步：執行 04_rls_policies.sql
-- ============================================================
