-- ============================================================
-- 沃茲新創空間 - Auth Trigger (Step 7/N)
-- ============================================================
-- 當 auth.users 有新用戶時，自動建立對應的 customers row
-- 並補上 INSERT policy 給 customers 表（讓註冊流程可用）
-- ============================================================

-- ============================================================
-- A. INSERT policy：允許自己幫自己建 customer row
-- ============================================================
drop policy if exists "customer self insert" on public.customers;
create policy "customer self insert"
  on public.customers for insert
  with check (auth_user_id = auth.uid());

-- ============================================================
-- B. Trigger Function：新 auth user → 自動建 customer
-- 用 SECURITY DEFINER 繞過 RLS（trigger 用 admin 身份執行）
-- ============================================================
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
begin
  -- 從 user_metadata 抓 name，沒有就用 email 前綴
  v_name := coalesce(
    new.raw_user_meta_data->>'name',
    split_part(new.email, '@', 1)
  );

  -- 建立 customer row（如果已存在則跳過）
  insert into public.customers (auth_user_id, email, name, status)
  values (new.id, new.email, v_name, 'active')
  on conflict (auth_user_id) do nothing;

  return new;
end;
$$;

-- ============================================================
-- C. 綁定到 auth.users 的 insert 事件
-- ============================================================
drop trigger if exists trg_auth_user_created on auth.users;
create trigger trg_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- ============================================================
-- ✅ 完成後，每當有人 signUp，會自動：
-- 1. 在 auth.users 建一筆（Supabase 內建）
-- 2. trigger 自動在 public.customers 建一筆
-- ============================================================

-- ============================================================
-- 補充：如果 customers.auth_user_id 還沒設 unique constraint，補上
-- （避免重複關聯）
-- ============================================================
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'customers_auth_user_id_key'
  ) then
    alter table public.customers add constraint customers_auth_user_id_key unique (auth_user_id);
  end if;
end$$;
