-- Receipt photos: each user can only read, upload and delete files in their
-- own folder (receipts/<user id>/...), which is where the app stores them.
--
-- The old rules let any signed-in user read or delete every user's receipts,
-- and upload anywhere in the bucket. Signed URLs (how the app shows receipts)
-- keep working: they're checked by their token, not by these rules, and the
-- delete-account function uses the service role.

drop policy if exists "Authenticated users can read receipts" on storage.objects;
drop policy if exists "Authenticated users can delete receipts" on storage.objects;
drop policy if exists "Authenticated users can upload receipts" on storage.objects;

-- "Users upload to own folder" (insert, own folder only) already exists and stays.

create policy "Users can read their own receipts" on storage.objects
  for select to authenticated
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "Users can delete their own receipts" on storage.objects
  for delete to authenticated
  using (bucket_id = 'receipts' and (storage.foldername(name))[1] = (select auth.uid())::text);
