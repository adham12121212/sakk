// supabase/functions/revenuecat-webhook/index.ts
//
// Keeps pro_subscriptions in step with RevenueCat, which is what the
// database checks for Pro (is_pro). RevenueCat calls this on every
// subscription event; the app logs in to RevenueCat with the Supabase user
// id, so app_user_id is the user's id.
//
// Deploy without JWT verification (RevenueCat doesn't send a Supabase JWT;
// the shared secret below authenticates it instead):
//   supabase functions deploy revenuecat-webhook --no-verify-jwt
// Secrets:
//   REVENUECAT_WEBHOOK_SECRET  the Authorization header value set in RevenueCat
//   REVENUECAT_API_KEY         optional, a secret (sk_...) REST API key. When set,
//                              each event re-reads the subscriber from RevenueCat
//                              instead of trusting the event alone, which also
//                              covers TRANSFER and events arriving out of order.
//
// Idempotent: an event id already applied is skipped, an event older than
// the last one applied to the user is ignored, and the same event always
// produces the same row.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { applyEvent, RevenueCatEvent, timingSafeEqual } from "./handler.ts";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const secret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  if (!secret) {
    console.error("REVENUECAT_WEBHOOK_SECRET is not set");
    return json({ error: "Not configured" }, 500);
  }
  if (!timingSafeEqual(req.headers.get("Authorization") ?? "", secret) &&
      !timingSafeEqual(req.headers.get("Authorization") ?? "", `Bearer ${secret}`)) {
    return json({ error: "Unauthorized" }, 401);
  }

  let event: RevenueCatEvent;
  try {
    event = (await req.json()).event;
    if (!event?.id || !event?.type) throw new Error("missing event");
  } catch {
    return json({ error: "Invalid body" }, 400);
  }

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  try {
    const { data: seen } = await admin.from("revenuecat_events").select("id").eq("id", event.id).maybeSingle();
    if (seen) return json({ ok: true, duplicate: true });

    if (event.type !== "TEST") {
      await applyEvent(admin, event);
    }

    // Recorded last: if applying failed, RevenueCat retries and it runs again.
    await admin.from("revenuecat_events").upsert(
      { id: event.id, type: event.type, app_user_id: event.app_user_id ?? null },
      { onConflict: "id", ignoreDuplicates: true },
    );
    return json({ ok: true });
  } catch (error) {
    console.error("revenuecat-webhook error:", error, "event:", event.id, event.type);
    // Non-2xx: RevenueCat retries later.
    return json({ error: error instanceof Error ? error.message : String(error) }, 500);
  }
});
