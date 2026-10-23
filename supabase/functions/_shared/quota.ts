// Daily AI quotas (see the pro_plan migration). The AI functions take one
// before calling Groq and give it back if the call fails on our side.

import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

export type QuotaType = "scan" | "chat" | "voice";

export interface QuotaResult {
  allowed: boolean;
  // null: no limit (Pro scans).
  remaining: number | null;
  pro: boolean;
}

/** Takes one [type] from the signed-in user's quota (atomic, in the database). */
export async function consumeQuota(userClient: SupabaseClient, type: QuotaType): Promise<QuotaResult> {
  const { data, error } = await userClient.rpc("consume_quota", { p_type: type });
  if (error) throw new Error(`consume_quota failed: ${error.message}`);
  return data as QuotaResult;
}

/** Gives one [type] back to [userId]. Best effort: never throws. */
export async function refundQuota(userId: string, type: QuotaType): Promise<void> {
  try {
    const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const { error } = await admin.rpc("refund_quota", { p_type: type, p_user_id: userId });
    if (error) console.error(`refund_quota(${type}) failed:`, error.message);
  } catch (e) {
    console.error(`refund_quota(${type}) failed:`, e);
  }
}

/**
 * 402 for a used-up quota. `code` is what the app matches; `remaining` and
 * `pro` let it pick the right message (a Pro user hit the fair-use cap).
 */
export function limitReachedResponse(type: QuotaType, quota: QuotaResult): Response {
  return new Response(
    JSON.stringify({ error: "LIMIT_REACHED", code: "LIMIT_REACHED", type, remaining: 0, pro: quota.pro }),
    { status: 402, headers: { "Content-Type": "application/json" } },
  );
}
