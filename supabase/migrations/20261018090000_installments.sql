-- Installments: purchases paid off in monthly installments (bank, Valu,
-- Contact, Sympl, the store...), so the app can show what's left to pay and
-- remind before each due date.
--
-- installment_plans holds the terms; installment_payments holds one row per
-- installment. The app builds the schedule (the same code draws the preview
-- in the form) and saves plan and payments together with
-- save_installment_plan, so a plan never exists without its payments.
--
-- Not stored, worked out in the app: remaining balance, paid count, next due
-- date, progress, "overdue" (pending and past its due date) and "completed"
-- (every payment paid).

-- ---------------------------------------------------------------------------
-- Plans
-- ---------------------------------------------------------------------------

create table public.installment_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  -- Optional link to one of the user's products. If the product is deleted
  -- the plan stays, under its title.
  product_id uuid references public.products (id) on delete set null,
  -- Always set: the product's name when one is linked (so the plan keeps a
  -- name if the product goes), otherwise what the user typed.
  title text not null check (length(title) between 1 and 100),
  -- Free text: bank, Valu, Contact, Sympl, the store...
  provider text check (length(provider) between 1 and 100),
  currency text not null default 'EGP' check (currency ~ '^[A-Z]{3}$'),
  total_price numeric(12, 2) not null check (total_price >= 0),
  down_payment numeric(12, 2) not null default 0 check (down_payment >= 0),
  installment_amount numeric(12, 2) not null check (installment_amount > 0),
  installments_count integer not null check (installments_count between 1 and 360),
  -- The first installment's due date.
  start_date date not null,
  -- 29-31 fall on the last day of shorter months.
  due_day_of_month smallint not null check (due_day_of_month between 1 and 31),
  interest_or_fees numeric(12, 2) check (interest_or_fees >= 0),
  notes text check (length(notes) <= 2000),
  -- "completed" isn't stored: it's every payment being paid.
  status text not null default 'active' check (status in ('active', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint installment_plans_down_payment_within_price check (down_payment <= total_price)
);

create index installment_plans_user_id_idx on public.installment_plans (user_id);
create index installment_plans_product_id_idx on public.installment_plans (product_id);

create trigger installment_plans_updated_at
  before update on public.installment_plans
  for each row execute function public.update_updated_at_column();

alter table public.installment_plans enable row level security;

-- Private to the user (not shared with the household, unlike products), and
-- only the user's own products can be linked: household members can see each
-- other's products, but not attach plans to them.
create policy "Users can view their own installment plans" on public.installment_plans
  for select using ((select auth.uid()) = user_id);

create policy "Users can insert their own installment plans" on public.installment_plans
  for insert with check (
    (select auth.uid()) = user_id
    and (
      product_id is null
      or exists (
        select 1 from public.products p
        where p.id = installment_plans.product_id and p.user_id = (select auth.uid())
      )
    )
  );

create policy "Users can update their own installment plans" on public.installment_plans
  for update using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and (
      product_id is null
      or exists (
        select 1 from public.products p
        where p.id = installment_plans.product_id and p.user_id = (select auth.uid())
      )
    )
  );

create policy "Users can delete their own installment plans" on public.installment_plans
  for delete using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- Payments
-- ---------------------------------------------------------------------------

create table public.installment_payments (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.installment_plans (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  due_date date not null,
  amount numeric(12, 2) not null check (amount > 0),
  paid_at timestamptz,
  -- "overdue" isn't stored: it's pending and past due_date.
  status text not null default 'pending' check (status in ('pending', 'paid')),
  created_at timestamptz not null default now(),
  constraint installment_payments_paid_has_date check ((status = 'paid') = (paid_at is not null))
);

-- A plan's schedule in order, and the user's upcoming payments across plans.
create index installment_payments_plan_due_idx on public.installment_payments (plan_id, due_date);
create index installment_payments_user_due_idx on public.installment_payments (user_id, due_date);

alter table public.installment_payments enable row level security;

create policy "Users can view their own installment payments" on public.installment_payments
  for select using ((select auth.uid()) = user_id);

create policy "Users can insert payments on their own installment plans" on public.installment_payments
  for insert with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.installment_plans p
      where p.id = installment_payments.plan_id and p.user_id = (select auth.uid())
    )
  );

create policy "Users can update payments on their own installment plans" on public.installment_payments
  for update using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.installment_plans p
      where p.id = installment_payments.plan_id and p.user_id = (select auth.uid())
    )
  );

create policy "Users can delete their own installment payments" on public.installment_payments
  for delete using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- Saving a plan with its schedule
-- ---------------------------------------------------------------------------

-- Adds a plan (p_plan without "id") or updates one (with "id"), together
-- with its unpaid payments, in one transaction.
--
-- p_plan:     the plan's columns, as the app writes them.
-- p_payments: [{"due_date": "2026-11-05", "amount": 1250.00}, ...], the
--             unpaid installments. On an update, paid payments are kept as
--             they are and every pending one is replaced by these.
--
-- Security invoker, so the RLS policies above still decide what the caller
-- may touch.
create function public.save_installment_plan(p_plan jsonb, p_payments jsonb)
returns public.installment_plans
language plpgsql security invoker set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
  v_plan_id uuid := (p_plan ->> 'id')::uuid;
  saved public.installment_plans;
  paid_count integer := 0;
begin
  if me is null then raise exception 'not_authenticated'; end if;
  if p_payments is null or jsonb_typeof(p_payments) <> 'array' then
    raise exception 'invalid_payments';
  end if;

  if v_plan_id is null then
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
  end if;

  -- Paid ones kept plus the new pending ones must make up the whole plan.
  if paid_count + jsonb_array_length(p_payments) <> saved.installments_count then
    raise exception 'schedule_count_mismatch';
  end if;

  insert into public.installment_payments (plan_id, due_date, amount)
    select saved.id, (p ->> 'due_date')::date, (p ->> 'amount')::numeric
    from jsonb_array_elements(p_payments) as p;

  return saved;
end
$$;

revoke all on function public.save_installment_plan(jsonb, jsonb) from public, anon;
grant execute on function public.save_installment_plan(jsonb, jsonb) to authenticated;
