-- My papers: the user's official papers (national ID, passport, driving and
-- car licences, insurance cards, a rental contract...) with a photo of each
-- side and the expiry date, so the app can remind before each one runs out.
--
-- Private to the user: not shared with the household, and never sent to the
-- AI. The photos live in their own private bucket, readable only by their
-- owner (the receipts bucket also lets household members read files that a
-- product points to, which papers must never be open to).
--
-- The free plan keeps a few papers; Pro has no limit. Same item limit
-- machinery as products, subscriptions and installments.

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

create table public.papers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  kind text not null default 'other'
    check (kind in ('national_id', 'passport', 'driving_licence', 'car_licence',
                    'car_insurance', 'health_insurance', 'rental_contract', 'other')),
  -- Whose it is or what it is ("Mona's passport", "Club membership").
  -- Required for 'other'; the app shows the kind's name otherwise.
  title text check (length(title) between 1 and 100),
  -- The paper's own number (ID, passport, licence or policy number).
  number text check (length(number) between 1 and 100),
  -- Null for papers that don't expire.
  expiry_date date,
  -- Storage paths in the papers bucket, always in the owner's folder.
  front_path text check (front_path like user_id::text || '/%'),
  back_path text check (back_path like user_id::text || '/%'),
  notes text check (length(notes) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint papers_other_has_title check (kind <> 'other' or title is not null)
);

-- The list is the user's papers, soonest expiry first.
create index papers_user_expiry_idx on public.papers (user_id, expiry_date);

create trigger papers_updated_at
  before update on public.papers
  for each row execute function public.update_updated_at_column();

alter table public.papers enable row level security;

create policy "Users can view their own papers" on public.papers
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "Users can insert their own papers" on public.papers
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "Users can update their own papers" on public.papers
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete their own papers" on public.papers
  for delete to authenticated using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- Photos
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('papers', 'papers', false, 10485760, array['image/jpeg', 'image/png', 'image/heic', 'image/webp']);

-- Owner only, in their own folder ("<user id>/<file>"). No update rule:
-- a new photo is a new file, and the old one is deleted.
create policy "Users can upload their own paper photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'papers' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "Users can read their own paper photos" on storage.objects
  for select to authenticated
  using (bucket_id = 'papers' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "Users can delete their own paper photos" on storage.objects
  for delete to authenticated
  using (bucket_id = 'papers' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
-- Free plan limit
-- ---------------------------------------------------------------------------

update public.app_config
set value = jsonb_set(jsonb_set(value, '{free,papers}', '3'), '{pro,papers}', 'null')
where key = 'limits';

-- Same as in the pro_plan migration, with papers added.
create or replace function public.limited_item_count(p_kind text, p_user_id uuid)
returns integer
language sql stable security definer set search_path = ''
as $$
  select case p_kind
    when 'products' then
      (select count(*) from public.products where user_id = p_user_id)
    when 'subscriptions' then
      (select count(*) from public.user_subscriptions where user_id = p_user_id)
    when 'installments' then
      (select count(*) from public.installment_plans p
        where p.user_id = p_user_id and p.status = 'active'
          and exists (select 1 from public.installment_payments x
                      where x.plan_id = p.id and x.status = 'pending'))
    when 'papers' then
      (select count(*) from public.papers where user_id = p_user_id)
  end::integer
$$;

create trigger papers_free_limit
  before insert on public.papers
  for each row execute function public.enforce_item_limit('papers');

-- Same as in the voice_quota migration, with papers in the item counts.
create or replace function public.get_usage_status()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
  pro boolean;
  plan_name text;
  sub public.pro_subscriptions;
  result jsonb;
  q text;
  used integer;
  lim integer;
  k text;
  items jsonb := '{}'::jsonb;
begin
  if me is null then raise exception 'not_authenticated'; end if;
  pro := public.is_pro(me);
  plan_name := case when pro then 'pro' else 'free' end;
  select * into sub from public.pro_subscriptions where user_id = me;

  result := jsonb_build_object(
    'pro', pro,
    'day', public.cairo_today(),
    'plan', case when sub.user_id is null then null else jsonb_build_object(
      'product_id', sub.product_id,
      'is_trial', sub.is_trial,
      'active_until', sub.active_until,
      'will_renew', sub.will_renew,
      'billing_issue', sub.billing_issue_at is not null
    ) end
  );

  foreach q in array array['scan', 'chat', 'voice'] loop
    select coalesce((select count from public.usage
                     where user_id = me and day = public.cairo_today() and type = q), 0)
      into used;
    lim := public.app_limit(plan_name, q || '_per_day');
    result := result || jsonb_build_object(q, jsonb_build_object(
      'used', used,
      'limit', lim,
      'remaining', case when lim is null then null else greatest(lim - used, 0) end
    ));
  end loop;

  foreach k in array array['products', 'subscriptions', 'installments', 'papers'] loop
    items := items || jsonb_build_object(k, jsonb_build_object(
      'count', public.limited_item_count(k, me),
      'limit', public.app_limit(plan_name, k)
    ));
  end loop;

  return result || jsonb_build_object('items', items);
end
$$;
