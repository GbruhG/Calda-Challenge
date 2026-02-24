create table public.item_history (
  id          uuid        not null default gen_random_uuid(),
  item_id     uuid        not null,
  operation   varchar     not null,
  old_data    jsonb,
  new_data    jsonb,
  changed_by  uuid,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),

  primary key (id),
  constraint item_history_operation_valid check (operation in ('INSERT', 'UPDATE', 'DELETE'))
);

create index item_history_item_id_idx on public.item_history(item_id);

create or replace function public.track_item_changes()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.item_history (item_id, operation, old_data, new_data, changed_by)
  values (
    coalesce(new.id, old.id),
    tg_op,
    case when tg_op = 'INSERT' then null else to_jsonb(old) end,
    case when tg_op = 'DELETE' then null else to_jsonb(new) end,
    auth.uid()
  );
  return coalesce(new, old);
end;
$$;

-- triggers on every INSERT, UPDATE and DELETE regardless of what triggered the change
create trigger on_item_changed
  after insert or update or delete on public.items
  for each row execute function public.track_item_changes();