-- The two helpers used by the household access rules only make sense for a
-- signed-in user. They answer "no" for anyone else, but Supabase flags them as
-- callable by signed-out visitors (advisor: anon_security_definer_function_
-- executable), so limit them to signed-in users. Signed-out requests for
-- products already return nothing; with this they get a permission error.
revoke execute on function public.my_household_id() from public, anon;
revoke execute on function public.shares_household_with(uuid) from public, anon;
grant execute on function public.my_household_id() to authenticated;
grant execute on function public.shares_household_with(uuid) to authenticated;
