-- Tighten access rules after an audit of every policy and the Supabase
-- security advisor. The app's behaviour doesn't change.

-- ---------------------------------------------------------------------------
-- Receipts bucket: private
-- ---------------------------------------------------------------------------
-- It was public, so anyone with a file's path could open a receipt without
-- signing in, whatever the storage rules said. The app only ever uses signed
-- URLs for receipts and documents (none of the stored URLs are public links),
-- and signed URLs keep working on a private bucket.
update storage.buckets set public = false where id = 'receipts';

-- ---------------------------------------------------------------------------
-- Rules for signed-in users only
-- ---------------------------------------------------------------------------
-- These applied to every role. Signed-out requests already matched nothing
-- (auth.uid() is null), but now the rules don't even run for them.

alter policy "Users can view their own chat messages" on public.chat_messages to authenticated;
alter policy "Users can insert their own chat messages" on public.chat_messages to authenticated;
alter policy "Users can delete their own chat messages" on public.chat_messages to authenticated;

alter policy "Members can view their household" on public.households to authenticated;
alter policy "Members can view their household's members" on public.household_members to authenticated;

alter policy "Users can view their own installment plans" on public.installment_plans to authenticated;
alter policy "Users can insert their own installment plans" on public.installment_plans to authenticated;
alter policy "Users can update their own installment plans" on public.installment_plans to authenticated;
alter policy "Users can delete their own installment plans" on public.installment_plans to authenticated;

alter policy "Users can view their own installment payments" on public.installment_payments to authenticated;
alter policy "Users can insert payments on their own installment plans" on public.installment_payments to authenticated;
alter policy "Users can update payments on their own installment plans" on public.installment_payments to authenticated;
alter policy "Users can delete their own installment payments" on public.installment_payments to authenticated;

alter policy "Users can view their own notifications" on public.notifications to authenticated;
alter policy "Users can insert their own notifications" on public.notifications to authenticated;
alter policy "Users can update their own notifications" on public.notifications to authenticated;
alter policy "Users can delete their own notifications" on public.notifications to authenticated;

alter policy "Users can view their own Pro subscription" on public.pro_subscriptions to authenticated;

alter policy "Users and their household can view documents" on public.product_documents to authenticated;
alter policy "Users can add documents to their own products" on public.product_documents to authenticated;
alter policy "Users can delete their own documents" on public.product_documents to authenticated;

alter policy "Users and their household can view extra warranties" on public.product_warranties to authenticated;
alter policy "Users can insert extra warranties on their own products" on public.product_warranties to authenticated;
alter policy "Users can update their own extra warranties" on public.product_warranties to authenticated;
alter policy "Users can delete their own extra warranties" on public.product_warranties to authenticated;

alter policy "Users and their household can view products" on public.products to authenticated;
alter policy "Users can insert their own products" on public.products to authenticated;
alter policy "Users can update their own products" on public.products to authenticated;
alter policy "Users can delete their own products" on public.products to authenticated;

alter policy "Users can view their own usage" on public.usage to authenticated;

alter policy "Users can view their own subscriptions" on public.user_subscriptions to authenticated;
alter policy "Users can insert their own subscriptions" on public.user_subscriptions to authenticated;
alter policy "Users can update their own subscriptions" on public.user_subscriptions to authenticated;
alter policy "Users can delete their own subscriptions" on public.user_subscriptions to authenticated;

alter policy "Users and their household can view claims" on public.warranty_claims to authenticated;
alter policy "Users can insert claims on their own products" on public.warranty_claims to authenticated;
alter policy "Users can update their own claims" on public.warranty_claims to authenticated;
alter policy "Users can delete their own claims" on public.warranty_claims to authenticated;

-- ---------------------------------------------------------------------------
-- Storage rules
-- ---------------------------------------------------------------------------
-- auth.uid() in a subquery (advisor: auth_rls_initplan), and the avatar rules
-- the app needs: re-uploading an avatar is an upsert, which also reads the
-- existing file, and deleting the account removes it.

alter policy "Users upload to own folder" on storage.objects
  with check (bucket_id = 'receipts' and (storage.foldername(name))[1] = (select auth.uid())::text);

alter policy "Users can upload their own avatar" on storage.objects
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

alter policy "Users can update their own avatar" on storage.objects
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "Users can read their own avatar" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "Users can delete their own avatar" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- ---------------------------------------------------------------------------
-- Functions
-- ---------------------------------------------------------------------------

-- A trigger function: never meant to be called through the API (advisor:
-- anon/authenticated_security_definer_function_executable).
revoke all on function public.enforce_item_limit() from public, anon, authenticated;

-- app_config is readable by signed-in users anyway, so app_limit doesn't need
-- its owner's rights. The SECURITY DEFINER functions that call it still run
-- as the owner, and the service role skips RLS.
alter function public.app_limit(text, text) security invoker;

-- ---------------------------------------------------------------------------
-- Performance
-- ---------------------------------------------------------------------------

-- Deleting a product looks up its notifications (advisor: unindexed_foreign_keys).
create index if not exists notifications_product_id_idx on public.notifications (product_id);
