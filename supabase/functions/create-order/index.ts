// could be made fully atomic with rpc in production
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
    return Response.json({ error: "missing authorization header" }, { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  );

  const token = authHeader.replace("Bearer ", "");
  const { data, error: claimsError } = await supabase.auth.getClaims(token);
  if (claimsError || !data?.claims) {
    return Response.json({ error: "invalid JWT" }, { status: 401 });
  }

  const userId = data.claims.sub;
  const body = await req.json();
  const { recipient_name, shipping_address, items } = body as OrderRequest;

  if (!recipient_name || !shipping_address || !items?.length) {
    return Response.json({ error: "missing required fields" }, { status: 400 });
  }

  for (const item of items) {
    if (!item.item_id || item.quantity < 1) {
      return Response.json({ error: "invalid item or quantity" }, { status: 400 });
    }
  }

  const itemIds = items.map((i) => i.item_id);
  const { data: catalogueItems } = await serviceClient
    .from("items")
    .select("id, price, stock")
    .in("id", itemIds);

  if (!catalogueItems?.length || catalogueItems.length !== itemIds.length) {
    return Response.json({ error: "one or more items not found" }, { status: 400 });
  }

  const priceMap: Record<string, number> = {};
  const stockMap: Record<string, number> = {};
  for (const item of catalogueItems) {
    priceMap[item.id] = item.price;
    stockMap[item.id] = item.stock;
  }

  // check stock before proceeding
  for (const item of items) {
    if (stockMap[item.item_id] < item.quantity) {
      return Response.json({ error: `insufficient stock for item ${item.item_id}` }, { status: 400 });
    }
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

  const { error: orderItemsError } = await supabase.from("order_items").insert(orderItems);
  if (orderItemsError) {
    // rollback order if insertion fails
    await serviceClient.from("orders").delete().eq("id", order!.id);
    return Response.json({ error: "failed to create order" }, { status: 500 });
  }

  // reduce stock for each item
  for (const item of items) {
    await serviceClient
      .from("items")
      .update({ stock: stockMap[item.item_id] - item.quantity })
      .eq("id", item.item_id);
  }

  const { data: allOrderItems } = await serviceClient
    .from("order_items")
    .select("quantity, unit_price")
    .neq("order_id", order!.id);

  let other_orders_total = 0;
  for (const item of allOrderItems ?? []) {
    other_orders_total += item.quantity * item.unit_price;
  }

  return Response.json({ order, other_orders_total }, { status: 201 });
});