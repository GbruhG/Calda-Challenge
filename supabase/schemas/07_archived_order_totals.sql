create table public.archived_order_totals (
  id           uuid        not null default gen_random_uuid(),
  order_id     uuid        not null,
  user_id      uuid        not null,
  order_total  integer     not null,
  archived_at  timestamptz not null default now(),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  primary key (id)
);