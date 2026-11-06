// Google Gemini, Sakk's backup AI provider. The functions call Groq first and
// fall back to Gemini when Groq fails or hits its limits, so one provider's
// outage or rate limit doesn't stop scans, voice or chat. Without a
// GEMINI_API_KEY the functions use Groq only, as before.
//
// Secrets: GEMINI_API_KEY (from aistudio.google.com). GEMINI_MODEL is
// optional; the default is a cheap Flash-Lite model that reads images and
// audio. Google retires models: check GET /v1beta/models before changing it.

import { encodeBase64 } from "jsr:@std/encoding@1/base64";

const DEFAULT_MODEL = "gemini-2.5-flash-lite";
const API_BASE = "https://generativelanguage.googleapis.com/v1beta/models";

// Images and recordings are sent inline, which Gemini caps at about 20 MB a
// request. The app's uploads are far smaller.
const MAX_INLINE_BYTES = 15 * 1024 * 1024;

/** Gemini's rate limit was hit. */
export class GeminiBusyError extends Error {
  constructor() {
    super("gemini_busy");
  }
}

export type GeminiPart =
  | { text: string }
  | { inline_data: { mime_type: string; data: string } };

export interface GeminiMessage {
  role: "user" | "model";
  parts: GeminiPart[];
}

export interface GeminiOptions {
  system: string;
  contents: GeminiMessage[];
  temperature: number;
  maxOutputTokens: number;
  // Asks for a JSON object as the answer.
  json?: boolean;
}

/** True when a Gemini key is set, so Gemini can take over from Groq. */
export function geminiConfigured(): boolean {
  return !!Deno.env.get("GEMINI_API_KEY");
}

/** Gemini's text answer. Throws GeminiBusyError on 429, Error otherwise. */
export async function geminiGenerate(options: GeminiOptions): Promise<string> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) throw new Error("GEMINI_API_KEY secret is not configured");
  const model = Deno.env.get("GEMINI_MODEL") || DEFAULT_MODEL;

  const response = await fetch(`${API_BASE}/${encodeURIComponent(model)}:generateContent`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
    body: JSON.stringify({
      systemInstruction: { parts: [{ text: options.system }] },
      contents: options.contents,
      generationConfig: {
        temperature: options.temperature,
        maxOutputTokens: options.maxOutputTokens,
        ...(options.json ? { responseMimeType: "application/json" } : {}),
      },
    }),
  });

  if (response.status === 429) {
    await response.body?.cancel();
    throw new GeminiBusyError();
  }
  if (!response.ok) {
    throw new Error(`Gemini request failed (${response.status}): ${await response.text()}`);
  }

  const result = await response.json();
  const parts: { text?: string; thought?: boolean }[] = result.candidates?.[0]?.content?.parts ?? [];
  const text = parts.filter((p) => !p.thought && typeof p.text === "string").map((p) => p.text).join("");
  if (!text.trim()) {
    const reason = result.candidates?.[0]?.finishReason ?? result.promptFeedback?.blockReason ?? "unknown";
    throw new Error(`Gemini returned no content (${reason})`);
  }
  return text;
}

/** The file at [url] as an inline Gemini part. */
export async function inlinePartFromUrl(url: string, fallbackMimeType: string): Promise<GeminiPart> {
  const file = await fetch(url);
  if (!file.ok) throw new Error(`Downloading the file for Gemini failed (${file.status})`);
  const bytes = new Uint8Array(await file.arrayBuffer());
  if (bytes.length > MAX_INLINE_BYTES) throw new Error("File too large to send to Gemini");
  const header = file.headers.get("content-type")?.split(";")[0].trim();
  const mimeType = header && header !== "application/octet-stream" ? header : fallbackMimeType;
  return { inline_data: { mime_type: mimeType, data: encodeBase64(bytes) } };
}
