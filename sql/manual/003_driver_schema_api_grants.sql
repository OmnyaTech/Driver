-- Omnya Driver
-- API grants for custom schema exposure support.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

grant usage on schema driver to anon, authenticated, service_role;

grant all on all tables in schema driver to anon, authenticated, service_role;
grant all on all routines in schema driver to anon, authenticated, service_role;
grant all on all sequences in schema driver to anon, authenticated, service_role;

alter default privileges for role postgres in schema driver
  grant all on tables to anon, authenticated, service_role;

alter default privileges for role postgres in schema driver
  grant all on routines to anon, authenticated, service_role;

alter default privileges for role postgres in schema driver
  grant all on sequences to anon, authenticated, service_role;
