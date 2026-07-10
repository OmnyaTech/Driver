-- Omnya Driver
-- Promote the first Omnya Driver administrator manually.
-- Date: 2026-07-10
-- Replace the e-mail below before executing in Supabase SQL Editor.

update driver.profiles
set
  role = 'developer',
  plan_type = 'developer',
  subscription_status = 'active',
  subscription_expires_at = null,
  current_period_end = null,
  updated_at = timezone('utc', now())
where lower(email) = lower('SEU_EMAIL_AQUI');

insert into driver.subscriptions (
  user_id,
  plan_type,
  status,
  provider,
  started_at,
  created_at,
  updated_at
)
select
  p.id,
  'developer',
  'active',
  'developer_admin',
  timezone('utc', now()),
  timezone('utc', now()),
  timezone('utc', now())
from driver.profiles p
where lower(p.email) = lower('SEU_EMAIL_AQUI');
