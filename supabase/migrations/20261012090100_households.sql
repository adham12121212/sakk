-- Family sharing. A household is a group of users who see each other's
-- products (with their extra warranties, claims and documents). Only the
-- person who added a product can change or delete it. A user is in at most
-- one household. Joining needs the household's invite code.

create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 60),
  invite_code text not null unique,
  created_at timestamptz not null default now()
);

create table public.household_members (
  user_id uuid primary key references auth.users (id) on delete cascade, -- one household per user
  household_id uuid not null references public.households (id) on delete cascade,
  -- Copied at join time: members can't read each other's auth profile.
  display_name text not null check (length(trim(display_name)) between 1 and 80),
  role text not null check (role in ('owner', 'member')),
  joined_at timestamptz not null default now()
);

create index household_members_household_id_idx on public.household_members (household_id);

alter table public.households enable row level security;
alter table public.household_members enable row level security;

-- ---------------------------------------------------------------------------
-- Helpers. SECURITY DEFINER so policies can look at household_members without
-- recursing into its own RLS; an empty search_path so nothing can shadow them.

-- The caller's household, or null.
create function public.my_household_id() returns uuid
language sql stable security definer set search_path = ''
as $$
  select household_id from public.household_members where user_id = (select auth.uid())
$$;

-- True if [owner] is the caller or a member of the caller's household.
create function public.shares_household_with(owner uuid) returns boolean
language sql stable security definer set search_path = ''
as $$
  select owner = (select auth.uid())
    or exists (
      select 1
      from public.household_members me
      join public.household_members them on them.household_id = me.household_id
      where me.user_id = (select auth.uid()) and them.user_id = owner
    )
$$;

-- ---------------------------------------------------------------------------
-- Members see their household and its members. All changes go through the
-- functions below (no direct insert/update/delete).

create policy "Members can view their household" on public.households
  for select using (id = (select public.my_household_id()));

create policy "Members can view their household's members" on public.household_members
  for select using (household_id = (select public.my_household_id()));

-- ---------------------------------------------------------------------------
-- Widen viewing (only viewing) of products and everything attached to them.

alter policy "Users can view their own products" on public.products
  using (public.shares_household_with(user_id));
alter policy "Users can view their own products" on public.products
  rename to "Users and their household can view products";

alter policy "Users can view their own extra warranties" on public.product_warranties
  using (public.shares_household_with(user_id));
alter policy "Users can view their own extra warranties" on public.product_warranties
  rename to "Users and their household can view extra warranties";

alter policy "Users can view their own claims" on public.warranty_claims
  using (public.shares_household_with(user_id));
alter policy "Users can view their own claims" on public.warranty_claims
  rename to "Users and their household can view claims";

alter policy "Users can view their own documents" on public.product_documents
  using (public.shares_household_with(user_id));
alter policy "Users can view their own documents" on public.product_documents
  rename to "Users and their household can view documents";

-- ---------------------------------------------------------------------------
-- Actions (called with supabase.rpc). Each checks the caller itself.

-- 10 hex characters (40 random bits): hard to guess, easy to read out.
create function public._new_invite_code() returns text
language sql volatile set search_path = ''
as $$
  select upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))
$$;
revoke all on function public._new_invite_code() from public, anon, authenticated;

create function public.create_household(p_name text, p_display_name text) returns public.households
language plpgsql security definer set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
  h public.households;
begin
  if me is null then raise exception 'not_authenticated'; end if;
  if exists (select 1 from public.household_members where user_id = me) then
    raise exception 'already_in_household';
  end if;
  insert into public.households (name, invite_code)
    values (trim(p_name), public._new_invite_code())
    returning * into h;
  insert into public.household_members (user_id, household_id, display_name, role)
    values (me, h.id, trim(p_display_name), 'owner');
  return h;
end
$$;

create function public.join_household(p_invite_code text, p_display_name text) returns public.households
language plpgsql security definer set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
  h public.households;
begin
  if me is null then raise exception 'not_authenticated'; end if;
  if exists (select 1 from public.household_members where user_id = me) then
    raise exception 'already_in_household';
  end if;
  select * into h from public.households
    where invite_code = upper(regexp_replace(p_invite_code, '[^0-9A-Za-z]', '', 'g'));
  if h.id is null then raise exception 'invalid_invite_code'; end if;
  if (select count(*) from public.household_members where household_id = h.id) >= 10 then
    raise exception 'household_full';
  end if;
  insert into public.household_members (user_id, household_id, display_name, role)
    values (me, h.id, trim(p_display_name), 'member');
  return h;
end
$$;

create function public.leave_household() returns void
language sql security definer set search_path = ''
as $$
  delete from public.household_members where user_id = (select auth.uid())
$$;

create function public.remove_household_member(p_user_id uuid) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  me uuid := (select auth.uid());
begin
  if not exists (
    select 1 from public.household_members
    where user_id = me and role = 'owner' and household_id = (
      select household_id from public.household_members where user_id = p_user_id
    )
  ) or p_user_id = me then
    raise exception 'not_allowed';
  end if;
  delete from public.household_members where user_id = p_user_id;
end
$$;

-- Owner only: a new code, e.g. after it was shared too widely.
create function public.regenerate_invite_code() returns text
language plpgsql security definer set search_path = ''
as $$
declare
  code text := public._new_invite_code();
begin
  update public.households set invite_code = code
    where id = (
      select household_id from public.household_members
      where user_id = (select auth.uid()) and role = 'owner'
    );
  if not found then raise exception 'not_allowed'; end if;
  return code;
end
$$;

revoke all on function public.create_household(text, text) from public, anon;
revoke all on function public.join_household(text, text) from public, anon;
revoke all on function public.leave_household() from public, anon;
revoke all on function public.remove_household_member(uuid) from public, anon;
revoke all on function public.regenerate_invite_code() from public, anon;
grant execute on function public.create_household(text, text) to authenticated;
grant execute on function public.join_household(text, text) to authenticated;
grant execute on function public.leave_household() to authenticated;
grant execute on function public.remove_household_member(uuid) to authenticated;
grant execute on function public.regenerate_invite_code() to authenticated;

-- ---------------------------------------------------------------------------
-- When someone leaves, is removed or deletes their account: an empty household
-- is deleted, and if the owner left, the longest-standing member takes over.

create function public._after_household_member_removed() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.household_members where household_id = old.household_id) then
    delete from public.households where id = old.household_id;
  elsif not exists (
    select 1 from public.household_members where household_id = old.household_id and role = 'owner'
  ) then
    update public.household_members set role = 'owner'
      where user_id = (
        select user_id from public.household_members
        where household_id = old.household_id
        order by joined_at, user_id
        limit 1
      );
  end if;
  return null;
end
$$;
revoke all on function public._after_household_member_removed() from public, anon, authenticated;

create trigger household_member_removed
  after delete on public.household_members
  for each row execute function public._after_household_member_removed();
