-- ============================================================
-- 沃茲新創空間 - 補缺漏的空間價格 (Step 11)
-- ============================================================
-- 05_seed_data.sql 漏了 2 個空間沒設價格：
-- - 22222222-0002-0000-0000-000000000002 (忠明館-休息室)
-- - 22222222-0004-0000-0000-000000000003 (漢口會議室)
--
-- 結果是這 2 個前台會跳「請來電洽詢」fallback
-- ============================================================

-- 忠明館-休息室（容納 10 人，價格約 忠明館的 1/3）
insert into public.prices (
  space_id, weekday_hourly, weekend_hourly,
  weekday_half, weekend_half, weekday_full, weekend_full,
  deposit, half_setup, full_setup,
  headcount_tiers, cleanup_tiers
) values (
  '22222222-0002-0000-0000-000000000002', 320, 400,
  1400, 1750, 2600, 3250,
  1000, 300, 500,
  '[{"label":"10人(含)以內","price":0}]'::jsonb,
  '[{"label":"10人(含)以內","price":300}]'::jsonb
) on conflict (space_id) do nothing;

-- 漢口會議室（容納 20 人）
insert into public.prices (
  space_id, weekday_hourly, weekend_hourly,
  weekday_half, weekend_half, weekday_full, weekend_full,
  deposit, half_setup, full_setup,
  headcount_tiers, cleanup_tiers
) values (
  '22222222-0004-0000-0000-000000000003', 480, 600,
  2080, 2600, 3900, 4880,
  2000, 400, 700,
  '[{"label":"20人(含)以內","price":0}]'::jsonb,
  '[{"label":"20人(含)以內","price":400}]'::jsonb
) on conflict (space_id) do nothing;

-- ============================================================
-- ✅ 完成
-- 跑完後，這 2 個空間在前台會有完整預約功能
-- ============================================================
