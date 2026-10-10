-- Speed: wrap auth.uid() in a subquery so Postgres evaluates it once per
-- query instead of once per row (Supabase advisor: auth_rls_initplan).
-- The rules themselves are unchanged.

alter policy "Users can delete their own notifications" on public.notifications
  using (((select auth.uid()) = user_id));

alter policy "Users can insert their own notifications" on public.notifications
  with check (((select auth.uid()) = user_id));

alter policy "Users can view their own notifications" on public.notifications
  using (((select auth.uid()) = user_id));

alter policy "Users can update their own notifications" on public.notifications
  using (((select auth.uid()) = user_id));

alter policy "Users can delete their own extra warranties" on public.product_warranties
  using (((select auth.uid()) = user_id));

alter policy "Users can insert extra warranties on their own products" on public.product_warranties
  with check ((((select auth.uid()) = user_id) AND (EXISTS ( SELECT 1
   FROM products p
  WHERE ((p.id = product_warranties.product_id) AND (p.user_id = (select auth.uid())))))));

alter policy "Users can view their own extra warranties" on public.product_warranties
  using (((select auth.uid()) = user_id));

alter policy "Users can update their own extra warranties" on public.product_warranties
  using (((select auth.uid()) = user_id))
  with check ((((select auth.uid()) = user_id) AND (EXISTS ( SELECT 1
   FROM products p
  WHERE ((p.id = product_warranties.product_id) AND (p.user_id = (select auth.uid())))))));

alter policy "Users can delete their own products" on public.products
  using (((select auth.uid()) = user_id));

alter policy "Users can insert their own products" on public.products
  with check (((select auth.uid()) = user_id));

alter policy "Users can view their own products" on public.products
  using (((select auth.uid()) = user_id));

alter policy "Users can update their own products" on public.products
  using (((select auth.uid()) = user_id));

alter policy "Users can delete their own claims" on public.warranty_claims
  using (((select auth.uid()) = user_id));

alter policy "Users can insert claims on their own products" on public.warranty_claims
  with check ((((select auth.uid()) = user_id) AND (EXISTS ( SELECT 1
   FROM products p
  WHERE ((p.id = warranty_claims.product_id) AND (p.user_id = (select auth.uid())))))));

alter policy "Users can view their own claims" on public.warranty_claims
  using (((select auth.uid()) = user_id));

alter policy "Users can update their own claims" on public.warranty_claims
  using (((select auth.uid()) = user_id))
  with check ((((select auth.uid()) = user_id) AND (EXISTS ( SELECT 1
   FROM products p
  WHERE ((p.id = warranty_claims.product_id) AND (p.user_id = (select auth.uid())))))));

-- Security: pin the trigger function's search_path so a schema earlier on the
-- caller's path can't shadow what it calls (advisor: function_search_path_mutable).
-- now() comes from pg_catalog, which is always searched first.
alter function public.update_updated_at_column() set search_path = '';
