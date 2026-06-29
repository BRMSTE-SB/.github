// BRMSTE email inbox — core logic (runtime-agnostic, dependency-injected)
// BRMSTE LTD · Companies House 15310393 · GB2607860
//
// Captures inbound mail (Cloudflare Email Worker) and serves a token-protected
// JSON reader. All persistence goes through an injected `storage` object so the
// same code runs under workerd in production and under Node in the tests.

import PostalMime from "postal-mime";
import { isConfigured, sendViaCloudMailin } from "./send.js";

export const INBOX_PAGE = "brmste-email-inbox-v1";

const SECURITY_HEADERS = {
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Referrer-Policy": "no-referrer",
  "Cache-Control": "no-store",
};

function json(body, status = 200, extra) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...SECURITY_HEADERS,
      ...(extra || {}),
    },
  });
}

// Length-constant comparison to avoid leaking the token via timing.
function safeEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
  const enc = new TextEncoder();
  const ab = enc.encode(a);
  const bb = enc.encode(b);
  if (ab.length !== bb.length) return false;
  let diff = 0;
  for (let i = 0; i < ab.length; i++) diff |= ab[i] ^ bb[i];
  return diff === 0;
}

export function extractToken(request) {
  const auth = request.headers.get("Authorization") || "";
  const m = /^Bearer\s+(.+)$/i.exec(auth.trim());
  if (m) return m[1].trim();
  const t = new URL(request.url).searchParams.get("token");
  return t ? t.trim() : "";
}

export function allowedAddresses(env) {
  const raw = env.INBOX_ADDRESSES || "sb@brmste.ai";
  return raw
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
}

async function readRaw(message) {
  const raw = message.raw;
  if (raw == null) return new ArrayBuffer(0);
  if (raw instanceof ArrayBuffer) return raw;
  if (ArrayBuffer.isView(raw)) {
    return raw.buffer.slice(raw.byteOffset, raw.byteOffset + raw.byteLength);
  }
  if (typeof raw === "string") return new TextEncoder().encode(raw).buffer;
  // Otherwise assume a ReadableStream (Cloudflare's message.raw).
  return await new Response(raw).arrayBuffer();
}

function pickAddress(value) {
  if (!value) return "";
  if (Array.isArray(value)) return value[0]?.address?.toLowerCase?.() || "";
  return value.address?.toLowerCase?.() || "";
}

function cleanId(id) {
  return String(id).replace(/[<>]/g, "").trim().slice(0, 255);
}

export async function parseEmail(raw) {
  return await new PostalMime().parse(raw);
}

export function recordFromParsed(parsed, ctx = {}) {
  const ts = ctx.ts ?? Date.now();
  const rawId =
    ctx.id ||
    parsed.messageId ||
    `brmste-${ts}-${Math.random().toString(36).slice(2, 10)}`;
  const headers_json = JSON.stringify(
    (parsed.headers || []).reduce((acc, h) => {
      if (h && h.key) acc[h.key] = h.value;
      return acc;
    }, {}),
  );
  return {
    id: cleanId(rawId),
    ts,
    mail_from: (ctx.mail_from || pickAddress(parsed.from) || "").toLowerCase(),
    rcpt_to: (ctx.rcpt_to || pickAddress(parsed.to) || "").toLowerCase(),
    subject: parsed.subject || "",
    text_body: parsed.text || "",
    html_body: parsed.html || "",
    raw_size: ctx.raw_size ?? null,
    message_id: parsed.messageId || null,
    headers_json,
  };
}

// Inbound mail handler. Returns a small result object (handy for tests/logs).
export async function handleEmailMessage(message, env, storage) {
  const to = String(message.to || "").toLowerCase();
  const allow = allowedAddresses(env);
  const isAllowed = allow.length === 0 || allow.includes(to);

  if (!isAllowed) {
    if (env.FORWARD_TO && typeof message.forward === "function") {
      await message.forward(env.FORWARD_TO);
    }
    return { stored: false, reason: "recipient-not-allowed", to };
  }

  const rawBuf = await readRaw(message);
  const parsed = await parseEmail(rawBuf);
  const rec = recordFromParsed(parsed, {
    mail_from: message.from,
    rcpt_to: to,
    raw_size: message.rawSize ?? rawBuf.byteLength,
    id: parsed.messageId,
  });
  await storage.putEmail(rec);

  // Optionally also forward a copy to a verified human mailbox.
  if (env.FORWARD_TO && typeof message.forward === "function") {
    try {
      await message.forward(env.FORWARD_TO);
    } catch (_) {
      // Forwarding is best-effort; the message is already captured in D1.
    }
  }

  return { stored: true, id: rec.id, to: rec.rcpt_to, subject: rec.subject };
}

// HTTP reader. GET /health (open) and GET /inbox (token-protected).
export async function handleInboxRequest(request, env, storage) {
  const url = new URL(request.url);
  const path = url.pathname.replace(/\/+$/, "") || "/";

  if (path === "/health") {
    return json({
      ok: true,
      service: "brmste-email-inbox",
      page: env.BRMSTE_PAGE || INBOX_PAGE,
      addresses: allowedAddresses(env),
      inbox_reader: env.INBOX_TOKEN ? "ready" : "locked",
      outbound: isConfigured(env) ? "ready" : "not-configured",
    });
  }

  if (path === "/inbox") {
    if (request.method !== "GET") {
      return json({ ok: false, error: "method-not-allowed" }, 405);
    }

    const token = env.INBOX_TOKEN;
    if (!token) {
      return json({ ok: false, error: "inbox-token-not-configured" }, 503);
    }
    if (!safeEqual(extractToken(request), token)) {
      return json({ ok: false, error: "unauthorized" }, 401, {
        "WWW-Authenticate": "Bearer",
      });
    }

    const id = url.searchParams.get("id");
    if (id) {
      const email = await storage.getEmail(id);
      if (!email) return json({ ok: false, error: "not-found" }, 404);
      return json({ ok: true, email });
    }

    const address = url.searchParams.get("address") || undefined;
    const limit = url.searchParams.get("limit") || undefined;
    const emails = await storage.listEmails({ address, limit });
    return json({
      ok: true,
      count: emails.length,
      address: address || null,
      emails,
    });
  }

  if (path === "/send") {
    if (request.method !== "POST") {
      return json({ ok: false, error: "method-not-allowed" }, 405);
    }
    const token = env.INBOX_TOKEN;
    if (!token) return json({ ok: false, error: "inbox-token-not-configured" }, 503);
    if (!safeEqual(extractToken(request), token)) {
      return json({ ok: false, error: "unauthorized" }, 401, {
        "WWW-Authenticate": "Bearer",
      });
    }
    if (!isConfigured(env)) {
      return json({ ok: false, error: "cloudmailin-not-configured" }, 503);
    }
    let payload;
    try {
      payload = await request.json();
    } catch (_) {
      return json({ ok: false, error: "invalid-json" }, 400);
    }
    const hasBody =
      payload &&
      (payload.plain != null || payload.html != null || payload.text != null);
    if (!payload || !payload.to || !hasBody) {
      return json(
        { ok: false, error: "missing-fields", need: ["to", "plain|html", "subject"] },
        422,
      );
    }
    const result = await sendViaCloudMailin(env, payload);
    return json(result, result.ok ? 202 : result.status || 502);
  }

  return json({ ok: false, error: "not-found" }, 404);
}

// Exposed for unit tests only.
export const __test__ = { safeEqual, readRaw, pickAddress, cleanId };
