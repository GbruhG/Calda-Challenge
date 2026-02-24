create table public.orders (
  id                uuid        not null default gen_random_uuid(),
  user_id           uuid        not null references public.profiles(id),
  recipient_name    varchar     not null,
  shipping_address  text        not null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  primary key (id)
);

create index orders_user_id_idx on public.orders(user_id);

create index orders_created_at_idx on public.orders(created_at);

create trigger set_orders_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();