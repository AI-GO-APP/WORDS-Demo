-- ============================================================
-- 沃茲新創空間 - Seed Data (Step 5/6)
-- ============================================================
-- 初始資料：5 個場館、19 個空間、價格、會員等級、測試客戶
-- ============================================================

-- ============================================================
-- A. 會員等級
-- ============================================================
insert into public.membership_tiers (code, name, threshold_amount, discount_rate, sort_order, benefits) values
  ('basic',   '一般會員', 0,      1.00, 1, '["消費 1% 回饋", "生日小禮"]'::jsonb),
  ('silver',  '小資會員', 6000,   0.95, 2, '["享 95 折", "消費 1% 回饋", "生日 NT$100 折抵券"]'::jsonb),
  ('gold',    '經濟會員', 30000,  0.92, 3, '["享 92 折", "消費 1% 回饋", "生日 NT$300 折抵券", "優先預訂熱門時段"]'::jsonb),
  ('vip',     '商務會員', 100000, 0.90, 4, '["享 90 折", "消費 1.5% 回饋", "月月專屬好禮", "LINE 專屬客服"]'::jsonb),
  ('premium', '高級會員', 300000, 0.85, 5, '["享 85 折", "消費 2% 回饋", "免費場地升等", "VIP 場館優先"]'::jsonb);

-- ============================================================
-- B. 場館（5 個）
-- ============================================================
insert into public.venues (id, name, code, district, address, status) values
  ('11111111-1111-1111-1111-000000000001', '勤美館', 'QM', '北區', '404 台中市北區英才路 396 號 11 樓-2', 'active'),
  ('11111111-1111-1111-1111-000000000002', '忠明館', 'ZM', '南區', '台中市南區忠明南路 478 號 B1',           'active'),
  ('11111111-1111-1111-1111-000000000003', '文華館', 'WH', '西屯區', '台中市西屯區文心路三段 237 號 6F',     'active'),
  ('11111111-1111-1111-1111-000000000004', '漢口館', 'HK', '西屯區', '台中市西屯區四川路 87 號 B1',          'active'),
  ('11111111-1111-1111-1111-000000000005', '站前館', 'ZQ', '東區',   '台中市東區自由二街 91 號',             'active');

-- ============================================================
-- C. 空間（19 個）
-- ============================================================
-- 勤美館
insert into public.spaces (id, venue_id, name, capacity) values
  ('22222222-0001-0000-0000-000000000001', '11111111-1111-1111-1111-000000000001', '勤美館', 30);

-- 忠明館
insert into public.spaces (id, venue_id, name, capacity) values
  ('22222222-0002-0000-0000-000000000001', '11111111-1111-1111-1111-000000000002', '忠明館', 60),
  ('22222222-0002-0000-0000-000000000002', '11111111-1111-1111-1111-000000000002', '忠明館-休息室', 10);

-- 文華館
insert into public.spaces (id, venue_id, name, capacity) values
  ('22222222-0003-0000-0000-000000000001', '11111111-1111-1111-1111-000000000003', '文華館', 40);

-- 漢口館
insert into public.spaces (id, venue_id, name, capacity) values
  ('22222222-0004-0000-0000-000000000001', '11111111-1111-1111-1111-000000000004', '漢口一館', 80),
  ('22222222-0004-0000-0000-000000000002', '11111111-1111-1111-1111-000000000004', '漢口二館', 80),
  ('22222222-0004-0000-0000-000000000003', '11111111-1111-1111-1111-000000000004', '漢口會議室', 20);

-- 站前館
insert into public.spaces (id, venue_id, name, capacity) values
  ('22222222-0005-0000-0000-000000000001', '11111111-1111-1111-1111-000000000005', '藝文展間', 60),
  ('22222222-0005-0000-0000-000000000002', '11111111-1111-1111-1111-000000000005', '階梯教室', 60),
  ('22222222-0005-0000-0000-000000000003', '11111111-1111-1111-1111-000000000005', '多功能 1 館', 60),
  ('22222222-0005-0000-0000-000000000004', '11111111-1111-1111-1111-000000000005', '多功能 2 館', 60),
  ('22222222-0005-0000-0000-000000000005', '11111111-1111-1111-1111-000000000005', '階梯+展間', 140),
  ('22222222-0005-0000-0000-000000000006', '11111111-1111-1111-1111-000000000005', '多功能全館', 140),
  ('22222222-0005-0000-0000-000000000007', '11111111-1111-1111-1111-000000000005', '藝文半展間', 40),
  ('22222222-0005-0000-0000-000000000008', '11111111-1111-1111-1111-000000000005', '會議室', 15),
  ('22222222-0005-0000-0000-000000000009', '11111111-1111-1111-1111-000000000005', '洽談室', 8),
  ('22222222-0005-0000-0000-000000000010', '11111111-1111-1111-1111-000000000005', '休息室', 8),
  ('22222222-0005-0000-0000-000000000011', '11111111-1111-1111-1111-000000000005', '站前館外廣場', 50),
  ('22222222-0005-0000-0000-000000000012', '11111111-1111-1111-1111-000000000005', '站前館外長廊', 30);

-- ============================================================
-- D. 價格（每個空間一筆）
-- ============================================================
-- 勤美館
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit, half_setup, full_setup, headcount_tiers, cleanup_tiers) values
  ('22222222-0001-0000-0000-000000000001', 680, 850, 2600, 3300, 5200, 6480, 3000, 600, 1000,
   '[{"label":"15人(含)以內","price":0},{"label":"16人以上","price":500}]'::jsonb,
   '[{"label":"15人(含)以內","price":500},{"label":"16人以上","price":800}]'::jsonb);

-- 忠明館
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit, half_setup, full_setup, headcount_tiers, cleanup_tiers) values
  ('22222222-0002-0000-0000-000000000001', 960, 1200, 4250, 5200, 7950, 9800, 3000, 800, 1500,
   '[{"label":"30人(含)以內","price":0},{"label":"31-60人","price":600},{"label":"61人以上","price":1000}]'::jsonb,
   '[{"label":"30人(含)以內","price":800},{"label":"31-60人","price":1200},{"label":"61人以上","price":1500}]'::jsonb);

-- 文華館
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit, half_setup, full_setup, headcount_tiers, cleanup_tiers) values
  ('22222222-0003-0000-0000-000000000001', 760, 950, 3300, 4000, 6200, 7680, 3000, 800, 1500,
   '[{"label":"20人(含)以內","price":0},{"label":"21-40人","price":600},{"label":"41人以上","price":1000}]'::jsonb,
   '[{"label":"20人(含)以內","price":500},{"label":"21-40人","price":800},{"label":"41人以上","price":1200}]'::jsonb);

-- 漢口一館 / 二館（同價）
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit, half_setup, full_setup, headcount_tiers, cleanup_tiers)
select id, 1104, 1380, 5200, 6250, 9450, 11560, 5000, 1200, 2000,
       '[{"label":"40人(含)以內","price":0},{"label":"41-80人","price":800},{"label":"81人以上","price":1200}]'::jsonb,
       '[{"label":"40人(含)以內","price":800},{"label":"41-80人","price":1200},{"label":"81人以上","price":1800}]'::jsonb
from public.spaces where id in ('22222222-0004-0000-0000-000000000001','22222222-0004-0000-0000-000000000002');

-- 站前-藝文展間
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit, half_setup, full_setup, headcount_tiers, cleanup_tiers) values
  ('22222222-0005-0000-0000-000000000001', 1104, 1380, 5120, 6150, 9350, 11460, 3000, 1000, 1800,
   '[{"label":"30人(含)以內","price":0},{"label":"31-60人","price":600},{"label":"61人以上","price":1000}]'::jsonb,
   '[{"label":"30人(含)以內","price":800},{"label":"31-60人","price":1200},{"label":"61人以上","price":1500}]'::jsonb);

-- 站前-階梯教室
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit, half_setup, full_setup, headcount_tiers, cleanup_tiers) values
  ('22222222-0005-0000-0000-000000000002', 960, 1200, 4480, 5380, 8120, 9920, 3000, 800, 1500,
   '[{"label":"30人(含)以內","price":0},{"label":"31-60人","price":600},{"label":"61人以上","price":1000}]'::jsonb,
   '[{"label":"30人(含)以內","price":800},{"label":"31-60人","price":1200},{"label":"61人以上","price":1500}]'::jsonb);

-- 站前-多功能 1 館 / 2 館
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit, half_setup, full_setup, headcount_tiers, cleanup_tiers)
select id, 1104, 1380, 5000, 6050, 9250, 11360, 3000, 1000, 1800,
       '[{"label":"30人(含)以內","price":0},{"label":"31-60人","price":600},{"label":"61人以上","price":1000}]'::jsonb,
       '[{"label":"30人(含)以內","price":800},{"label":"31-60人","price":1000},{"label":"61人以上","price":1200}]'::jsonb
from public.spaces where id in ('22222222-0005-0000-0000-000000000003','22222222-0005-0000-0000-000000000004');

-- 站前-階梯+展間
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit, half_setup, full_setup, headcount_tiers, cleanup_tiers) values
  ('22222222-0005-0000-0000-000000000005', 1320, 1650, 6820, 8050, 11900, 14350, 5000, 1500, 2200,
   '[{"label":"60人(含)以內","price":0},{"label":"61-100人","price":1200},{"label":"101-140人","price":1800},{"label":"141人以上","price":2400}]'::jsonb,
   '[{"label":"60人(含)以內","price":1200},{"label":"61-100人","price":1800},{"label":"101-140人","price":2400},{"label":"141人以上","price":3000}]'::jsonb);

-- 站前-多功能全館
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit, half_setup, full_setup, headcount_tiers, cleanup_tiers) values
  ('22222222-0005-0000-0000-000000000006', 1480, 1850, 7450, 8850, 13120, 15950, 5000, 1500, 2200,
   '[{"label":"60人(含)以內","price":0},{"label":"61-100人","price":1200},{"label":"101-140人","price":1800},{"label":"141人以上","price":2400}]'::jsonb,
   '[{"label":"60人(含)以內","price":1200},{"label":"61-100人","price":1800},{"label":"101-140人","price":2400},{"label":"141人以上","price":3000}]'::jsonb);

-- 站前-藝文半展間
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit, half_setup, full_setup, headcount_tiers, cleanup_tiers) values
  ('22222222-0005-0000-0000-000000000007', 800, 1000, 3750, 4500, 6820, 8350, 3000, 800, 1500,
   '[{"label":"20人(含)以內","price":0},{"label":"21-40人","price":600},{"label":"41人以上","price":1000}]'::jsonb,
   '[{"label":"20人(含)以內","price":500},{"label":"21-40人","price":800},{"label":"41人以上","price":1200}]'::jsonb);

-- 站前-會議室 / 洽談室 / 休息室（統一清潔費）
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit, cleanup_flat) values
  ('22222222-0005-0000-0000-000000000008', 544, 680, 2080, 2580, 4160, 5200, 1000, 300),
  ('22222222-0005-0000-0000-000000000009', 440, 550, 1680, 2090, 3380, 4210, 1000, 300),
  ('22222222-0005-0000-0000-000000000010', 384, 480, 1460, 1850, 2950, 3680, 1000, 300);

-- 站前-外廣場 / 外長廊
insert into public.prices (space_id, weekday_hourly, weekend_hourly, weekday_half, weekend_half, weekday_full, weekend_full, deposit)
select id, 640, 800, 2450, 3050, 4900, 6120, 5000
from public.spaces where id in ('22222222-0005-0000-0000-000000000011','22222222-0005-0000-0000-000000000012');

-- ============================================================
-- E. 測試客戶（Joanna）
-- ============================================================
insert into public.customers (id, name, email, phone, line_id, birthday, gender, tier_id, total_spent, total_orders, stored_value_balance, loyalty_points, registered_at, last_order_at) values
  ('33333333-0001-0000-0000-000000000001',
   'Joanna', 'joanna@urfit.com.tw', '0912-345-678', 'joanna_w',
   '1990-08-15', 'female',
   (select id from public.membership_tiers where code = 'gold'),
   45680, 8, 2000, 312,
   '2025-08-15 10:00:00+08', '2026-05-29 14:30:00+08');

-- ============================================================
-- F. 範例優惠券
-- ============================================================
insert into public.coupons (code, name, description, discount_type, discount_value, min_order_amount, valid_from, valid_until, total_quantity, per_customer_limit, status) values
  ('WELCOME200',  '新會員迎賓 NT$200', '註冊後 30 天內可用',          'amount',  200,  500,  now(), now() + interval '30 days', 1000, 1, 'active'),
  ('BIRTHDAY300', '會員生日禮 NT$300', '生日當月有效，全館適用',         'amount',  300,  1500, now(), now() + interval '60 days', null,  1, 'active'),
  ('SUMMER85',    '夏季限定 85 折',    '平日方案、最高折抵 NT$1,500',    'percent', 15,   3000, now(), now() + interval '90 days', 500,   1, 'active'),
  ('REFER500',    '推薦好友獎勵 NT$500','推薦人和受推薦人都可得',          'amount',  500,  2000, now(), now() + interval '90 days', null,  1, 'active');

-- ============================================================
-- G. 系統參數
-- ============================================================
insert into public.system_settings (key, value, description) values
  ('payment_due_days', '3', '訂單建立後幾天內必須付款'),
  ('cancel_refund_policy', '{"days_7_plus": 100, "days_3_to_6": 80, "within_48hr": 0}', '取消退款政策（% 退款）'),
  ('point_earn_rate', '0.01', '消費獲得點數比例（1% = 0.01）'),
  ('point_value', '1', '1 點 = NT$ 1'),
  ('default_company_account', '{"bank":"國泰世華 013","account":"0001234567890"}', '公司收款帳號'),
  ('night_surcharge_multiplier', '1.5', '夜間時段加成倍數');

-- ============================================================
-- ✅ Seed Data 載入完成
-- 下一步：執行 06_storage_buckets.sql
-- ============================================================
