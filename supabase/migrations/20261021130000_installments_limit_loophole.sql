-- Close the ways around the free plan's limit on running installment plans.
--
-- Only plans with a pending payment count toward the limit, so a free user
-- could get more running plans by:
--   1. adding a plan with no payments, then inserting its payments directly;
--   2. marking a finished plan's payment unpaid again after adding a new plan
--      (reachable from the app);
--   3. editing a finished plan so it gets new pending payments.
--
-- Payments can now only be inserted by save_installment_plan, and a plan
-- that starts counting again is checked against the limit. Editing a plan
-- that is already running is never blocked, so nothing changes for users
-- who went over the limit while they had Pro.

-- ---------------------------------------------------------------------------
-- The check
-- ---------------------------------------------------------------------------

-- Raises LIMIT_REACHED:installments if the caller has no room for one more
-- running plan. Call it while the plan in question doesn't count yet.
-- Uses the caller's id only, so it tells nobody anything about other users.
create function public._ensure_installment_slot()
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
  lim integer;
begin
  -- Service role and SQL editor changes aren't limited.
  if me is null or public.is_pro(me) then return; end if;
  lim := public.app_limit('free', 'installments');
  if lim is null then return; end if;
  -- Same lock as enforce_item_limit, so parallel requests queue up.
  perform pg_advisory_xact_lock(hashtext('installments'), hashtext(me::text));
  if public.limited_item_count('installments', me) >= lim then
    raise exception 'LIMIT_REACHED:installments'
      using hint = format('Free plan allows %s installments', lim);
  end if;
end
$$;

revoke all on function public._ensure_installment_slot() from public, anon;
grant execute on function public._ensure_installment_slot() to authenticated;

-- ---------------------------------------------------------------------------
-- 1. Payments are inserted only by save_installment_plan
-- ---------------------------------------------------------------------------
-- The function sets sakk.saving_plan for its own transaction. API clients
-- can't set settings (pg_catalog isn't exposed), and every API request is
-- its own transaction, so the flag never leaks to a later request.

alter policy "Users can insert payments on their own installment plans" on public.installment_payments
  with check (
    current_setting('sakk.saving_plan', true) = 'on'
    and (select auth.uid()) = user_id
    and exists (
      select 1 from public.installment_plans p
      where p.id = installment_payments.plan_id and p.user_id = (select auth.uid())
    )
  );

-- Users only mark payments paid or unpaid; amounts, dates and plans change
-- through save_installment_plan.
revoke update on public.installment_payments from anon, authenticated;
grant update (status, paid_at) on public.installment_payments to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Unmarking a payment on a finished plan
-- ---------------------------------------------------------------------------

create function public._installment_payment_reopened()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  -- The plan only starts counting again if it's active and this would be
  -- its only pending payment (the row is still 'paid' in the table here).
  if exists (select 1 from public.installment_plans where id = new.plan_id and status = 'active')
     and not exists (
       select 1 from public.installment_payments
       where plan_id = new.plan_id and status = 'pending' and id <> new.id
     ) then
    perform public._ensure_installment_slot();
  end if;
  return new;
end
$$;

revoke all on function public._installment_payment_reopened() from public, anon, authenticated;

create trigger installment_payments_reopen_limit
  before update of status on public.installment_payments
  for each row
  when (old.status = 'paid' and new.status = 'pending')
  execute function public._installment_payment_reopened();

-- ---------------------------------------------------------------------------
-- 3. save_installment_plan: sets the flag, and checks a plan that starts
--    counting again
-- ---------------------------------------------------------------------------

create or replace function public.save_installment_plan(p_plan jsonb, p_payments jsonb)
returns public.installment_plans
language plpgsql security invoker set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
  v_plan_id uuid := (p_plan ->> 'id')::uuid;
  saved public.installment_plans;
  paid_count integer := 0;
  was_running boolean := false;
begin
  if me is null then raise exception 'not_authenticated'; end if;
  if p_payments is null or jsonb_typeof(p_payments) <> 'array' then
    raise exception 'invalid_payments';
  end if;

  if v_plan_id is null then
    -- A new plan is checked by the installment_plans_free_limit trigger.
    insert into public.installment_plans (
      product_id, title, provider, currency, total_price, down_payment,
      installment_amount, installments_count, start_date, due_day_of_month,
      interest_or_fees, notes, status
    ) values (
      (p_plan ->> 'product_id')::uuid,
      p_plan ->> 'title',
      p_plan ->> 'provider',
      coalesce(p_plan ->> 'currency', 'EGP'),
      (p_plan ->> 'total_price')::numeric,
      coalesce((p_plan ->> 'down_payment')::numeric, 0),
      (p_plan ->> 'installment_amount')::numeric,
      (p_plan ->> 'installments_count')::integer,
      (p_plan ->> 'start_date')::date,
      (p_plan ->> 'due_day_of_month')::smallint,
      (p_plan ->> 'interest_or_fees')::numeric,
      p_plan ->> 'notes',
      coalesce(p_plan ->> 'status', 'active')
    )
    returning * into saved;
  else
    -- Whether the plan counts toward the limit before this edit.
    select p.status = 'active'
           and exists (select 1 from public.installment_payments x
                       where x.plan_id = p.id and x.status = 'pending')
      into was_running
      from public.installment_plans p
      where p.id = v_plan_id;

    update public.installment_plans set
      product_id = (p_plan ->> 'product_id')::uuid,
      title = p_plan ->> 'title',
      provider = p_plan ->> 'provider',
      currency = coalesce(p_plan ->> 'currency', 'EGP'),
      total_price = (p_plan ->> 'total_price')::numeric,
      down_payment = coalesce((p_plan ->> 'down_payment')::numeric, 0),
      installment_amount = (p_plan ->> 'installment_amount')::numeric,
      installments_count = (p_plan ->> 'installments_count')::integer,
      start_date = (p_plan ->> 'start_date')::date,
      due_day_of_month = (p_plan ->> 'due_day_of_month')::smallint,
      interest_or_fees = (p_plan ->> 'interest_or_fees')::numeric,
      notes = p_plan ->> 'notes',
      status = coalesce(p_plan ->> 'status', 'active')
    where id = v_plan_id
    returning * into saved;
    -- Missing, or someone else's (RLS hides it).
    if saved.id is null then raise exception 'plan_not_found'; end if;

    delete from public.installment_payments
      where installment_payments.plan_id = saved.id and status = 'pending';
    select count(*) into paid_count from public.installment_payments
      where installment_payments.plan_id = saved.id;

    -- A finished plan given new pending payments starts counting again.
    -- Checked now, while it has none, so it isn't counted against itself.
    if not coalesce(was_running, false) and saved.status = 'active'
       and jsonb_array_length(p_payments) > 0 then
      perform public._ensure_installment_slot();
    end if;
  end if;

  -- Paid ones kept plus the new pending ones must make up the whole plan.
  if paid_count + jsonb_array_length(p_payments) <> saved.installments_count then
    raise exception 'schedule_count_mismatch';
  end if;

  perform set_config('sakk.saving_plan', 'on', true);
  insert into public.installment_payments (plan_id, due_date, amount)
    select saved.id, (p ->> 'due_date')::date, (p ->> 'amount')::numeric
    from jsonb_array_elements(p_payments) as p;
  perform set_config('sakk.saving_plan', 'off', true);

  return saved;
end
$$;
