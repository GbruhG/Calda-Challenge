-- price is stored in cents to avoid floating point issues (1999 = €19.99)
create table public.items (
  id          uuid        not null default gen_random_uuid(),
  name        varchar     not null,
  price       integer     not null,
  stock       integer     not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  primary key (id),
  constraint items_price_positive check (price > 0),
  constraint items_stock_non_negative check (stock >= 0)
);

create trigger set_items_updated_at
  before update on public.items
  for each row execute function public.set_updated_at();