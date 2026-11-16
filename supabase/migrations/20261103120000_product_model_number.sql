-- Model number: the manufacturer's model code, which service centres ask for
-- on a warranty claim. NULL for every existing product until the user adds it.
alter table public.products
  add column model_number text;
