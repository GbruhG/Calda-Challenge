create extension pg_cron with schema extensions;
grant usage on schema cron to postgres;
grant all privileges on all tables in schema cron to postgres;

create or replace function public.archive_and_delete_old_orders()
returns void
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.archived_order_totals (order_id, user_id, order_total)
  select
    o.id,
    o.user_id,
    sum(oi.quantity * oi.unit_price)
  from public.orders o
  join public.order_items oi on oi.order_id = o.id
  where o.created_at < now() - interval '1 week'
  group by o.id, o.user_id;
  delete from public.orders
  where created_at < now() - interval '1 week';
end;
$$;
-- run every day at midnight
select cron.schedule(
  'archive-and-delete-old-orders',
  '0 0 * * *',
  $$ select public.archive_and_delete_old_orders(); $$
);