alter table public.profiles enable row level security;

create policy "users can read their own profile"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "users can update their own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

alter table public.items enable row level security;

create policy "anyone can read items"
  on public.items for select
  to anon, authenticated
  using (true);

alter table public.orders enable row level security;

create policy "users can read their own orders"
  on public.orders for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "users can insert their own orders"
  on public.orders for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

-- prevents updating orders that are already shipped, delivered or cancelled
create policy "users can only update pending or confirmed orders"
  on public.orders for update
  to authenticated
  using (
    (select auth.uid()) = user_id
    and status in ('pending', 'confirmed')
  )
  with check ((select auth.uid()) = user_id);

alter table public.order_items enable row level security;

create policy "users can read their own order items"
  on public.order_items for select
  to authenticated
  using (
    exists (
      select 1 from public.orders
      where orders.id = order_items.order_id
      and orders.user_id = (select auth.uid())
    )
  );

create policy "order items can only be inserted into pending orders"
  on public.order_items for insert
  to authenticated
  with check (
    exists (
      select 1 from public.orders
      where orders.id = order_items.order_id
      and orders.user_id = (select auth.uid())
      and orders.status = 'pending'
    )
  );

alter table public.item_history enable row level security;

create policy "authenticated users can read item history"
  on public.item_history for select
  to authenticated
  using (true);

alter table public.archived_order_totals enable row level security;

create policy "users can read their own archived order totals"
  on public.archived_order_totals for select
  to authenticated
  using ((select auth.uid()) = user_id);
