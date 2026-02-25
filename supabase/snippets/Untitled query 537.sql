-- supabase docs say - "To mitigate the risk, always set with (security_invoker=on) when a view should respect RLS policies."
-- cant create the view with a schema, because cli diffing engine treats "security_invoker" as a "default" or "ignorable" parameter and removes it
create view public.order_summary with (security_invoker=on) as
select
  o.id,
  o.user_id,
  o.recipient_name,
  o.shipping_address,
  o.status,
  o.created_at,
  o.updated_at,
  sum(oi.quantity * oi.unit_price) as order_total,
  jsonb_agg(
    jsonb_build_object(
      'item_id',    oi.item_id,
      'name',       i.name,
      'quantity',   oi.quantity,
      'unit_price', oi.unit_price
    )
  ) as items
from public.orders o
join public.order_items oi on oi.order_id = o.id
join public.items i on i.id = oi.item_id
group by o.id;
