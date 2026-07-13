-- Omnya Driver
-- Initial setup profile location fields.
-- Date: 2026-07-12
-- Execute manually in Supabase SQL Editor before testing the new onboarding flow.

alter table driver.profiles
  add column if not exists city text,
  add column if not exists state text,
  add column if not exists country text not null default 'Brasil';

update driver.profiles
set
  city = coalesce(nullif(city, ''), nullif(public_city, '')),
  country = coalesce(nullif(country, ''), 'Brasil')
where city is null
   or city = ''
   or country is null
   or country = '';
