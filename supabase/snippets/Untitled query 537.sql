update public.orders set created_at = now() - interval '8 days' where id = '20000000-0000-0000-0000-000000000001';
select public.archive_and_delete_old_orders();