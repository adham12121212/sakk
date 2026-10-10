-- Extra warranties on top of the manufacturer's one stored on products
-- (e.g. an extended warranty bought from the store). A product counts as
-- covered until the latest end date across all of its warranties.
create table public.product_warranties (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  provider text not null check (length(provider) between 1 and 200),
  start_date date not null,
  months integer not null check (months between 1 and 240),
  created_at timestamptz not null default now()
);

create index product_warranties_product_id_idx on public.product_warranties (product_id);
create index product_warranties_user_id_idx on public.product_warranties (user_id);

alter table public.product_warranties enable row level security;

create policy "Users can view their own extra warranties" on public.product_warranties
  for select using (auth.uid() = user_id);

create policy "Users can insert extra warranties on their own products" on public.product_warranties
  for insert with check (
    auth.uid() = user_id
    and exists (select 1 from public.products p where p.id = product_id and p.user_id = auth.uid())
  );

create policy "Users can update their own extra warranties" on public.product_warranties
  for update using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.products p where p.id = product_id and p.user_id = auth.uid())
  );

create policy "Users can delete their own extra warranties" on public.product_warranties
  for delete using (auth.uid() = user_id);
