-- Add by voice (Sakk Pro): the user says what they bought and the
-- extract-receipt function turns it into a product. Each one takes a
-- "voice" from a daily quota like scans and chats: none on the free plan
-- (Pro only), a fair-use cap on Pro. Both numbers live in app_config.

alter table public.usage drop constraint usage_type_check;
alter table public.usage add constraint usage_type_check check (type in ('scan', 'chat', 'voice'));

update public.app_config
set value = jsonb_set(jsonb_set(value, '{free,voice_per_day}', '0'), '{pro,voice_per_day}', '30')
where key = 'limits';

-- Same as in the pro_plan migration, with 'voice' added.
create or replace function public.consume_quota(p_type text)
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
  if p_type not in ('scan', 'chat', 'voice') then raise exception 'invalid_quota_type'; end if;

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

  foreach k in array array['products', 'subscriptions', 'installments'] loop
    items := items || jsonb_build_object(k, jsonb_build_object(
      'count', public.limited_item_count(k, me),
      'limit', public.app_limit(plan_name, k)
    ));
  end loop;

  return result || jsonb_build_object('items', items);
end
$$;
