-- Subscriptions: online services the user pays for on a cycle (Netflix,
-- Shahid, Spotify...), so the app can show what they cost each month and
-- remind before each renewal.
--
-- subscription_catalog is a shared, read-only list of known services and
-- their plans; user_subscriptions holds what each user actually pays for,
-- picked from the catalog or entered by hand.

-- ---------------------------------------------------------------------------
-- Catalog
-- ---------------------------------------------------------------------------

create table public.subscription_catalog (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (length(name) between 1 and 100),
  category text not null default 'other'
    check (category in ('streaming', 'music', 'gaming', 'cloud', 'productivity', 'ai', 'delivery', 'telecom', 'other')),
  -- Used for the logo (Google favicon service) when logo_url is null.
  domain text check (domain ~ '^[a-z0-9.-]+\.[a-z]{2,}$'),
  logo_url text,
  -- [{"name": "Premium", "price": 240, "currency": "EGP", "billing_cycle": "monthly"}, ...]
  plans jsonb not null default '[]'::jsonb
    check (jsonb_typeof(plans) = 'array'),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.subscription_catalog enable row level security;

-- Read-only for users: no insert, update or delete policies, so only the
-- service role can change the list. Inactive services stay readable so
-- existing subscriptions keep their name and logo; the app's picker only
-- offers active ones.
create policy "Signed-in users can view catalog services" on public.subscription_catalog
  for select to authenticated using (true);

-- ---------------------------------------------------------------------------
-- User subscriptions
-- ---------------------------------------------------------------------------

create table public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  -- Null for a custom subscription; set null if the service leaves the catalog
  -- (the row keeps its own price and cycle, so nothing else breaks).
  catalog_id uuid references public.subscription_catalog (id) on delete set null,
  custom_name text check (length(custom_name) between 1 and 100),
  plan_name text check (length(plan_name) between 1 and 100),
  -- Copied from the catalog when picked from it; chosen by the user for a
  -- custom one. Used for the Analytics breakdown.
  category text not null default 'other'
    check (category in ('streaming', 'music', 'gaming', 'cloud', 'productivity', 'ai', 'delivery', 'telecom', 'other')),
  price numeric(12, 2) not null check (price >= 0),
  currency text not null default 'EGP' check (currency ~ '^[A-Z]{3}$'),
  billing_cycle text not null check (billing_cycle in ('monthly', 'yearly')),
  next_renewal_date date not null,
  payment_method text check (length(payment_method) between 1 and 100),
  notes text check (length(notes) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_subscriptions_has_name check (catalog_id is not null or custom_name is not null)
);

-- The list is the user's rows ordered by the nearest renewal.
create index user_subscriptions_user_renewal_idx on public.user_subscriptions (user_id, next_renewal_date);
create index user_subscriptions_catalog_id_idx on public.user_subscriptions (catalog_id);

create trigger user_subscriptions_updated_at
  before update on public.user_subscriptions
  for each row execute function public.update_updated_at_column();

alter table public.user_subscriptions enable row level security;

-- Private to the user (not shared with the household, unlike products).
create policy "Users can view their own subscriptions" on public.user_subscriptions
  for select using ((select auth.uid()) = user_id);

create policy "Users can insert their own subscriptions" on public.user_subscriptions
  for insert with check ((select auth.uid()) = user_id);

create policy "Users can update their own subscriptions" on public.user_subscriptions
  for update using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete their own subscriptions" on public.user_subscriptions
  for delete using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- Seed: popular services in Egypt
-- ---------------------------------------------------------------------------
-- PLACEHOLDER PRICES: every price below is an estimate and must be verified
-- before release. Prices change often and differ between web, App Store and
-- Google Play billing.

insert into public.subscription_catalog (name, category, domain, plans) values
  -- Video streaming
  ('Netflix', 'streaming', 'netflix.com', '[
    {"name": "Basic",    "price": 120, "currency": "EGP", "billing_cycle": "monthly"},
    {"name": "Standard", "price": 190, "currency": "EGP", "billing_cycle": "monthly"},
    {"name": "Premium",  "price": 240, "currency": "EGP", "billing_cycle": "monthly"}
  ]'),
  ('Shahid', 'streaming', 'shahid.mbc.net', '[
    {"name": "VIP",        "price": 100,  "currency": "EGP", "billing_cycle": "monthly"},
    {"name": "VIP",        "price": 1000, "currency": "EGP", "billing_cycle": "yearly"},
    {"name": "VIP | Sports", "price": 250, "currency": "EGP", "billing_cycle": "monthly"}
  ]'),
  ('OSN+', 'streaming', 'osnplus.com', '[
    {"name": "Monthly", "price": 135,  "currency": "EGP", "billing_cycle": "monthly"},
    {"name": "Yearly",  "price": 1350, "currency": "EGP", "billing_cycle": "yearly"}
  ]'),
  ('WATCH IT', 'streaming', 'watchit.com', '[
    {"name": "Monthly", "price": 100,  "currency": "EGP", "billing_cycle": "monthly"},
    {"name": "Yearly",  "price": 1000, "currency": "EGP", "billing_cycle": "yearly"}
  ]'),
  ('Yango Play', 'streaming', 'yango.com', '[
    {"name": "Monthly", "price": 100, "currency": "EGP", "billing_cycle": "monthly"}
  ]'),
  ('Disney+', 'streaming', 'disneyplus.com', '[
    {"name": "Monthly", "price": 5.99, "currency": "USD", "billing_cycle": "monthly"}
  ]'),
  ('Amazon Prime Video', 'streaming', 'primevideo.com', '[
    {"name": "Monthly", "price": 3.99, "currency": "USD", "billing_cycle": "monthly"}
  ]'),
  ('YouTube Premium', 'streaming', 'youtube.com', '[
    {"name": "Individual", "price": 75,  "currency": "EGP", "billing_cycle": "monthly"},
    {"name": "Family",     "price": 140, "currency": "EGP", "billing_cycle": "monthly"}
  ]'),

  -- Music
  ('Spotify', 'music', 'spotify.com', '[
    {"name": "Individual", "price": 80,  "currency": "EGP", "billing_cycle": "monthly"},
    {"name": "Duo",        "price": 100, "currency": "EGP", "billing_cycle": "monthly"},
    {"name": "Family",     "price": 120, "currency": "EGP", "billing_cycle": "monthly"},
    {"name": "Student",    "price": 45,  "currency": "EGP", "billing_cycle": "monthly"}
  ]'),
  ('Anghami', 'music', 'anghami.com', '[
    {"name": "Plus",        "price": 50,  "currency": "EGP", "billing_cycle": "monthly"},
    {"name": "Plus Family", "price": 100, "currency": "EGP", "billing_cycle": "monthly"}
  ]'),
  ('Apple Music', 'music', 'music.apple.com', '[
    {"name": "Individual", "price": 4.99, "currency": "USD", "billing_cycle": "monthly"},
    {"name": "Family",     "price": 7.99, "currency": "USD", "billing_cycle": "monthly"}
  ]'),

  -- Cloud storage
  ('iCloud+', 'cloud', 'icloud.com', '[
    {"name": "50 GB",  "price": 0.99, "currency": "USD", "billing_cycle": "monthly"},
    {"name": "200 GB", "price": 2.99, "currency": "USD", "billing_cycle": "monthly"},
    {"name": "2 TB",   "price": 9.99, "currency": "USD", "billing_cycle": "monthly"}
  ]'),
  ('Google One', 'cloud', 'one.google.com', '[
    {"name": "100 GB", "price": 40,  "currency": "EGP", "billing_cycle": "monthly"},
    {"name": "2 TB",   "price": 200, "currency": "EGP", "billing_cycle": "monthly"}
  ]'),

  -- Productivity and AI
  ('Microsoft 365', 'productivity', 'microsoft.com', '[
    {"name": "Personal", "price": 1300, "currency": "EGP", "billing_cycle": "yearly"},
    {"name": "Family",   "price": 1700, "currency": "EGP", "billing_cycle": "yearly"}
  ]'),
  ('ChatGPT', 'ai', 'chatgpt.com', '[
    {"name": "Plus", "price": 20,  "currency": "USD", "billing_cycle": "monthly"},
    {"name": "Pro",  "price": 200, "currency": "USD", "billing_cycle": "monthly"}
  ]'),
  ('Claude', 'ai', 'claude.ai', '[
    {"name": "Pro", "price": 20,  "currency": "USD", "billing_cycle": "monthly"},
    {"name": "Max", "price": 100, "currency": "USD", "billing_cycle": "monthly"}
  ]'),

  -- Gaming
  ('Xbox Game Pass', 'gaming', 'xbox.com', '[
    {"name": "Core",     "price": 9.99,  "currency": "USD", "billing_cycle": "monthly"},
    {"name": "Ultimate", "price": 19.99, "currency": "USD", "billing_cycle": "monthly"}
  ]'),
  ('PlayStation Plus', 'gaming', 'playstation.com', '[
    {"name": "Essential", "price": 79.99,  "currency": "USD", "billing_cycle": "yearly"},
    {"name": "Extra",     "price": 134.99, "currency": "USD", "billing_cycle": "yearly"}
  ]'),

  -- Delivery
  ('talabat pro', 'delivery', 'talabat.com', '[
    {"name": "Monthly", "price": 50, "currency": "EGP", "billing_cycle": "monthly"}
  ]'),

  -- Telecom
  ('Vodafone Egypt', 'telecom', 'vodafone.com.eg', '[
    {"name": "Monthly bundle", "price": 200, "currency": "EGP", "billing_cycle": "monthly"}
  ]'),
  ('Orange Egypt', 'telecom', 'orange.eg', '[
    {"name": "Monthly bundle", "price": 200, "currency": "EGP", "billing_cycle": "monthly"}
  ]'),
  ('e& Egypt', 'telecom', 'etisalat.eg', '[
    {"name": "Monthly bundle", "price": 200, "currency": "EGP", "billing_cycle": "monthly"}
  ]'),
  ('WE', 'telecom', 'te.eg', '[
    {"name": "Home internet", "price": 250, "currency": "EGP", "billing_cycle": "monthly"}
  ]');
