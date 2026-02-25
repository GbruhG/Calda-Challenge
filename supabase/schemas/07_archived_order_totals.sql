create table public.archived_order_totals (
  id           uuid        not null default gen_random_uuid(),
  order_id     uuid        not null,
  user_id      uuid        not null,
  order_total  integer     not null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  primary key (id)
);

create trigger set_archived_order_totals_updated_at
  before update on public.archived_order_totals
  for each row execute function public.set_updated_at();