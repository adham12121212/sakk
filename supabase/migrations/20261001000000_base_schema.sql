-- The schema the app started with, before the migrations in this folder: the
-- products and notifications tables, the updated_at trigger function and the
-- storage buckets. It was set up in the dashboard, so a fresh project had
-- nothing for the later migrations to build on. Rebuilt from the live
-- database's catalog (2026-10-23) as it stood before 20261010120000; later
-- migrations add return_days, widen and rename the products view rule, pin
-- the function's search_path, make the receipts bucket private and limit the
-- rules to signed-in users.
--
-- The live project already has all of this. Mark it as applied there instead
-- of running it:
--   supabase migration repair --status applied 20261001000000

-- ---------------------------------------------------------------------------
-- updated_at
-- ---------------------------------------------------------------------------

create function public.update_updated_at_column() returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------

create table public.products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  brand text,
  store_name text,
  invoice_number text,
  serial_number text,
  barcode text,
  price numeric,
  currency text not null default 'EGP',
  quantity integer not null default 1 constraint products_quantity_check check (quantity > 0),
  purchase_date date not null,
  warranty_months integer not null constraint products_warranty_months_check check (warranty_months >= 0),
  warranty_source text default 'manual',
  notes text,
  image_url text,
  receipt_url text,
  ocr_text text,
  ai_raw_response jsonb,
  ai_confidence real,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  status text default 'active',
  category text not null default 'other'
    constraint products_category_check
    check (category in ('electronics', 'appliances', 'furniture', 'vehicles', 'accessories', 'other'))
);

create index idx_products_user_id on public.products (user_id);
create index idx_products_purchase_date on public.products (purchase_date);
create index idx_products_invoice on public.products (invoice_number);
create index idx_products_store on public.products (store_name);
create index idx_products_brand on public.products (brand);

create trigger products_updated_at
  before update on public.products
  for each row execute function public.update_updated_at_column();

alter table public.products enable row level security;

create policy "Users can view their own products" on public.products
  for select using (auth.uid() = user_id);
create policy "Users can insert their own products" on public.products
  for insert with check (auth.uid() = user_id);
create policy "Users can update their own products" on public.products
  for update using (auth.uid() = user_id);
create policy "Users can delete their own products" on public.products
  for delete using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Notifications (the in-app list)
-- ---------------------------------------------------------------------------

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  subtitle text not null,
  type text not null constraint notifications_type_check check (type in ('warning', 'success', 'info', 'error')),
  product_id uuid references public.products (id) on delete set null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index notifications_user_id_idx on public.notifications (user_id);

alter table public.notifications enable row level security;

create policy "Users can view their own notifications" on public.notifications
  for select using (auth.uid() = user_id);
create policy "Users can insert their own notifications" on public.notifications
  for insert with check (auth.uid() = user_id);
create policy "Users can update their own notifications" on public.notifications
  for update using (auth.uid() = user_id);
create policy "Users can delete their own notifications" on public.notifications
  for delete using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Storage: receipts (and product documents) and avatars, each user in their
-- own <user id>/ folder
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public) values
  ('receipts', 'receipts', true),
  ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "Users upload to own folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can upload their own avatar" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can update their own avatar" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
