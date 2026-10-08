// supabase/functions/delete-account/index.ts
//
// Permanently deletes the CALLING user's account and data.
// The user is identified from their own JWT, so nobody can delete someone else.
//
// Deploy:  supabase functions deploy delete-account
// (SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are injected automatically.)

import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

// ⚠️ Check these match your project (Dashboard → Storage / Table Editor).
// Every file is expected under "<user_id>/..." (that's how avatars are stored today).
const BUCKETS = ["avatars", "receipts"];
// Tables with a `user_id` column. Children first, parents last.
const TABLES = ["notifications", "products"];

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

async function listAllFiles(admin: SupabaseClient, bucket: string, prefix: string): Promise<string[]> {
  const out: string[] = [];
  let offset = 0;
  while (true) {
    const { data, error } = await admin.storage.from(bucket).list(prefix, { limit: 1000, offset });
    if (error) throw new Error(`list ${bucket}/${prefix}: ${error.message}`);
    if (!data || data.length === 0) break;
    for (const item of data) {
      const path = `${prefix}/${item.name}`;
      // folders come back with id === null → recurse
      if (item.id === null) out.push(...(await listAllFiles(admin, bucket, path)));
      else out.push(path);
    }
    if (data.length < 1000) break;
    offset += 1000;
  }
  return out;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Missing Authorization header" }, 401);

  const url = Deno.env.get("SUPABASE_URL")!;
  const userClient = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userErr } = await userClient.auth.getUser();
  if (userErr || !user) return json({ error: "Not authenticated" }, 401);

  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });

  try {
    // 1) Storage files
    for (const bucket of BUCKETS) {
      const files = await listAllFiles(admin, bucket, user.id);
      for (let i = 0; i < files.length; i += 100) {
        const { error } = await admin.storage.from(bucket).remove(files.slice(i, i + 100));
        if (error) throw new Error(`remove from ${bucket}: ${error.message}`);
      }
    }

    // 2) Table rows
    for (const table of TABLES) {
      const { error } = await admin.from(table).delete().eq("user_id", user.id);
      if (error) throw new Error(`delete from ${table}: ${error.message}`);
    }

    // 3) The auth user itself (signs them out everywhere)
    const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
    if (delErr) throw new Error(`delete auth user: ${delErr.message}`);

    return json({ success: true });
  } catch (e) {
    console.error("delete-account failed", user.id, e);
    return json({ error: "Could not delete account. Please try again." }, 500);
  }
});
