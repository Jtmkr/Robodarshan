-- =========================================================
-- Migration: announcements get an optional image, Veteran (in
-- addition to Admin) can create them, and anyone (including
-- logged-out visitors) can read them -- they show on the public
-- Home page, not just inside the member portal.
-- =========================================================

alter table public.announcements add column if not exists image_url text;

-- Public read (Home page is public) -- previously authenticated-only.
drop policy if exists announcements_select on public.announcements;
create policy announcements_select on public.announcements
  for select to anon, authenticated
  using (true);

-- Veteran or Admin can create/manage announcements -- previously admin-only.
drop policy if exists announcements_admin_write on public.announcements;
create policy announcements_write on public.announcements
  for all to authenticated
  using (public.user_role(auth.uid()) in ('veteran', 'admin'))
  with check (public.user_role(auth.uid()) in ('veteran', 'admin'));

-- ---------------------------------------------------------
-- Storage: announcement images bucket + RLS
-- ---------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('announcement-images', 'announcement-images', true)
on conflict (id) do nothing;

drop policy if exists announcement_images_public_read on storage.objects;
create policy announcement_images_public_read on storage.objects
  for select to public
  using (bucket_id = 'announcement-images');

drop policy if exists announcement_images_write on storage.objects;
create policy announcement_images_write on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'announcement-images'
    and public.user_role(auth.uid()) in ('veteran', 'admin')
  );
