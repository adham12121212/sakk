-- The day of the month a subscription renews on. next_renewal_date alone
-- loses it in a short month: a renewal on the 31st is stored as Nov 30 and
-- then drifted to the 30th for good. With the day kept, Nov 30 goes back to
-- Dec 31, and the app can tell which day the last renewal was on.
alter table public.user_subscriptions
  add column renewal_day smallint check (renewal_day between 1 and 31);

-- Keeps renewal_day matching next_renewal_date: the date falls on that
-- day, or on its month's last day when the month is shorter. Otherwise
-- (a new row, an app version that doesn't send it, a date moved by hand)
-- the date's own day becomes the renewal day.
create or replace function public.sync_renewal_day()
returns trigger
language plpgsql set search_path = ''
as $$
declare
  d smallint := extract(day from new.next_renewal_date);
  last_day smallint := extract(day from
    (date_trunc('month', new.next_renewal_date::timestamp)
      + interval '1 month - 1 day'));
begin
  if new.renewal_day is null
     or not (d = new.renewal_day or (d = last_day and d < new.renewal_day)) then
    new.renewal_day := d;
  end if;
  return new;
end;
$$;

create trigger user_subscriptions_sync_renewal_day
  before insert or update of next_renewal_date, renewal_day
  on public.user_subscriptions
  for each row execute function public.sync_renewal_day();

-- Existing rows: the best guess is the day they're on now.
update public.user_subscriptions
set renewal_day = extract(day from next_renewal_date);

alter table public.user_subscriptions alter column renewal_day set not null;
