-- Warranty claims: a record of each time the user asked the store or maker to
-- repair or replace a product, and where that claim stands.
create table public.warranty_claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  issue text not null check (length(issue) between 1 and 2000),
  status text not null default 'submitted'
    check (status in ('submitted', 'in_repair', 'resolved', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index warranty_claims_product_id_idx on public.warranty_claims (product_id);
create index warranty_claims_user_id_idx on public.warranty_claims (user_id);

create trigger warranty_claims_updated_at
  before update on public.warranty_claims
  for each row execute function public.update_updated_at_column();

alter table public.warranty_claims enable row level security;

-- Same rules as products: users only touch their own rows. Inserts and
-- updates must also point at a product the user owns.
create policy "Users can view their own claims" on public.warranty_claims
  for select using (auth.uid() = user_id);

create policy "Users can insert claims on their own products" on public.warranty_claims
  for insert with check (
    auth.uid() = user_id
    and exists (select 1 from public.products p where p.id = product_id and p.user_id = auth.uid())
  );

create policy "Users can update their own claims" on public.warranty_claims
  for update using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.products p where p.id = product_id and p.user_id = auth.uid())
  );

create policy "Users can delete their own claims" on public.warranty_claims
  for delete using (auth.uid() = user_id);
