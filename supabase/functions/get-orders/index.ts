import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method !== "GET") {
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

  const url = new URL(req.url);
  const order_id = url.searchParams.get("order_id");

  if (order_id) {
    const { data: order, error } = await supabase
      .from("order_summary")
      .select("*")
      .eq("id", order_id)
      .single();

    if (error || !order) {
      return Response.json({ error: "order not found" }, { status: 404 });
    }

    return Response.json({ order }, { status: 200 });
  }

  const { data: orders, error } = await supabase
    .from("order_summary")
    .select("*");

  if (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }

  return Response.json({ orders }, { status: 200 });
});