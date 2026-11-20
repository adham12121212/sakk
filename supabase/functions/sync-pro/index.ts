// supabase/functions/sync-pro/index.ts
//
// Copies the signed-in user's Pro subscription from RevenueCat into
// pro_subscriptions. The app calls it right after a purchase or restore and
// on launch when the store says Pro but the server doesn't, so Pro unlocks
// on the server even if a webhook is late or missing.
//
// Deployed with JWT verification (the default): the user id comes from the
// caller's token, never from the request body.
// Secret: REVENUECAT_API_KEY, a secret (sk_...) RevenueCat REST API key.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { syncFromRevenueCat } from "../revenuecat-webhook/handler.ts";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const apiKey = Deno.env.get("REVENUECAT_API_KEY");
  if (!apiKey) {
    console.error("REVENUECAT_API_KEY is not set");
    return json({ error: "not_configured" }, 500);
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) return json({ error: "unauthorized" }, 401);

  try {
    const pro = await syncFromRevenueCat(admin, data.user.id, apiKey);
    return json({ pro });
  } catch (e) {
    console.error("sync-pro error:", e);
    return json({ error: "internal_error" }, 502);
  }
});
