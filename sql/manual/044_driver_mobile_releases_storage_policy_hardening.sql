-- Omnya Driver
-- Harden mobile release storage policies.
-- Date: 2026-07-15
-- Execute manually in Supabase SQL Editor after 043.

drop policy if exists "driver_mobile_releases_public_read" on storage.objects;

-- Keep the bucket public for direct object downloads by known path:
-- /storage/v1/object/public/driver-mobile-releases/{file}
--
-- Do not keep a broad SELECT policy on storage.objects for this bucket. That
-- policy lets clients list every file in the bucket and causes the Supabase
-- dashboard warning about broad file listing.
