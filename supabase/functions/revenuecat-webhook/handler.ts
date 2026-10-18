// The revenuecat-webhook logic, apart from the HTTP server so it can be tested.

import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

const ENTITLEMENT = "pro";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export interface RevenueCatEvent {
  id: string;
  type: string;
  app_user_id?: string;
  original_app_user_id?: string;
  aliases?: string[];
  product_id?: string;
  new_product_id?: string;
  entitlement_ids?: string[] | null;
  period_type?: string;
  expiration_at_ms?: number | null;
  grace_period_expiration_at_ms?: number | null;
  event_timestamp_ms?: number;
  store?: string;
  transferred_from?: string[];
  transferred_to?: string[];
}

interface ProRow {
  user_id: string;
  entitlement: string;
  active_until: string | null;
  product_id: string | null;
  is_trial: boolean;
  will_renew: boolean;
  billing_issue_at: string | null;
  store: string | null;
  last_event_at: string | null;
}


export async function applyEvent(admin: SupabaseClient, event: RevenueCatEvent) {
  // Events for other entitlements (none today) don't touch Pro.
  if (event.entitlement_ids && !event.entitlement_ids.includes(ENTITLEMENT) && event.type !== "TRANSFER") {
    return;
  }

  const apiKey = Deno.env.get("REVENUECAT_API_KEY");
  const affected = event.type === "TRANSFER"
    ? [...(event.transferred_from ?? []), ...(event.transferred_to ?? [])].filter(isUserId)
    : [userIdOf(event)].filter((id): id is string => id !== null);
  if (affected.length === 0) {
    console.warn("revenuecat-webhook: no Supabase user id in event", event.id, event.app_user_id);
    return;
  }

  for (const userId of affected) {
    if (apiKey) {
      await syncFromRevenueCat(admin, userId, apiKey);
    } else if (event.type === "TRANSFER") {
      // Without the REST API the new owner's dates aren't in the event; the
      // old owner loses Pro, the new one gets it on their next event.
      if ((event.transferred_from ?? []).includes(userId)) {
        await upsert(admin, userId, { active_until: new Date().toISOString(), will_renew: false });
      }
    } else {
      await applyEventPayload(admin, userId, event);
    }
  }
}

/** The user the event is about: the first Supabase user id among its ids. */
function userIdOf(event: RevenueCatEvent): string | null {
  return [event.app_user_id, event.original_app_user_id, ...(event.aliases ?? [])].find(isUserId) ?? null;
}

// Anonymous RevenueCat ids ($RCAnonymousID:...) aren't users.
function isUserId(id: string | undefined): id is string {
  return typeof id === "string" && UUID.test(id);
}

const iso = (ms: number | null | undefined) => (ms ? new Date(ms).toISOString() : null);

async function applyEventPayload(admin: SupabaseClient, userId: string, event: RevenueCatEvent) {
  const eventAt = event.event_timestamp_ms ?? Date.now();
  const { data: existing } = await admin.from("pro_subscriptions").select("*").eq("user_id", userId).maybeSingle();
  const row = existing as ProRow | null;
  // An older event arriving late must not undo a newer one.
  if (row?.last_event_at && Date.parse(row.last_event_at) > eventAt) return;

  // During a billing issue Google keeps the subscription in its grace
  // period; RevenueCat reports that as the grace expiration.
  const until = iso(event.grace_period_expiration_at_ms ?? event.expiration_at_ms);
  const base = { last_event_at: new Date(eventAt).toISOString(), store: event.store ?? row?.store ?? null };

  switch (event.type) {
    case "INITIAL_PURCHASE":
    case "RENEWAL":
    case "UNCANCELLATION":
    case "SUBSCRIPTION_EXTENDED":
    case "TEMPORARY_ENTITLEMENT_GRANT":
      await upsert(admin, userId, {
        ...base,
        active_until: until,
        product_id: event.product_id ?? row?.product_id ?? null,
        is_trial: event.period_type === "TRIAL",
        will_renew: true,
        billing_issue_at: null,
      });
      return;
    case "PRODUCT_CHANGE":
      // Monthly ⇄ yearly. Google applies it at the next renewal, which
      // sends its own RENEWAL with the dates; keep the current period.
      await upsert(admin, userId, {
        ...base,
        product_id: event.new_product_id ?? event.product_id ?? row?.product_id ?? null,
      });
      return;
    case "CANCELLATION":
      // Auto-renew turned off (or refunded): Pro runs until the expiration
      // RevenueCat gives, which is "now" for a refund.
      await upsert(admin, userId, { ...base, active_until: until ?? row?.active_until ?? null, will_renew: false });
      return;
    case "EXPIRATION":
      await upsert(admin, userId, {
        ...base,
        active_until: iso(event.expiration_at_ms) ?? new Date(eventAt).toISOString(),
        will_renew: false,
        is_trial: false,
        billing_issue_at: null,
      });
      return;
    case "BILLING_ISSUE":
      await upsert(admin, userId, {
        ...base,
        active_until: until ?? row?.active_until ?? null,
        billing_issue_at: new Date(eventAt).toISOString(),
      });
      return;
    default:
      // SUBSCRIPTION_PAUSED, NON_RENEWING_PURCHASE, ...: nothing to change.
      console.log("revenuecat-webhook: ignored event type", event.type);
  }
}

/** Reads the subscriber's current state from RevenueCat (REST API v1) and stores it. */
async function syncFromRevenueCat(admin: SupabaseClient, userId: string, apiKey: string) {
  const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`, {
    headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
  });
  if (!response.ok) throw new Error(`RevenueCat API ${response.status}: ${await response.text()}`);
  const { subscriber } = await response.json();

  const entitlement = subscriber?.entitlements?.[ENTITLEMENT];
  const productId: string | null = entitlement?.product_identifier ?? null;
  // Google base plans come back as "product:base_plan"; the subscription
  // entry is keyed by either form.
  const sub = productId
    ? subscriber?.subscriptions?.[productId] ?? subscriber?.subscriptions?.[productId.split(":")[0]]
    : null;

  await upsert(admin, userId, {
    active_until: entitlement?.grace_period_expires_date ?? entitlement?.expires_date ?? null,
    product_id: productId,
    is_trial: sub?.period_type === "trial",
    will_renew: sub ? sub.unsubscribe_detected_at == null : false,
    billing_issue_at: sub?.billing_issues_detected_at ?? null,
    store: sub?.store ?? null,
    last_event_at: new Date().toISOString(),
  });
}

async function upsert(admin: SupabaseClient, userId: string, fields: Partial<ProRow>) {
  const { error } = await admin
    .from("pro_subscriptions")
    .upsert({ user_id: userId, entitlement: ENTITLEMENT, ...fields }, { onConflict: "user_id" });
  if (error) throw new Error(`Saving pro_subscriptions failed: ${error.message}`);
}

export function timingSafeEqual(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}
