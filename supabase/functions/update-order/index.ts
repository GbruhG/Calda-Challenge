import { createClient } from "jsr:@supabase/supabase-js@2";

const VALID_TRANSITIONS: Record<string, string[]> = {
  pending: ["confirmed", "cancelled"],
  confirmed: ["shipped", "cancelled"],
  shipped: ["delivered"],
  delivered: [],
  cancelled: [],
};

Deno.serve(async (req) => {
  if (req.method !== "PATCH") {
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

  const { order_id, status } = await req.json();
  if (!order_id || !status) {
    return Response.json({ error: "missing order_id or status" }, { status: 400 });
  }

  const { data: current, error: fetchError } = await supabase
    .from("orders")
    .select("status")
    .eq("id", order_id)
    .single();

  if (fetchError || !current) {
    return Response.json({ error: "order not found" }, { status: 404 });
  }

  const allowed = VALID_TRANSITIONS[current.status];
  if (!allowed?.includes(status)) {
    return Response.json(
      { error: `cannot transition from ${current.status} to ${status}` },
      { status: 400 }
    );
  }

  const { data: order, error: updateError } = await supabase
    .from("orders")
    .update({ status })
    .eq("id", order_id)
    .select()
    .single();

  if (updateError || !order) {
    return Response.json({ error: "failed to update order" }, { status: 500 });
  }

  return Response.json({ order }, { status: 200 });
});