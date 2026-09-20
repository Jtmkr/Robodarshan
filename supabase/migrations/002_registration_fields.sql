-- =========================================================
-- Migration: add registration fields to users + profile
-- picture storage bucket.
--
-- Run this in the Supabase SQL Editor. It is safe to run
-- against your existing database (does not drop anything) --
-- it backfills any existing row(s) with placeholder values
-- before enforcing NOT NULL, so your test account survives.
-- After running, supabase/schema.sql (the fresh-install
-- script) already reflects this end state too.
-- =========================================================

alter table public.users
  add column if not exists name text,
  add column if not exists mobile_number text,
  add column if not exists enrollment_number text,
  add column if not exists personal_email text,
  add column if not exists profile_picture_url text;

update public.users set
  name = coalesce(name, 'Unknown'),
  mobile_number = coalesce(mobile_number, 'unknown'),
  enrollment_number = coalesce(enrollment_number, 'unknown'),
  personal_email = coalesce(personal_email, gsuite_email),
  profile_picture_url = coalesce(profile_picture_url, '')
where name is null
   or mobile_number is null
   or enrollment_number is null
   or personal_email is null
   or profile_picture_url is null;

alter table public.users
  alter column name set not null,
  alter column mobile_number set not null,
  alter column enrollment_number set not null,
  alter column personal_email set not null,
  alter column profile_picture_url set not null;

-- ---------------------------------------------------------
-- Storage: profile pictures bucket + RLS
-- ---------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('profile-pictures', 'profile-pictures', true)
on conflict (id) do nothing;

drop policy if exists profile_pictures_public_read on storage.objects;
create policy profile_pictures_public_read on storage.objects
  for select to public
  using (bucket_id = 'profile-pictures');

drop policy if exists profile_pictures_owner_write on storage.objects;
create policy profile_pictures_owner_write on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'profile-pictures'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists profile_pictures_owner_update on storage.objects;
create policy profile_pictures_owner_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'profile-pictures'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'profile-pictures'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
