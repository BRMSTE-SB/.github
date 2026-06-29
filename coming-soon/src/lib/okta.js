/**
 * Okta OIDC (authorization code + PKCE) for BRMSTE edge worker.
 * Secrets: OKTA_CLIENT_ID, OKTA_CLIENT_SECRET via wrangler — never in git.
 */

const DEFAULT_ISSUER = "https://trial-4122800.okta.com/oauth2/default";
const SESSION_COOKIE = "brmste_session";
const FLOW_COOKIE = "brmste_oidc";
const SESSION_TTL_SEC = 60 * 60 * 8;
const FLOW_TTL_SEC = 600;

let jwksCache = { issuer: "", keys: null, fetchedAt: 0 };
const JWKS_TTL_MS = 60 * 60 * 1000;

export function oktaConfigured(env) {
  return Boolean(env.OKTA_CLIENT_ID && env.OKTA_CLIENT_SECRET);
}

export function oktaIssuer(env) {
  return (env.OKTA_ISSUER || DEFAULT_ISSUER).replace(/\/$/, "");
}

function base64UrlEncode(bytes) {
  const bin = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes);
  let str = "";
  for (const b of bin) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64UrlDecode(str) {
  const padded = str.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((str.length + 3) % 4);
  const bin = atob(padded);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

async function sha256(input) {
  return crypto.subtle.digest("SHA-256", new TextEncoder().encode(input));
}

async function hmacSign(secret, message) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
}

function randomString(len = 48) {
  const bytes = crypto.getRandomValues(new Uint8Array(len));
  return base64UrlEncode(bytes).slice(0, len);
}

function redirectUriFor(request) {
  const url = new URL(request.url);
  return `${url.origin}/login/callback`;
}

function safeReturnTo(value) {
  if (!value || typeof value !== "string") return "/banking";
  if (!value.startsWith("/") || value.startsWith("//")) return "/banking";
  return value;
}

function parseCookies(request) {
  const header = request.headers.get("Cookie") || "";
  const out = {};
  for (const part of header.split(";")) {
    const idx = part.indexOf("=");
    if (idx === -1) continue;
    const key = part.slice(0, idx).trim();
    const val = part.slice(idx + 1).trim();
    if (key) out[key] = decodeURIComponent(val);
  }
  return out;
}

function cookieHeader(name, value, { maxAge, httpOnly = true, secure = true, path = "/" } = {}) {
  const parts = [`${name}=${encodeURIComponent(value)}`, `Path=${path}`, "SameSite=Lax"];
  if (httpOnly) parts.push("HttpOnly");
  if (secure) parts.push("Secure");
  if (maxAge !== undefined) parts.push(`Max-Age=${maxAge}`);
  return parts.join("; ");
}

async function signPayload(secret, payload) {
  const body = base64UrlEncode(new TextEncoder().encode(JSON.stringify(payload)));
  const sig = base64UrlEncode(await hmacSign(secret, body));
  return `${body}.${sig}`;
}

async function verifySignedPayload(secret, token) {
  if (!token) return null;
  const dot = token.lastIndexOf(".");
  if (dot === -1) return null;
  const body = token.slice(0, dot);
  const sig = token.slice(dot + 1);
  const expected = base64UrlEncode(await hmacSign(secret, body));
  if (sig.length !== expected.length) return null;
  let ok = 0;
  for (let i = 0; i < sig.length; i++) ok |= sig.charCodeAt(i) ^ expected.charCodeAt(i);
  if (ok !== 0) return null;
  try {
    const json = new TextDecoder().decode(base64UrlDecode(body));
    return JSON.parse(json);
  } catch {
    return null;
  }
}

async function discovery(issuer) {
  const res = await fetch(`${issuer}/.well-known/openid-configuration`, {
    headers: { Accept: "application/json" },
  });
  if (!res.ok) throw new Error(`Okta discovery failed (${res.status})`);
  return res.json();
}

async function jwksForIssuer(issuer) {
  const now = Date.now();
  if (jwksCache.issuer === issuer && jwksCache.keys && now - jwksCache.fetchedAt < JWKS_TTL_MS) {
    return jwksCache.keys;
  }
  const meta = await discovery(issuer);
  const res = await fetch(meta.jwks_uri, { headers: { Accept: "application/json" } });
  if (!res.ok) throw new Error(`Okta JWKS fetch failed (${res.status})`);
  const body = await res.json();
  jwksCache = { issuer, keys: body.keys ?? [], fetchedAt: now };
  return jwksCache.keys;
}

function decodeJwtPart(part) {
  return JSON.parse(new TextDecoder().decode(base64UrlDecode(part)));
}

async function importRsaKey(jwk) {
  return crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"],
  );
}

async function verifyIdToken(idToken, env, nonce) {
  const issuer = oktaIssuer(env);
  const parts = idToken.split(".");
  if (parts.length !== 3) throw new Error("Invalid id_token format");
  const header = decodeJwtPart(parts[0]);
  const payload = decodeJwtPart(parts[1]);
  const keys = await jwksForIssuer(issuer);
  const jwk = keys.find((k) => k.kid === header.kid);
  if (!jwk) throw new Error("No matching JWKS key");
  const key = await importRsaKey(jwk);
  const data = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
  const signature = base64UrlDecode(parts[2]);
  const valid = await crypto.subtle.verify({ name: "RSASSA-PKCS1-v1_5" }, key, signature, data);
  if (!valid) throw new Error("id_token signature invalid");

  const now = Math.floor(Date.now() / 1000);
  if (payload.iss !== issuer) throw new Error("id_token issuer mismatch");
  if (payload.aud !== env.OKTA_CLIENT_ID) throw new Error("id_token audience mismatch");
  if (payload.exp <= now) throw new Error("id_token expired");
  if (nonce && payload.nonce !== nonce) throw new Error("id_token nonce mismatch");

  return payload;
}

export async function getSession(request, env) {
  if (!oktaConfigured(env)) return null;
  const cookies = parseCookies(request);
  const payload = await verifySignedPayload(env.OKTA_CLIENT_SECRET, cookies[SESSION_COOKIE]);
  if (!payload?.sub) return null;
  if (payload.exp <= Math.floor(Date.now() / 1000)) return null;
  return payload;
}

export async function startLogin(request, env) {
  const issuer = oktaIssuer(env);
  const meta = await discovery(issuer);
  const url = new URL(request.url);
  const returnTo = safeReturnTo(url.searchParams.get("returnTo"));
  const state = randomString(32);
  const nonce = randomString(32);
  const codeVerifier = randomString(64);
  const challenge = base64UrlEncode(await sha256(codeVerifier));
  const redirectUri = redirectUriFor(request);

  const flow = await signPayload(env.OKTA_CLIENT_SECRET, {
    state,
    nonce,
    codeVerifier,
    redirectUri,
    returnTo,
    exp: Math.floor(Date.now() / 1000) + FLOW_TTL_SEC,
  });

  const params = new URLSearchParams({
    client_id: env.OKTA_CLIENT_ID,
    response_type: "code",
    scope: "openid profile email",
    redirect_uri: redirectUri,
    state,
    nonce,
    code_challenge: challenge,
    code_challenge_method: "S256",
  });

  return new Response(null, {
    status: 302,
    headers: {
      Location: `${meta.authorization_endpoint}?${params}`,
      "Set-Cookie": cookieHeader(FLOW_COOKIE, flow, { maxAge: FLOW_TTL_SEC }),
      "Cache-Control": "no-store",
    },
  });
}

export async function finishLogin(request, env) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const err = url.searchParams.get("error");
  if (err) {
    return new Response(`Okta login error: ${err}`, { status: 400 });
  }
  if (!code || !state) {
    return new Response("Missing authorization code", { status: 400 });
  }

  const cookies = parseCookies(request);
  const flow = await verifySignedPayload(env.OKTA_CLIENT_SECRET, cookies[FLOW_COOKIE]);
  if (!flow || flow.state !== state || flow.exp <= Math.floor(Date.now() / 1000)) {
    return new Response("Invalid or expired login session", { status: 400 });
  }

  const issuer = oktaIssuer(env);
  const meta = await discovery(issuer);
  const tokenRes = await fetch(meta.token_endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json" },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      client_id: env.OKTA_CLIENT_ID,
      client_secret: env.OKTA_CLIENT_SECRET,
      code,
      redirect_uri: flow.redirectUri,
      code_verifier: flow.codeVerifier,
    }),
  });

  if (!tokenRes.ok) {
    return new Response("Token exchange failed", { status: 502 });
  }

  const tokens = await tokenRes.json();
  const claims = await verifyIdToken(tokens.id_token, env, flow.nonce);
  const session = await signPayload(env.OKTA_CLIENT_SECRET, {
    sub: claims.sub,
    email: claims.email ?? null,
    name: claims.name ?? null,
    exp: Math.floor(Date.now() / 1000) + SESSION_TTL_SEC,
  });

  const headers = new Headers({
    Location: flow.returnTo || "/banking",
    "Cache-Control": "no-store",
  });
  headers.append("Set-Cookie", cookieHeader(SESSION_COOKIE, session, { maxAge: SESSION_TTL_SEC }));
  headers.append("Set-Cookie", cookieHeader(FLOW_COOKIE, "", { maxAge: 0 }));

  return new Response(null, { status: 302, headers });
}

export function logout(request, env) {
  const issuer = oktaIssuer(env);
  const returnTo = new URL("/banking", request.url).toString();
  const location = `${issuer}/v1/logout?${new URLSearchParams({
    client_id: env.OKTA_CLIENT_ID,
    post_logout_redirect_uri: returnTo,
  })}`;

  return new Response(null, {
    status: 302,
    headers: {
      Location: location,
      "Set-Cookie": cookieHeader(SESSION_COOKIE, "", { maxAge: 0 }),
      "Cache-Control": "no-store",
    },
  });
}

export async function requireAuth(request, env) {
  if (!oktaConfigured(env)) return { ok: true, session: null };
  const session = await getSession(request, env);
  if (session) return { ok: true, session };
  return { ok: false, session: null };
}

export function loginRedirect(request) {
  const url = new URL(request.url);
  const returnTo = `${url.pathname}${url.search}`;
  return new Response(null, {
    status: 302,
    headers: {
      Location: `/login?returnTo=${encodeURIComponent(returnTo)}`,
      "Cache-Control": "no-store",
    },
  });
}

export function unauthorizedJson(request) {
  const url = new URL(request.url);
  return new Response(
    JSON.stringify({
      ok: false,
      message: "Authentication required",
      login: `/login?returnTo=${encodeURIComponent(`${url.pathname}${url.search}`)}`,
    }),
    {
      status: 401,
      headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
    },
  );
}
