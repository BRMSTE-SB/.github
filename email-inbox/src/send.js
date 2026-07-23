// BRMSTE email inbox — outbound sending via CloudMailin
// BRMSTE LTD · Companies House 15310393 · GB2607860
//
// CloudMailin outbound API:
//   POST https://api.cloudmailin.com/api/v0.1/{SMTP_USERNAME}/messages
//   Auth: HTTP Basic (SMTP username + API key)  [docs: "smtpAuth"]
//   Body: { from, to[], cc?, subject, plain?, html?, test_mode? }
//   202 = accepted, 401 = unauthorized, 422 = validation error
//
// Credentials are read from env (never hard-coded / never in chat):
//   CLOUDMAILIN_USERNAME, CLOUDMAILIN_API_KEY, CLOUDMAILIN_FROM (optional)

const API_BASE = "https://api.cloudmailin.com/api/v0.1";

export function cloudmailinConfig(env) {
  return {
    username: env.CLOUDMAILIN_USERNAME || "",
    apiKey: env.CLOUDMAILIN_API_KEY || "",
    from: env.CLOUDMAILIN_FROM || "BRMSTE <sb@brmste.ai>",
  };
}

export function isConfigured(env) {
  const c = cloudmailinConfig(env);
  return Boolean(c.username && c.apiKey);
}

function b64(s) {
  // Works in both workerd (btoa) and Node 18+ (btoa global, Buffer fallback).
  if (typeof btoa === "function") return btoa(s);
  return Buffer.from(s, "utf-8").toString("base64");
}

export function normalizeMessage(m, defaults = {}) {
  if (!m || (!m.to && m.to !== 0)) throw new Error("missing-to");
  const to = Array.isArray(m.to) ? m.to : [m.to];
  const out = {
    from: m.from || defaults.from,
    to,
    subject: m.subject ?? "",
  };
  if (m.cc) out.cc = Array.isArray(m.cc) ? m.cc : [m.cc];
  if (m.plain != null) out.plain = m.plain;
  if (m.html != null) out.html = m.html;
  if (m.plain == null && m.html == null && m.text != null) out.plain = m.text;
  if (m.test_mode) out.test_mode = true;
  if (m.tags) out.tags = Array.isArray(m.tags) ? m.tags : [m.tags];
  return out;
}

export function buildSendRequest(cfg, message) {
  if (!cfg.username || !cfg.apiKey) throw new Error("cloudmailin-not-configured");
  return {
    url: `${API_BASE}/${encodeURIComponent(cfg.username)}/messages`,
    method: "POST",
    headers: {
      Authorization: "Basic " + b64(`${cfg.username}:${cfg.apiKey}`),
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify(normalizeMessage(message, { from: cfg.from })),
  };
}

export async function sendViaCloudMailin(env, message, fetchImpl) {
  const doFetch = fetchImpl || globalThis.fetch;
  const cfg = cloudmailinConfig(env);
  const req = buildSendRequest(cfg, message);

  const res = await doFetch(req.url, {
    method: req.method,
    headers: req.headers,
    body: req.body,
  });

  let data = null;
  try {
    data = await res.json();
  } catch (_) {
    data = null;
  }

  if (res.status === 202) {
    return { ok: true, status: 202, id: data?.id ?? null, message: data ?? null };
  }
  const error =
    res.status === 401
      ? "unauthorized"
      : res.status === 422
        ? "validation-failed"
        : "send-failed";
  return { ok: false, status: res.status, error, detail: data };
}
