-- unit_price snapshots the item price at order time so historical
-- orders are not affected if the item price changes later
create table public.order_items (
  id          uuid        not null default gen_random_uuid(),
  order_id    uuid        not null references public.orders(id) on delete cascade,
  item_id     uuid        not null references public.items(id),
  quantity    integer     not null,
  unit_price  integer     not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  primary key (id),
  constraint order_items_quantity_positive check (quantity > 0),
  constraint order_items_unit_price_positive check (unit_price > 0)
);

create index order_items_order_id_idx on public.order_items(order_id);

create trigger set_order_items_updated_at
  before update on public.order_items
  for each row execute function public.set_updated_at();