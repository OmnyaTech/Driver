-- Omnya Driver
-- Platform logo column only.
-- Date: 2026-07-10
-- Execute this first and alone in Supabase SQL Editor.

set lock_timeout = '5s';

alter table driver.platforms
  add column if not exists logo_url text;

reset lock_timeout;
