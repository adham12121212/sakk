-- Return window: how many days after purchase the store accepts a return or
-- exchange. NULL means the user isn't tracking one (every existing product).
alter table public.products
  add column return_days integer
  constraint products_return_days_check check (return_days between 1 and 365);
