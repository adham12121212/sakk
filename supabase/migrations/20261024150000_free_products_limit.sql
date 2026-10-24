-- The free plan tracks up to 15 products, however they're added (scan,
-- typed in, by voice, shared). Scans stay limited per day for the AI's
-- cost; this limits what the free plan is for. Users who already have
-- more keep them all: only adding another is refused (enforce_item_limit),
-- and the app opens the paywall.
update public.app_config
set value = jsonb_set(value, '{free,products}', '15')
where key = 'limits';
