-- ============================================================
-- 沃茲新創空間 - Indexes (Step 2/6)
-- ============================================================
-- 加速常用查詢的索引
-- ============================================================

-- venues
create index idx_venues_status on public.venues(status) where deleted_at is null;
create index idx_venues_district on public.venues(district);

-- spaces
create index idx_spaces_venue on public.spaces(venue_id) where deleted_at is null;
create index idx_spaces_status on public.spaces(status);

-- prices
create index idx_prices_space on public.prices(space_id);

-- customers
create index idx_customers_email on public.customers(email);
create index idx_customers_phone on public.customers(phone);
create index idx_customers_tier on public.customers(tier_id);
create index idx_customers_total_spent on public.customers(total_spent desc);
create index idx_customers_last_order on public.customers(last_order_at desc nulls last);

-- addresses
create index idx_addresses_customer on public.addresses(customer_id);

-- orders（這張表是查詢熱點，多個索引）
create index idx_orders_customer on public.orders(customer_id) where deleted_at is null;
create index idx_orders_space on public.orders(space_id);
create index idx_orders_booking_date on public.orders(booking_date);
create index idx_orders_status on public.orders(status);
create index idx_orders_payment_status on public.orders(payment_status);
create index idx_orders_created_at on public.orders(created_at desc);
create index idx_orders_payment_account_last5 on public.orders(payment_account_last5);
create index idx_orders_queue_parent on public.orders(queue_parent_id) where queue_parent_id is not null;
-- 給「重複時段查詢」用
create index idx_orders_slot_conflict on public.orders(space_id, booking_date, start_time, end_time, status)
  where status in ('pending','paid','confirmed');

-- coupons
create index idx_coupons_code on public.coupons(code);
create index idx_coupons_status on public.coupons(status);
create index idx_coupons_valid on public.coupons(valid_from, valid_until);

-- coupon_usage
create index idx_coupon_usage_coupon on public.coupon_usage(coupon_id);
create index idx_coupon_usage_customer on public.coupon_usage(customer_id);
create index idx_coupon_usage_lookup on public.coupon_usage(coupon_id, customer_id);  -- 給「該客戶用過幾次此券」查詢

-- point_transactions
create index idx_point_tx_customer on public.point_transactions(customer_id, created_at desc);

-- stored_value_transactions
create index idx_sv_tx_customer on public.stored_value_transactions(customer_id, created_at desc);

-- bank_transactions
create index idx_bank_tx_date on public.bank_transactions(transaction_date desc);
create index idx_bank_tx_last5 on public.bank_transactions(account_last5);
create index idx_bank_tx_match_status on public.bank_transactions(match_status);
create index idx_bank_tx_batch on public.bank_transactions(batch_id);
create index idx_bank_tx_amount on public.bank_transactions(amount);

-- bank_transaction_orders
create index idx_bto_tx on public.bank_transaction_orders(bank_transaction_id);
create index idx_bto_order on public.bank_transaction_orders(order_id);

-- import_batches
create index idx_import_batches_imported_at on public.import_batches(imported_at desc);

-- venue_pages
create index idx_venue_pages_venue on public.venue_pages(venue_id);
create index idx_venue_pages_status on public.venue_pages(status);

-- messages
create index idx_messages_customer on public.messages(customer_id, created_at desc);
create index idx_messages_status on public.messages(status, created_at);

-- ============================================================
-- ✅ Indexes 建立完成
-- 下一步：執行 03_triggers_functions.sql
-- ============================================================
