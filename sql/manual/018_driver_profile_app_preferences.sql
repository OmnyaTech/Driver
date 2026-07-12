-- Omnya Driver
-- Driver app language and currency preferences.
-- Date: 2026-07-12
-- Execute manually in Supabase SQL Editor.

alter table driver.profiles
  add column if not exists language_code text not null default 'pt-BR',
  add column if not exists currency_code text not null default 'BRL';

update driver.profiles
set
  language_code = coalesce(nullif(language_code, ''), 'pt-BR'),
  currency_code = coalesce(nullif(currency_code, ''), 'BRL')
where language_code is null
   or language_code = ''
   or currency_code is null
   or currency_code = '';
