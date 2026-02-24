alter table public.profiles enable row level security;

create policy "authenticated users can do anything with profiles"
  on public.profiles
  for all
  to authenticated
  using (true)
  with check (true);

alter table public.items enable row level security;

create policy "authenticated users can do anything with items"
  on public.items
  for all
  to authenticated
  using (true)
  with check (true);

alter table public.orders enable row level security;

create policy "users can do anything with their own orders"
  on public.orders
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

alter table public.order_items enable row level security;

create policy "authenticated users can do anything with order_items"
  on public.order_items
  for all
  to authenticated
  using (true)
  with check (true);

alter table public.item_history enable row level security;

create policy "authenticated users can do anything with item_history"
  on public.item_history
  for all
  to authenticated
  using (true)
  with check (true);

alter table public.archived_order_totals enable row level security;

create policy "authenticated users can do anything with archived_order_totals"
  on public.archived_order_totals
  for all
  to authenticated
  using (true)
  with check (true);