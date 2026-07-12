-- Omnya Driver
-- Adds pending status for subscription checkout flow.
-- Date: 2026-07-12
-- Execute manually in Supabase SQL Editor before
-- sql/manual/017_driver_subscription_pending_checkout.sql.

alter type driver.subscription_status add value if not exists 'pending';
