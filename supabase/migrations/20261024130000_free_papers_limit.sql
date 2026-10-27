-- The free plan keeps 2 papers (was 3); Pro still has no limit. Users who
-- already have more keep them all: only adding another is refused.
update public.app_config
set value = jsonb_set(value, '{free,papers}', '2')
where key = 'limits';
