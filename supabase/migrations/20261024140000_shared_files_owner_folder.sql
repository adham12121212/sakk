-- Household members read the receipts and documents of products they can
-- see. The rule matched the file by name only, so a user could point one of
-- their own products' receipt_url at someone else's file (any path in the
-- receipts bucket) and then read it. Now the file must also be in the
-- folder of the user who owns that product or document.
alter policy "Household members can read shared product files" on storage.objects
  using (
    bucket_id = 'receipts'
    and (
      exists (
        select 1 from public.product_documents d
        where d.file_path = objects.name
          and (storage.foldername(objects.name))[1] = d.user_id::text
      )
      or exists (
        select 1 from public.products p
        where objects.name in (public.receipt_object_path(p.receipt_url), public.receipt_object_path(p.image_url))
          and (storage.foldername(objects.name))[1] = p.user_id::text
      )
    )
  );
