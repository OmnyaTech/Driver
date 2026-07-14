-- Omnya Driver
-- Real push cron scheduler for Supabase hosted projects.
-- Date: 2026-07-13
-- Execute manually in Supabase SQL Editor after replacing the placeholders below.
--
-- Required replacements before running:
--   <DRIVER_PUSH_SERVICE_SECRET> with the same value configured as DRIVER_PUSH_SECRET.
--
-- This intentionally does not store real secrets in git.

create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;

do $$
begin
  perform cron.unschedule('driver-send-push-every-5-min');
exception
  when others then
    null;
end;
$$;

select cron.schedule(
  'driver-send-push-every-5-min',
  '*/5 * * * *',
  $$
    select net.http_post(
      url := 'https://cattokugqanpagleawpw.supabase.co/functions/v1/driver-send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-driver-push-secret', '<DRIVER_PUSH_SERVICE_SECRET>'
      ),
      body := jsonb_build_object('limit', 50),
      timeout_milliseconds := 15000
    );
  $$
);
