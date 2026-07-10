-- Omnya Driver
-- Profile avatar storage bucket and policies.
-- Date: 2026-07-10
-- Execute manually in Supabase SQL Editor.

alter table driver.profiles
  add column if not exists avatar_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'driver-avatars',
  'driver-avatars',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "driver_avatars_public_read" on storage.objects;
create policy "driver_avatars_public_read"
  on storage.objects
  for select
  to public
  using (bucket_id = 'driver-avatars');

drop policy if exists "driver_avatars_authenticated_insert" on storage.objects;
create policy "driver_avatars_authenticated_insert"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'driver-avatars'
    and auth.uid() is not null
    and split_part(name, '/', 1) = auth.uid()::text
  );

drop policy if exists "driver_avatars_authenticated_update" on storage.objects;
create policy "driver_avatars_authenticated_update"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'driver-avatars'
    and auth.uid() is not null
    and split_part(name, '/', 1) = auth.uid()::text
  )
  with check (
    bucket_id = 'driver-avatars'
    and auth.uid() is not null
    and split_part(name, '/', 1) = auth.uid()::text
  );

drop policy if exists "driver_avatars_authenticated_delete" on storage.objects;
create policy "driver_avatars_authenticated_delete"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'driver-avatars'
    and auth.uid() is not null
    and split_part(name, '/', 1) = auth.uid()::text
  );
