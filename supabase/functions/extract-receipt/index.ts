import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface ExtractRequest {
  imageUrl: string;
}

interface ExtractResponse {
  productName: string | null;
  brand: string | null;
  store_name: string | null;
  price: number | null;
  purchaseDate: string | null;
  warrantyMonths: number | null;
  category: string | null;
  confidence: number;
}


const ALLOWED_CATEGORIES = [
  "electronics",
  "appliances",
  "furniture",
  "vehicles",
  "accessories",
  "other",
];

const SYSTEM_PROMPT = `You extract structured data from receipt or warranty card images, which may be in Arabic or English.
Return ONLY a JSON object with these exact keys:
productName, brand, store_name, price (number), purchaseDate (YYYY-MM-DD), warrantyMonths (integer), category (string), confidence (0-1 float).
Use null for any field that is not present in the image or that you cannot read with confidence — do not guess or estimate.
Warranty cards often have no price listed; in that case price must be null.
Dates may be written in DD/MM/YYYY format — convert to YYYY-MM-DD.
For "category", classify the product into EXACTLY ONE of these values: electronics, appliances, furniture, vehicles, accessories, other.
Use "electronics" for phones, laptops, TVs, cameras, and similar devices.
Use "appliances" for kitchen/home appliances like fridges, washing machines, microwaves.
Use "furniture" for chairs, tables, sofas, beds.
Use "vehicles" for cars, motorcycles, bicycles.
Use "accessories" for watches, bags, jewelry, small personal items.
Use "other" if the product doesn't clearly fit any of the above, or if you're unsure.
Always return one of these six exact lowercase values for category — never invent a new category name, and never leave it null.`;


serve(async (req) => {
  try {
    const { imageUrl }: ExtractRequest = await req.json();

    if (!imageUrl) {
      return jsonResponse({ error: "imageUrl is required" }, 400);
    }

    const extracted = await runExtraction(imageUrl);
    const validated = validate(extracted);

    return jsonResponse(validated, 200);
  } catch (error) {
    console.error("extract-receipt error:", error);
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});

async function runExtraction(imageUrl: string): Promise<ExtractResponse> {
  const apiKey = Deno.env.get("AI_API_KEY");
  if (!apiKey) {
    throw new Error("AI_API_KEY secret is not configured");
  }

const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Authorization: `Bearer ${apiKey}`,
  },
  body: JSON.stringify({
    model: "qwen/qwen3.6-27b",
    reasoning_effort: "none",     // 1. turn off thinking mode — this is the fix
    response_format: { type: "json_object" },
    max_tokens: 1500,             // 2. headroom in case thinking still leaks through
    temperature: 0.7,             // Groq's documented non-thinking-mode setting
    top_p: 0.8,
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      {
        role: "user",
        content: [
          { type: "text", text: "Extract the fields from this receipt/warranty card image." },
          { type: "image_url", image_url: { url: imageUrl } },
        ],
      },
    ],
  }),
});

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`AI request failed (${response.status}): ${errText}`);
  }

  const completion = await response.json();
  const content = completion.choices?.[0]?.message?.content;
  if (!content) throw new Error("AI returned no content");

  const parsed = JSON.parse(content);

  return {
    productName: parsed.productName ?? null,
    brand: parsed.brand ?? null,
    store_name: parsed.store_name ?? null,
    price: typeof parsed.price === "number" ? parsed.price : null,
    purchaseDate: parsed.purchaseDate ?? null,
    warrantyMonths: typeof parsed.warrantyMonths === "number" ? parsed.warrantyMonths : null,
    category: typeof parsed.category === "string" ? parsed.category : null,
    confidence: typeof parsed.confidence === "number" ? parsed.confidence : 0.5,
  };
}

function validate(data: ExtractResponse): ExtractResponse {
  const today = new Date().toISOString().split("T")[0];

  const normalizedCategory = data.category?.trim().toLowerCase() ?? null;
  const category = ALLOWED_CATEGORIES.includes(normalizedCategory ?? "")
    ? normalizedCategory
    : null;

  return {
    productName: data.productName?.trim() || null,
    brand: data.brand?.trim() || null,
    store_name: data.store_name?.trim() || null,
    price: data.price !== null && data.price > 0 ? data.price : null,
    purchaseDate:
      data.purchaseDate && data.purchaseDate <= today ? data.purchaseDate : null,
    warrantyMonths:
      data.warrantyMonths !== null && data.warrantyMonths >= 0 && data.warrantyMonths <= 120
        ? data.warrantyMonths
        : null,
    category,
    confidence: data.confidence,
  };
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}