-- What an in-app notification says (which reminder and the facts its text
-- is built from), so the app shows the list in its current language instead
-- of the language it was created in. Null on older rows and from older app
-- versions; those keep showing their stored title and subtitle.
alter table public.notifications
  add column message jsonb
  constraint notifications_message_check
    check (message is null or (jsonb_typeof(message) = 'object' and message ? 'kind'));
