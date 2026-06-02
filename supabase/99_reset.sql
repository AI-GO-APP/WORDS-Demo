-- ============================================================
-- 沃茲新創空間 - Reset (only for development!)
-- ============================================================
-- ⚠️ 警告：這會 DROP 所有資料表，會清空所有資料
-- 只在開發 / 測試時使用，絕對不要在 production 跑
-- ============================================================

-- DROP 順序：依 FK 依賴反向
drop trigger if exists trg_orders_order_number on public.orders cascade;
drop trigger if exists trg_orders_payment_last5 on public.orders cascade;
drop trigger if exists trg_orders_queue_position on public.orders cascade;
drop trigger if exists trg_orders_confirmed on public.orders cascade;
drop trigger if exists trg_point_tx on public.point_transactions cascade;
drop trigger if exists trg_sv_tx on public.stored_value_transactions cascade;
drop trigger if exists trg_customer_tier_check on public.customers cascade;

drop function if exists public.expire_unpaid_orders cascade;
drop function if exists public.handle_order_confirmed cascade;
drop function if exists public.calc_queue_position cascade;
drop function if exists public.fill_payment_last5 cascade;
drop function if exists public.generate_payment_last5 cascade;
drop function if exists public.fill_order_number cascade;
drop function if exists public.generate_order_number cascade;
drop function if exists public.update_customer_points cascade;
drop function if exists public.update_customer_stored_value cascade;
drop function if exists public.check_tier_upgrade cascade;
drop function if exists public.set_updated_at cascade;

drop table if exists public.system_settings cascade;
drop table if exists public.audit_logs cascade;
drop table if exists public.messages cascade;
drop table if exists public.venue_pages cascade;
drop table if exists public.bank_transaction_orders cascade;
drop table if exists public.bank_transactions cascade;
drop table if exists public.import_batches cascade;
drop table if exists public.stored_value_transactions cascade;
drop table if exists public.point_transactions cascade;
drop table if exists public.coupon_usage cascade;
drop table if exists public.coupons cascade;
drop table if exists public.orders cascade;
drop table if exists public.addresses cascade;
drop table if exists public.customers cascade;
drop table if exists public.membership_tiers cascade;
drop table if exists public.prices cascade;
drop table if exists public.spaces cascade;
drop table if exists public.venues cascade;

-- 清掉 Storage（如有需要，去 Dashboard 手動刪）

-- ============================================================
-- 清空後可重跑 01-06 重新建立
-- ============================================================
