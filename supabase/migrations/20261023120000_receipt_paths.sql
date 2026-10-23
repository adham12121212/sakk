-- Receipts and product documents are now stored as storage paths
-- (<user id>/<file>) instead of 5-year signed URLs, and the app signs a
-- short-lived link each time products load. Older rows still hold a signed
-- URL; the app reads the path out of it.
--
-- Signing needs read access to the file. Owners already have it ("Users can
-- read their own receipts"); household members, who see each other's
-- products, get it here for exactly the files those products point to, so
-- nothing else in a member's folder (e.g. subscription screenshots) is open
-- to them, and they can't list it.

-- The storage path in a products.receipt_url / image_url value: the value
-- itself when it's a path, the path inside it when it's a signed receipts
-- URL, otherwise null.
create function public.receipt_object_path(value text) returns text
language sql immutable set search_path = ''
as $$
  select case
    when value like '%/storage/v1/object/sign/receipts/%'
      then split_part(split_part(value, '/storage/v1/object/sign/receipts/', 2), '?', 1)
    when value !~ '://' then value
  end
$$;

-- The products and product_documents rules decide what the caller can see
-- (their own rows and their household's).
create policy "Household members can read shared product files" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'receipts'
    and (
      exists (
        select 1 from public.product_documents d
        where d.file_path = objects.name
      )
      or exists (
        select 1 from public.products p
        where objects.name in (public.receipt_object_path(p.receipt_url), public.receipt_object_path(p.image_url))
      )
    )
  );
