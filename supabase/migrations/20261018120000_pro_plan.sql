-- Sakk Pro: a free plan with limits and a paid plan (Google Play, through
-- RevenueCat) without them.
--
-- The limits live in app_config, read by these functions and by the app, so
-- they change without a release. Everything is enforced here; the app's own
-- checks only decide when to show the paywall.
--
-- Downgrading never deletes or hides anything: when Pro ends, existing rows
-- stay readable and editable, and only inserts above the free limits fail.
--
-- Days (for the daily AI quotas) start at midnight in Africa/Cairo.

-- ---------------------------------------------------------------------------
-- Config
-- ---------------------------------------------------------------------------

create table public.app_config (
  key text primary key check (length(key) between 1 and 100),
  value jsonb not null,
  updated_at timestamptz not null default now()
);

create trigger app_config_updated_at
  before update on public.app_config
  for each row execute function public.update_updated_at_column();

alter table public.app_config enable row level security;

-- Readable by the app; only the service role (dashboard, SQL editor) writes.
create policy "Signed-in users can read app config" on public.app_config
  for select to authenticated using (true);

-- null means unlimited. Everything starts unlimited, so deploying this
-- changes nothing for current users (including older app versions, which
-- can't show the paywall). Turn the free plan on when the release with the
-- paywall is out:
--
--   update public.app_config set value = '{
--     "free": {"products": null, "subscriptions": null, "installments": 2, "scan_per_day": 5, "chat_per_day": 10},
--     "pro":  {"products": null, "subscriptions": null, "installments": null, "scan_per_day": null, "chat_per_day": 200}
--   }' where key = 'limits';
--
-- Pro's chat number is a fair-use cap, not a feature.
insert into public.app_config (key, value) values ('limits', '{
  "free": {"products": null, "subscriptions": null, "installments": null, "scan_per_day": null, "chat_per_day": null},
  "pro":  {"products": null, "subscriptions": null, "installments": null, "scan_per_day": null, "chat_per_day": null}
}');

-- The limit for [p_name] on [p_plan] ('free' or 'pro'), or null for no limit.
create function public.app_limit(p_plan text, p_name text)
returns integer
language sql stable security definer set search_path = ''
as $$
  select (value -> p_plan ->> p_name)::integer
  from public.app_config where key = 'limits'
$$;

revoke all on function public.app_limit(text, text) from public, anon;
grant execute on function public.app_limit(text, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Pro entitlement (one row per user, written by the revenuecat-webhook
-- function with the service role)
-- ---------------------------------------------------------------------------
-- Named pro_subscriptions, not subscriptions: in this app "subscriptions"
-- are the services users track (user_subscriptions).

create table public.pro_subscriptions (
  user_id uuid primary key references auth.users (id) on delete cascade,
  entitlement text not null default 'pro',
  -- Pro while this is in the future. Includes Google Play's grace period
  -- during a billing issue, as RevenueCat reports it.
  active_until timestamptz,
  product_id text,
  is_trial boolean not null default false,
  -- False once the user cancels: Pro still runs until active_until.
  will_renew boolean not null default true,
  -- Set on BILLING_ISSUE, cleared by a renewal; the app shows "payment problem".
  billing_issue_at timestamptz,
  store text,
  -- The newest RevenueCat event applied, so an older one arriving late
  -- can't undo it.
  last_event_at timestamptz,
  updated_at timestamptz not null default now()
);

create trigger pro_subscriptions_updated_at
  before update on public.pro_subscriptions
  for each row execute function public.update_updated_at_column();

alter table public.pro_subscriptions enable row level security;

-- Read-only for users: no insert, update or delete policies.
create policy "Users can view their own Pro subscription" on public.pro_subscriptions
  for select using ((select auth.uid()) = user_id);

-- RevenueCat event ids already applied, so a retried webhook is a no-op.
create table public.revenuecat_events (
  id text primary key,
  type text not null,
  app_user_id text,
  received_at timestamptz not null default now()
);

-- No policies: service role only.
alter table public.revenuecat_events enable row level security;

create function public.is_pro(p_user_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.pro_subscriptions
    where user_id = p_user_id and active_until > now()
  )
$$;

-- Not callable by users (it would tell anyone whether another user id has
-- Pro); the functions below run as its owner. The app reads its own plan
-- through get_usage_status.
revoke all on function public.is_pro(uuid) from public, anon, authenticated;
grant execute on function public.is_pro(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- Daily AI usage
-- ---------------------------------------------------------------------------

create table public.usage (
  user_id uuid not null references auth.users (id) on delete cascade,
  -- The day in Africa/Cairo.
  day date not null,
  type text not null check (type in ('scan', 'chat')),
  count integer not null default 0 check (count >= 0),
  primary key (user_id, day, type)
);

alter table public.usage enable row level security;

-- Users can see their counters; only consume_quota and refund_quota change them.
create policy "Users can view their own usage" on public.usage
  for select using ((select auth.uid()) = user_id);

create function public.cairo_today()
returns date
language sql stable set search_path = ''
as $$ select (now() at time zone 'Africa/Cairo')::date $$;

-- Takes one [p_type] ('scan' or 'chat') from the caller's quota for today.
--
-- Atomic: the upsert's "where count < limit" runs under the row lock, so two
-- requests at once can't both take the last one. Pro users have no scan
-- limit (only counted) and a fair-use chat cap.
--
-- Returns {"allowed": bool, "remaining": int or null (no limit), "pro": bool}.
create function public.consume_quota(p_type text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
  pro boolean;
  lim integer;
  new_count integer;
begin
  if me is null then raise exception 'not_authenticated'; end if;
  if p_type not in ('scan', 'chat') then raise exception 'invalid_quota_type'; end if;

  pro := public.is_pro(me);
  lim := public.app_limit(case when pro then 'pro' else 'free' end, p_type || '_per_day');

  if lim is null then
    insert into public.usage as u (user_id, day, type, count)
      values (me, public.cairo_today(), p_type, 1)
      on conflict (user_id, day, type) do update set count = u.count + 1;
    return jsonb_build_object('allowed', true, 'remaining', null, 'pro', pro);
  end if;

  insert into public.usage as u (user_id, day, type, count)
    values (me, public.cairo_today(), p_type, 1)
    on conflict (user_id, day, type) do update set count = u.count + 1
      where u.count < lim
    returning count into new_count;

  -- No row returned: the existing counter was already at the limit. (A
  -- limit of 0 lets the first insert through, so check that too.)
  if new_count is null or new_count > lim then
    if new_count is not null then
      update public.usage set count = count - 1
        where user_id = me and day = public.cairo_today() and type = p_type;
    end if;
    return jsonb_build_object('allowed', false, 'remaining', 0, 'pro', pro);
  end if;

  return jsonb_build_object('allowed', true, 'remaining', lim - new_count, 'pro', pro);
end
$$;

revoke all on function public.consume_quota(text) from public, anon;
grant execute on function public.consume_quota(text) to authenticated;

-- Gives back one [p_type] to [p_user_id] today, after a scan or chat failed
-- on our side. Service role only (the edge functions): if users could call
-- it, they could refund themselves forever.
create function public.refund_quota(p_type text, p_user_id uuid)
returns void
language sql security definer set search_path = ''
as $$
  update public.usage set count = count - 1
  where user_id = p_user_id and day = public.cairo_today() and type = p_type and count > 0
$$;

revoke all on function public.refund_quota(text, uuid) from public, anon, authenticated;
grant execute on function public.refund_quota(text, uuid) to service_role;

-- ---------------------------------------------------------------------------
-- Item limits
-- ---------------------------------------------------------------------------

-- How many [p_kind] items count toward the limit for [p_user_id].
--   products:      their own products (not the household's).
--   subscriptions: their tracked subscriptions.
--   installments:  plans still running (active with a payment left), so a
--                  finished or cancelled plan frees the slot.
create function public.limited_item_count(p_kind text, p_user_id uuid)
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
  end::integer
$$;

revoke all on function public.limited_item_count(text, uuid) from public, anon, authenticated;

-- BEFORE INSERT on the three tables: TG_ARGV[0] is the kind. Raises
-- "LIMIT_REACHED:<kind>" (SQLSTATE P0001), which the app turns into the
-- paywall.
create function public.enforce_item_limit()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  kind text := tg_argv[0];
  lim integer;
begin
  -- Service role and SQL editor inserts (no signed-in user) aren't limited.
  if (select auth.uid()) is null then return new; end if;
  if public.is_pro(new.user_id) then return new; end if;

  lim := public.app_limit('free', kind);
  if lim is null then return new; end if;

  -- One insert at a time per user and kind, so two parallel inserts can't
  -- both see room for one more.
  perform pg_advisory_xact_lock(hashtext(kind), hashtext(new.user_id::text));

  if public.limited_item_count(kind, new.user_id) >= lim then
    raise exception 'LIMIT_REACHED:%', kind
      using hint = format('Free plan allows %s %s', lim, kind);
  end if;
  return new;
end
$$;

create trigger products_free_limit
  before insert on public.products
  for each row execute function public.enforce_item_limit('products');

create trigger user_subscriptions_free_limit
  before insert on public.user_subscriptions
  for each row execute function public.enforce_item_limit('subscriptions');

create trigger installment_plans_free_limit
  before insert on public.installment_plans
  for each row execute function public.enforce_item_limit('installments');

-- Reactivating a cancelled plan takes a slot too.
create trigger installment_plans_free_limit_reactivate
  before update of status on public.installment_plans
  for each row
  when (old.status = 'cancelled' and new.status = 'active')
  execute function public.enforce_item_limit('installments');

-- ---------------------------------------------------------------------------
-- Status for the app
-- ---------------------------------------------------------------------------

-- Everything the app shows about the plan in one call:
-- {
--   "pro": true,
--   "plan": {"product_id", "is_trial", "active_until", "will_renew", "billing_issue"} or null,
--   "scan": {"used": 1, "limit": 3, "remaining": 2},      -- limit/remaining null = unlimited
--   "chat": {"used": 0, "limit": 5, "remaining": 5},
--   "items": {"products": {"count": 4, "limit": 5}, "subscriptions": {...}, "installments": {...}},
--   "day": "2026-10-18"                                   -- today in Cairo
-- }
create function public.get_usage_status()
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

  foreach q in array array['scan', 'chat'] loop
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

  foreach k in array array['products', 'subscriptions', 'installments'] loop
    items := items || jsonb_build_object(k, jsonb_build_object(
      'count', public.limited_item_count(k, me),
      'limit', public.app_limit(plan_name, k)
    ));
  end loop;

  return result || jsonb_build_object('items', items);
end
$$;

revoke all on function public.get_usage_status() from public, anon;
grant execute on function public.get_usage_status() to authenticated;

-- ---------------------------------------------------------------------------
-- AI chat history
-- ---------------------------------------------------------------------------

create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null check (length(content) between 1 and 8000),
  created_at timestamptz not null default now()
);

create index chat_messages_user_created_idx on public.chat_messages (user_id, created_at desc);

alter table public.chat_messages enable row level security;

create policy "Users can view their own chat messages" on public.chat_messages
  for select using ((select auth.uid()) = user_id);

create policy "Users can insert their own chat messages" on public.chat_messages
  for insert with check ((select auth.uid()) = user_id);

create policy "Users can delete their own chat messages" on public.chat_messages
  for delete using ((select auth.uid()) = user_id);
