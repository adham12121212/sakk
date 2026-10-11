-- More than one document per product: the warranty card, a product photo, the
-- manual... next to the receipt that stays on products.receipt_url. Files live
-- in the receipts bucket under the owner's folder; file_url is a signed URL.
create table public.product_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  kind text not null check (kind in ('receipt', 'warranty_card', 'product_photo', 'manual', 'other')),
  file_url text not null check (length(file_url) between 1 and 2000),
  -- Storage path, so the file can be deleted with the document. Always in
  -- the owner's own folder, matching the storage rules.
  file_path text not null check (file_path like user_id::text || '/%'),
  created_at timestamptz not null default now()
);

create index product_documents_product_id_idx on public.product_documents (product_id);
create index product_documents_user_id_idx on public.product_documents (user_id);

alter table public.product_documents enable row level security;

-- Viewing is widened to household members in the household migration.
create policy "Users can view their own documents" on public.product_documents
  for select using ((select auth.uid()) = user_id);

create policy "Users can add documents to their own products" on public.product_documents
  for insert with check (
    (select auth.uid()) = user_id
    and exists (select 1 from public.products p where p.id = product_id and p.user_id = (select auth.uid()))
  );

create policy "Users can delete their own documents" on public.product_documents
  for delete using ((select auth.uid()) = user_id);
