-- Omnya Driver
-- Public APK release storage bucket.
-- Date: 2026-07-15
-- Execute manually in Supabase SQL Editor after 042.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'driver-mobile-releases',
  'driver-mobile-releases',
  true,
  104857600,
  array[
    'application/vnd.android.package-archive',
    'application/octet-stream',
    'application/zip'
  ]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "driver_mobile_releases_public_read" on storage.objects;
create policy "driver_mobile_releases_public_read"
  on storage.objects
  for select
  to public
  using (bucket_id = 'driver-mobile-releases');

drop policy if exists "driver_mobile_releases_developer_insert" on storage.objects;
create policy "driver_mobile_releases_developer_insert"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'driver-mobile-releases'
    and exists (
      select 1
      from driver.profiles p
      where p.id = auth.uid()
        and p.role = 'developer'::driver.user_role
    )
  );

drop policy if exists "driver_mobile_releases_developer_update" on storage.objects;
create policy "driver_mobile_releases_developer_update"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'driver-mobile-releases'
    and exists (
      select 1
      from driver.profiles p
      where p.id = auth.uid()
        and p.role = 'developer'::driver.user_role
    )
  )
  with check (
    bucket_id = 'driver-mobile-releases'
    and exists (
      select 1
      from driver.profiles p
      where p.id = auth.uid()
        and p.role = 'developer'::driver.user_role
    )
  );

drop policy if exists "driver_mobile_releases_developer_delete" on storage.objects;
create policy "driver_mobile_releases_developer_delete"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'driver-mobile-releases'
    and exists (
      select 1
      from driver.profiles p
      where p.id = auth.uid()
        and p.role = 'developer'::driver.user_role
    )
  );
