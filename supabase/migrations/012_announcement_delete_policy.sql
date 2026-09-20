-- =========================================================
-- Migration: allow Veteran/Admin to delete announcement images
-- from storage (migration 011 only granted SELECT + INSERT on
-- that bucket). The announcements table row itself was already
-- deletable via the existing "for all" RLS policy.
-- =========================================================

create policy announcement_images_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'announcement-images'
    and public.user_role(auth.uid()) in ('veteran', 'admin')
  );
