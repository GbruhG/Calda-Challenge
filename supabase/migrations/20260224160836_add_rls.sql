alter table "public"."item_history" drop constraint "item_history_operation_valid";


  create table "public"."archived_order_totals" (
    "id" uuid not null default gen_random_uuid(),
    "order_id" uuid not null,
    "user_id" uuid not null,
    "order_total" integer not null,
    "archived_at" timestamp with time zone not null default now(),
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."archived_order_totals" enable row level security;

alter table "public"."item_history" enable row level security;

alter table "public"."items" enable row level security;

alter table "public"."order_items" enable row level security;

alter table "public"."orders" enable row level security;

alter table "public"."profiles" enable row level security;

CREATE UNIQUE INDEX archived_order_totals_pkey ON public.archived_order_totals USING btree (id);

alter table "public"."archived_order_totals" add constraint "archived_order_totals_pkey" PRIMARY KEY using index "archived_order_totals_pkey";

alter table "public"."item_history" add constraint "item_history_operation_valid" CHECK (((operation)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying])::text[]))) not valid;

alter table "public"."item_history" validate constraint "item_history_operation_valid";

grant delete on table "public"."archived_order_totals" to "anon";

grant insert on table "public"."archived_order_totals" to "anon";

grant references on table "public"."archived_order_totals" to "anon";

grant select on table "public"."archived_order_totals" to "anon";

grant trigger on table "public"."archived_order_totals" to "anon";

grant truncate on table "public"."archived_order_totals" to "anon";

grant update on table "public"."archived_order_totals" to "anon";

grant delete on table "public"."archived_order_totals" to "authenticated";

grant insert on table "public"."archived_order_totals" to "authenticated";

grant references on table "public"."archived_order_totals" to "authenticated";

grant select on table "public"."archived_order_totals" to "authenticated";

grant trigger on table "public"."archived_order_totals" to "authenticated";

grant truncate on table "public"."archived_order_totals" to "authenticated";

grant update on table "public"."archived_order_totals" to "authenticated";

grant delete on table "public"."archived_order_totals" to "service_role";

grant insert on table "public"."archived_order_totals" to "service_role";

grant references on table "public"."archived_order_totals" to "service_role";

grant select on table "public"."archived_order_totals" to "service_role";

grant trigger on table "public"."archived_order_totals" to "service_role";

grant truncate on table "public"."archived_order_totals" to "service_role";

grant update on table "public"."archived_order_totals" to "service_role";


  create policy "authenticated users can do anything with archived_order_totals"
  on "public"."archived_order_totals"
  as permissive
  for all
  to authenticated
using (true)
with check (true);



  create policy "authenticated users can do anything with item_history"
  on "public"."item_history"
  as permissive
  for all
  to authenticated
using (true)
with check (true);



  create policy "authenticated users can do anything with items"
  on "public"."items"
  as permissive
  for all
  to authenticated
using (true)
with check (true);



  create policy "authenticated users can do anything with order_items"
  on "public"."order_items"
  as permissive
  for all
  to authenticated
using (true)
with check (true);



  create policy "users can do anything with their own orders"
  on "public"."orders"
  as permissive
  for all
  to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  create policy "authenticated users can do anything with profiles"
  on "public"."profiles"
  as permissive
  for all
  to authenticated
using (true)
with check (true);



