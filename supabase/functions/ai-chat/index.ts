import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface ChatMessageIn {
  role: string;
  content: string;
}

interface ChatRequest {
  message: string;
  history: ChatMessageIn[];
}

const SYSTEM_PROMPT = `You are the AI assistant built into Sakk, an app that helps people track
their purchases, warranties, and receipts.
Help users with questions about their own products, warranty coverage, purchase dates,
what to do if something breaks, and general shopping/warranty advice.
You do not have direct access to the user's product database in this conversation —
if they ask about a SPECIFIC product's exact warranty date, tell them to check the
product's detail page in the app rather than guessing a date.
Respond in the same language the user writes in (Arabic or English).
Keep answers concise, friendly, and practical.`;

serve(async (req) => {
  try {
    const { message, history }: ChatRequest = await req.json();

    if (!message || typeof message !== "string") {
      return jsonResponse({ error: "message is required" }, 400);
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
  const apiKey = Deno.env.get("AI_API_KEY");
  if (!apiKey) {
    throw new Error("AI_API_KEY secret is not configured");
  }


  const recentHistory = history.slice(-10).map((m) => ({
    role: m.role === "assistant" ? "assistant" : "user",
    content: String(m.content ?? ""),
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
      model: "qwen/qwen3.6-27b",
      reasoning_effort: "none",
      messages,
      temperature: 0.7,
      max_tokens: 800,
    }),
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`AI request failed (${response.status}): ${errText}`);
  }

  const completion = await response.json();
  const reply = completion.choices?.[0]?.message?.content;
  if (!reply) throw new Error("AI returned no content");

  return reply as string;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}