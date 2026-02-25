create type "public"."order_status" as enum ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled');


  create table "public"."archived_order_totals" (
    "id" uuid not null default gen_random_uuid(),
    "order_id" uuid not null,
    "user_id" uuid not null,
    "order_total" integer not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."archived_order_totals" enable row level security;


  create table "public"."item_history" (
    "id" uuid not null default gen_random_uuid(),
    "item_id" uuid not null,
    "operation" character varying not null,
    "old_data" jsonb,
    "new_data" jsonb,
    "changed_by" uuid,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."item_history" enable row level security;


  create table "public"."items" (
    "id" uuid not null default gen_random_uuid(),
    "name" character varying not null,
    "price" integer not null,
    "stock" integer not null default 0,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."items" enable row level security;


  create table "public"."order_items" (
    "id" uuid not null default gen_random_uuid(),
    "order_id" uuid not null,
    "item_id" uuid not null,
    "quantity" integer not null,
    "unit_price" integer not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."order_items" enable row level security;


  create table "public"."orders" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "recipient_name" character varying not null,
    "shipping_address" text not null,
    "status" public.order_status not null default 'pending'::public.order_status,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."orders" enable row level security;


  create table "public"."profiles" (
    "id" uuid not null,
    "first_name" character varying not null,
    "last_name" character varying not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."profiles" enable row level security;

CREATE UNIQUE INDEX archived_order_totals_pkey ON public.archived_order_totals USING btree (id);

CREATE INDEX item_history_item_id_idx ON public.item_history USING btree (item_id);

CREATE UNIQUE INDEX item_history_pkey ON public.item_history USING btree (id);

CREATE UNIQUE INDEX items_pkey ON public.items USING btree (id);

CREATE INDEX order_items_order_id_idx ON public.order_items USING btree (order_id);

CREATE UNIQUE INDEX order_items_pkey ON public.order_items USING btree (id);

CREATE INDEX orders_created_at_idx ON public.orders USING btree (created_at);

CREATE UNIQUE INDEX orders_pkey ON public.orders USING btree (id);

CREATE INDEX orders_user_id_idx ON public.orders USING btree (user_id);

CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id);

alter table "public"."archived_order_totals" add constraint "archived_order_totals_pkey" PRIMARY KEY using index "archived_order_totals_pkey";

alter table "public"."item_history" add constraint "item_history_pkey" PRIMARY KEY using index "item_history_pkey";

alter table "public"."items" add constraint "items_pkey" PRIMARY KEY using index "items_pkey";

alter table "public"."order_items" add constraint "order_items_pkey" PRIMARY KEY using index "order_items_pkey";

alter table "public"."orders" add constraint "orders_pkey" PRIMARY KEY using index "orders_pkey";

alter table "public"."profiles" add constraint "profiles_pkey" PRIMARY KEY using index "profiles_pkey";

alter table "public"."item_history" add constraint "item_history_operation_valid" CHECK (((operation)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying])::text[]))) not valid;

alter table "public"."item_history" validate constraint "item_history_operation_valid";

alter table "public"."items" add constraint "items_price_positive" CHECK ((price > 0)) not valid;

alter table "public"."items" validate constraint "items_price_positive";

alter table "public"."items" add constraint "items_stock_non_negative" CHECK ((stock >= 0)) not valid;

alter table "public"."items" validate constraint "items_stock_non_negative";

alter table "public"."order_items" add constraint "order_items_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.items(id) not valid;

alter table "public"."order_items" validate constraint "order_items_item_id_fkey";

alter table "public"."order_items" add constraint "order_items_order_id_fkey" FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE not valid;

alter table "public"."order_items" validate constraint "order_items_order_id_fkey";

alter table "public"."order_items" add constraint "order_items_quantity_positive" CHECK ((quantity > 0)) not valid;

alter table "public"."order_items" validate constraint "order_items_quantity_positive";

alter table "public"."order_items" add constraint "order_items_unit_price_positive" CHECK ((unit_price > 0)) not valid;

alter table "public"."order_items" validate constraint "order_items_unit_price_positive";

alter table "public"."orders" add constraint "orders_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) not valid;

alter table "public"."orders" validate constraint "orders_user_id_fkey";

alter table "public"."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."profiles" validate constraint "profiles_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  insert into public.profiles (id, first_name, last_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'first_name', ''),
    coalesce(new.raw_user_meta_data ->> 'last_name', '')
  );
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  new.updated_at = pg_catalog.now();
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.track_item_changes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
$function$
;

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

grant delete on table "public"."item_history" to "anon";

grant insert on table "public"."item_history" to "anon";

grant references on table "public"."item_history" to "anon";

grant select on table "public"."item_history" to "anon";

grant trigger on table "public"."item_history" to "anon";

grant truncate on table "public"."item_history" to "anon";

grant update on table "public"."item_history" to "anon";

grant delete on table "public"."item_history" to "authenticated";

grant insert on table "public"."item_history" to "authenticated";

grant references on table "public"."item_history" to "authenticated";

grant select on table "public"."item_history" to "authenticated";

grant trigger on table "public"."item_history" to "authenticated";

grant truncate on table "public"."item_history" to "authenticated";

grant update on table "public"."item_history" to "authenticated";

grant delete on table "public"."item_history" to "service_role";

grant insert on table "public"."item_history" to "service_role";

grant references on table "public"."item_history" to "service_role";

grant select on table "public"."item_history" to "service_role";

grant trigger on table "public"."item_history" to "service_role";

grant truncate on table "public"."item_history" to "service_role";

grant update on table "public"."item_history" to "service_role";

grant delete on table "public"."items" to "anon";

grant insert on table "public"."items" to "anon";

grant references on table "public"."items" to "anon";

grant select on table "public"."items" to "anon";

grant trigger on table "public"."items" to "anon";

grant truncate on table "public"."items" to "anon";

grant update on table "public"."items" to "anon";

grant delete on table "public"."items" to "authenticated";

grant insert on table "public"."items" to "authenticated";

grant references on table "public"."items" to "authenticated";

grant select on table "public"."items" to "authenticated";

grant trigger on table "public"."items" to "authenticated";

grant truncate on table "public"."items" to "authenticated";

grant update on table "public"."items" to "authenticated";

grant delete on table "public"."items" to "service_role";

grant insert on table "public"."items" to "service_role";

grant references on table "public"."items" to "service_role";

grant select on table "public"."items" to "service_role";

grant trigger on table "public"."items" to "service_role";

grant truncate on table "public"."items" to "service_role";

grant update on table "public"."items" to "service_role";

grant delete on table "public"."order_items" to "anon";

grant insert on table "public"."order_items" to "anon";

grant references on table "public"."order_items" to "anon";

grant select on table "public"."order_items" to "anon";

grant trigger on table "public"."order_items" to "anon";

grant truncate on table "public"."order_items" to "anon";

grant update on table "public"."order_items" to "anon";

grant delete on table "public"."order_items" to "authenticated";

grant insert on table "public"."order_items" to "authenticated";

grant references on table "public"."order_items" to "authenticated";

grant select on table "public"."order_items" to "authenticated";

grant trigger on table "public"."order_items" to "authenticated";

grant truncate on table "public"."order_items" to "authenticated";

grant update on table "public"."order_items" to "authenticated";

grant delete on table "public"."order_items" to "service_role";

grant insert on table "public"."order_items" to "service_role";

grant references on table "public"."order_items" to "service_role";

grant select on table "public"."order_items" to "service_role";

grant trigger on table "public"."order_items" to "service_role";

grant truncate on table "public"."order_items" to "service_role";

grant update on table "public"."order_items" to "service_role";

grant delete on table "public"."orders" to "anon";

grant insert on table "public"."orders" to "anon";

grant references on table "public"."orders" to "anon";

grant select on table "public"."orders" to "anon";

grant trigger on table "public"."orders" to "anon";

grant truncate on table "public"."orders" to "anon";

grant update on table "public"."orders" to "anon";

grant delete on table "public"."orders" to "authenticated";

grant insert on table "public"."orders" to "authenticated";

grant references on table "public"."orders" to "authenticated";

grant select on table "public"."orders" to "authenticated";

grant trigger on table "public"."orders" to "authenticated";

grant truncate on table "public"."orders" to "authenticated";

grant update on table "public"."orders" to "authenticated";

grant delete on table "public"."orders" to "service_role";

grant insert on table "public"."orders" to "service_role";

grant references on table "public"."orders" to "service_role";

grant select on table "public"."orders" to "service_role";

grant trigger on table "public"."orders" to "service_role";

grant truncate on table "public"."orders" to "service_role";

grant update on table "public"."orders" to "service_role";

grant delete on table "public"."profiles" to "anon";

grant insert on table "public"."profiles" to "anon";

grant references on table "public"."profiles" to "anon";

grant select on table "public"."profiles" to "anon";

grant trigger on table "public"."profiles" to "anon";

grant truncate on table "public"."profiles" to "anon";

grant update on table "public"."profiles" to "anon";

grant delete on table "public"."profiles" to "authenticated";

grant insert on table "public"."profiles" to "authenticated";

grant references on table "public"."profiles" to "authenticated";

grant select on table "public"."profiles" to "authenticated";

grant trigger on table "public"."profiles" to "authenticated";

grant truncate on table "public"."profiles" to "authenticated";

grant update on table "public"."profiles" to "authenticated";

grant delete on table "public"."profiles" to "service_role";

grant insert on table "public"."profiles" to "service_role";

grant references on table "public"."profiles" to "service_role";

grant select on table "public"."profiles" to "service_role";

grant trigger on table "public"."profiles" to "service_role";

grant truncate on table "public"."profiles" to "service_role";

grant update on table "public"."profiles" to "service_role";


  create policy "users can read their own archived order totals"
  on "public"."archived_order_totals"
  as permissive
  for select
  to authenticated
using ((( SELECT auth.uid() AS uid) = user_id));

  create policy "authenticated users can read item history"
  on "public"."item_history"
  as permissive
  for select
  to authenticated
using (true);



  create policy "anyone can read items"
  on "public"."items"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "order items can only be inserted into pending orders"
  on "public"."order_items"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = order_items.order_id) AND (orders.user_id = ( SELECT auth.uid() AS uid)) AND (orders.status = 'pending'::public.order_status)))));



  create policy "users can read their own order items"
  on "public"."order_items"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.orders
  WHERE ((orders.id = order_items.order_id) AND (orders.user_id = ( SELECT auth.uid() AS uid))))));



  create policy "users can insert their own orders"
  on "public"."orders"
  as permissive
  for insert
  to authenticated
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "users can only update pending or confirmed orders"
  on "public"."orders"
  as permissive
  for update
  to authenticated
using (((( SELECT auth.uid() AS uid) = user_id) AND (status = ANY (ARRAY['pending'::public.order_status, 'confirmed'::public.order_status]))))
with check ((( SELECT auth.uid() AS uid) = user_id));



  create policy "users can read their own orders"
  on "public"."orders"
  as permissive
  for select
  to authenticated
using ((( SELECT auth.uid() AS uid) = user_id));



  create policy "users can read their own profile"
  on "public"."profiles"
  as permissive
  for select
  to authenticated
using ((( SELECT auth.uid() AS uid) = id));



  create policy "users can update their own profile"
  on "public"."profiles"
  as permissive
  for update
  to authenticated
using ((( SELECT auth.uid() AS uid) = id))
with check ((( SELECT auth.uid() AS uid) = id));


CREATE TRIGGER on_item_changed AFTER INSERT OR DELETE OR UPDATE ON public.items FOR EACH ROW EXECUTE FUNCTION public.track_item_changes();

CREATE TRIGGER set_items_updated_at BEFORE UPDATE ON public.items FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_order_items_updated_at BEFORE UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_item_history_updated_at BEFORE UPDATE ON public.item_history FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_archived_order_totals_updated_at BEFORE UPDATE ON public.archived_order_totals FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();