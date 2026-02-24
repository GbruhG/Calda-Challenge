import { createClient } from "jsr:@supabase/supabase-js@2";

type OrderItem = { item_id: string; quantity: number };
type OrderRequest = { recipient_name: string; shipping_address: string; items: OrderItem[] };

const serviceClient = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return Response.json({ error: "method not allowed" }, { status: 405 });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return Response.json({ msg: "Missing authorization header" }, { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const token = authHeader.replace("Bearer ", "");
  const { data, error: claimsError } = await supabase.auth.getClaims(token);
  if (claimsError || !data?.claims) {
    return Response.json({ msg: "Invalid JWT" }, { status: 401 });
  }

  const userId = data.claims.sub;
  const { recipient_name, shipping_address, items }: OrderRequest = await req.json();

  const itemIds = items.map((i) => i.item_id);
  const { data: catalogueItems } = await supabase.from("items").select("id, price").in("id", itemIds);

  if (!catalogueItems?.length) {
    return Response.json({ error: "one or more items not found" }, { status: 400 });
  }

  const priceMap: Record<string, number> = {};
  for (const item of catalogueItems!) {
    priceMap[item.id] = item.price;
  }

  const { data: order } = await supabase
    .from("orders")
    .insert({ user_id: userId, recipient_name, shipping_address })
    .select()
    .single();

  const orderItems = items.map((item) => ({
    order_id: order!.id,
    item_id: item.item_id,
    quantity: item.quantity,
    unit_price: priceMap[item.item_id],
  }));

  await supabase.from("order_items").insert(orderItems);

  const { data: allOrderItems } = await serviceClient
    .from("order_items")
    .select("order_id, quantity, unit_price")
    .neq("order_id", order!.id);

  let other_orders_total = 0;
  for (const item of allOrderItems ?? []) {
    other_orders_total += item.quantity * item.unit_price;
  }

  return Response.json({ order, other_orders_total }, { status: 201 });
});