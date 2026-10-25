// Supabase Edge Function « reset-password » (réservée à la gérante).
// Déploiement : Supabase > Edge Functions > Create a new function > nom : reset-password > coller ce code > Deploy.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };
const out = (o: unknown) => new Response(JSON.stringify(o), { headers: { ...cors, "Content-Type": "application/json" } });
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const caller = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: req.headers.get("Authorization") || "" } } });
    const { data: { user } } = await caller.auth.getUser();
    if (!user) return out({ error: "Non connectée" });
    const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const { data: p } = await admin.from("profiles").select("role").eq("id", user.id).single();
    if (p?.role !== "admin") return out({ error: "Réservé à la gérante" });
    const { user_id } = await req.json();
    const password = String(crypto.getRandomValues(new Uint32Array(1))[0] % 900000 + 100000);
    const { error } = await admin.auth.admin.updateUserById(user_id, { password });
    if (error) return out({ error: error.message });
    return out({ password });
  } catch (e) { return out({ error: String(e) }); }
});
