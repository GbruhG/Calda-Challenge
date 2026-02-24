-- reusable trigger function to keep updated_at current on any table
-- for "(extra points if you figure out how to automatically update the updated_at column)"
create or replace function public.set_updated_at()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  new.updated_at = pg_catalog.now();
  return new;
end;
$$;