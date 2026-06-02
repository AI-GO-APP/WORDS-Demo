-- ============================================================
-- 沃茲新創空間 - Storage Buckets (Step 6/6)
-- ============================================================
-- 建立檔案儲存桶（場館圖片、頭像等）
-- ============================================================

-- 建立 buckets
-- ⚠️ 注意：以下 SQL 可能需要在 Supabase Dashboard → Storage 手動建立
-- 因為 Storage 的 schema 比較特別，這個 SQL 可能在某些版本上跑不過
-- 替代方法：去 Dashboard → Storage → Create new bucket

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('venue-images',    'venue-images',    true,  5242880,  array['image/jpeg','image/png','image/webp']),    -- 場館圖片（5MB）
  ('space-images',    'space-images',    true,  5242880,  array['image/jpeg','image/png','image/webp']),    -- 空間圖片（5MB）
  ('customer-avatar', 'customer-avatar', true,  2097152,  array['image/jpeg','image/png','image/webp']),    -- 頭像（2MB）
  ('bank-statements', 'bank-statements', false, 10485760, array['application/vnd.ms-excel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','text/csv']),  -- 對帳單（10MB，私有）
  ('id-documents',    'id-documents',    false, 5242880,  array['image/jpeg','image/png','application/pdf']) -- 身分證掃描（5MB，私有）
on conflict do nothing;

-- ============================================================
-- Storage RLS Policies
-- ============================================================

-- 公開讀取：venue-images / space-images / customer-avatar
create policy "public read venue images"
  on storage.objects for select
  using (bucket_id = 'venue-images');

create policy "public read space images"
  on storage.objects for select
  using (bucket_id = 'space-images');

create policy "public read customer avatar"
  on storage.objects for select
  using (bucket_id = 'customer-avatar');

-- 只有登入用戶才能上傳頭像
create policy "authenticated upload avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'customer-avatar'
    and auth.uid() is not null
  );

-- 只有自己能改自己的頭像
create policy "user update own avatar"
  on storage.objects for update
  using (
    bucket_id = 'customer-avatar'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 只有 service_role 能存對帳單 / 身分證（在 SQL 層級無 policy 即拒絕）

-- ============================================================
-- ✅ Storage 建立完成
-- 注意：如果以上 SQL 跑不過，去 Dashboard → Storage 手動建立 buckets：
--   1. venue-images (public, 5MB, jpeg/png/webp)
--   2. space-images (public, 5MB, jpeg/png/webp)
--   3. customer-avatar (public, 2MB, jpeg/png/webp)
--   4. bank-statements (private, 10MB, xls/xlsx/csv)
--   5. id-documents (private, 5MB, jpg/png/pdf)
-- ============================================================

-- ============================================================
-- 🎉 全部完成！
-- ============================================================
-- 接下來：
-- 1. Project Settings → API → 取得 URL 和 anon key
-- 2. 前端 data.js 加上 Supabase client 初始化
-- 3. 開始替換 mock data 為真實 API 呼叫
-- ============================================================
