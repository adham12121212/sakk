import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface ChatMessageIn {
  role: string;
  content: string;
}

interface ChatRequest {
  message: string;
  history: ChatMessageIn[];
}

// Longest message (in characters) the function accepts or forwards, so one
// request can't burn through the Groq quota.
const MAX_MESSAGE_LENGTH = 2000;

const SYSTEM_PROMPT = `You are the AI assistant built into Sakk, an app that helps people
in Egypt keep track of their purchases, receipts and warranties.

Help with: using the app, warranty coverage and rights, what to do when a product
breaks, and general advice on buying and keeping receipts. Politely decline topics
that have nothing to do with purchases, products or warranties.

How Sakk works (only describe features listed here; if asked about anything else,
say the app doesn't have it rather than inventing it):
- Bottom tabs: Home, Products, Scan (middle button), Analytics, AI (this chat).
- Adding a product: tap Scan, then Take Photo or Choose from Gallery to capture
  the receipt or warranty card. AI reads the product name, brand, store, price,
  purchase date and warranty length. On the Verify Details screen the user checks
  and corrects every field (product name and warranty length are required), picks
  a category, then taps Save Product. There is no way to add a product without
  scanning; if the scan fails they can try another photo and fix the fields by hand.
- Categories: Electronics, Appliances, Furniture, Vehicles, Accessories, Other.
- Prices are in Egyptian pounds (EGP).
- Warranty status: Active, Expiring (3 months or less left) or Expired.
- Products tab: search by name, filter by status or category.
- Product details: warranty ring with days left and expiry date, Details and
  Invoice tabs, and Edit, Delete, Share and Download Invoice (saves the receipt
  photo) actions.
- Home: greeting, totals for products, active warranties and expiring soon, and
  recent products. The search icon finds products; the bell opens Notifications.
- Notifications: the app reminds the user when a warranty is about to expire.
- Analytics: total spent, warranty status overview and spending per category.
- Profile (tap the avatar on Home): photo, language (Arabic or English), theme
  (Light, Dark, Auto), Face ID / fingerprint login, Log Out and Delete account.

You cannot see the user's products. For a specific product's dates or details,
tell them to open it from the Products tab instead of guessing.

Reply in the language the user writes in (Arabic or English). Keep answers short,
friendly and practical. The app shows replies as plain text, so never use
Markdown: no **bold**, # headings or tables. Use numbered lines or "-" for lists.`;

serve(async (req) => {
  try {
    // Only signed-in users may chat. The anon key ships inside the app, so a
    // valid JWT alone isn't enough; it has to belong to a real user.
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return jsonResponse({ error: "Not authenticated" }, 401);
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return jsonResponse({ error: "Not authenticated" }, 401);

    const { message, history }: ChatRequest = await req.json();

    if (!message || typeof message !== "string") {
      return jsonResponse({ error: "message is required" }, 400);
    }
    if (message.length > MAX_MESSAGE_LENGTH) {
      return jsonResponse({ error: "message is too long" }, 400);
    }

    const reply = await runChat(message, Array.isArray(history) ? history : []);
    return jsonResponse({ reply }, 200);
  } catch (error) {
    console.error("ai-chat error:", error);
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});

async function runChat(message: string, history: ChatMessageIn[]): Promise<string> {
  const apiKey = Deno.env.get("GROQ_API_KEY");
  if (!apiKey) {
    throw new Error("GROQ_API_KEY secret is not configured");
  }

  const recentHistory = history.slice(-10).map((m) => ({
    role: m.role === "assistant" ? "assistant" : "user",
    content: String(m.content ?? "").slice(0, MAX_MESSAGE_LENGTH),
  }));

  const messages = [
    { role: "system", content: SYSTEM_PROMPT },
    ...recentHistory,
    { role: "user", content: message },
  ];

  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      // Groq production model (free tier). Check GET /openai/v1/models before
      // changing it: Groq retires models without notice.
      model: "openai/gpt-oss-120b",
      // Reasoning model: keep thinking short so chat stays fast. Reasoning tokens
      // count toward max_tokens, hence the headroom.
      reasoning_effort: "low",
      messages,
      temperature: 0.7,
      max_tokens: 2000,
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`AI request failed (${response.status}): ${errText}`);
  }

  const completion = await response.json();
  const raw: string = completion.choices?.[0]?.message?.content ?? "";
  // The model sometimes uses Markdown despite the prompt; the app renders plain text.
  const reply = raw
    .replace(/\*\*(.+?)\*\*/g, "$1")
    .replace(/^#{1,6}\s+/gm, "")
    .replace(/[ \t]+$/gm, "")
    .trim();
  if (!reply) throw new Error("AI returned no content");

  return reply;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}