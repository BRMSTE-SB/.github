const SECURITY_HEADERS = {
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "strict-origin-when-cross-origin",
};

function json(body, status = 200, extra = {}) {
  const headers = new Headers({
    "Content-Type": "application/json",
    "Cache-Control": "no-store",
    ...SECURITY_HEADERS,
    ...extra,
  });
  return new Response(JSON.stringify(body), { status, headers });
}

function redirect(url, extra = {}) {
  const headers = new Headers({ Location: url, ...SECURITY_HEADERS, ...extra });
  return new Response(null, { status: 302, headers });
}

function requiredEnv(env, key) {
  const value = env[key];
  if (!value) throw new Error(`missing_env:${key}`);
  return value;
}

function base64Url(bytes) {
  const bin = String.fromCharCode(...bytes);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

async function signState(secret, payload) {
  const data = JSON.stringify(payload);
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(data),
  );
  return `${base64Url(new TextEncoder().encode(data))}.${base64Url(new Uint8Array(sig))}`;
}

async function verifyState(secret, token) {
  const [payloadPart, sigPart] = token.split(".");
  if (!payloadPart || !sigPart) return null;
  const data = new TextDecoder().decode(
    Uint8Array.from(atob(payloadPart.replace(/-/g, "+").replace(/_/g, "/")), (c) =>
      c.charCodeAt(0),
    ),
  );
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const sigBytes = Uint8Array.from(
    atob(sigPart.replace(/-/g, "+").replace(/_/g, "/")),
    (c) => c.charCodeAt(0),
  );
  const ok = await crypto.subtle.verify(
    "HMAC",
    key,
    sigBytes,
    new TextEncoder().encode(data),
  );
  if (!ok) return null;
  const payload = JSON.parse(data);
  if (Date.now() > payload.exp) return null;
  return payload;
}

async function exchangeToken(env, body) {
  const issuer = requiredEnv(env, "OKTA_ISSUER").replace(/\/$/, "");
  const clientId = requiredEnv(env, "OKTA_CLIENT_ID");
  const clientSecret = requiredEnv(env, "OKTA_CLIENT_SECRET");
  const tokenUrl = `${issuer}/oauth2/v1/token`;
  const basic = btoa(`${clientId}:${clientSecret}`);
  const response = await fetch(tokenUrl, {
    method: "POST",
    headers: {
      Authorization: `Basic ${basic}`,
      "Content-Type": "application/x-www-form-urlencoded",
      Accept: "application/json",
    },
    body: new URLSearchParams(body).toString(),
  });
  const text = await response.text();
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    parsed = { raw: text };
  }
  return { ok: response.ok, status: response.status, body: parsed };
}

async function fetchUserinfo(env, accessToken) {
  const issuer = requiredEnv(env, "OKTA_ISSUER").replace(/\/$/, "");
  const response = await fetch(`${issuer}/oauth2/v1/userinfo`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: "application/json" },
  });
  if (!response.ok) {
    return { ok: false, status: response.status, body: await response.text() };
  }
  return { ok: true, body: await response.json() };
}

function publicConfig(env) {
  const issuer = env.OKTA_ISSUER ?? "https://trial-4122800.okta.com";
  const clientId = env.OKTA_CLIENT_ID ?? "0oa14nyit7owrT8Yw698";
  const redirectUri =
    env.OKTA_REDIRECT_URI ?? "https://brmste.com/api/auth/okta/callback";
  const registerUrl = env.BRMSTE_REGISTER_URL ?? "https://brmste.com/register";
  return {
    ok: true,
    provider: "okta",
    issuer,
    client_id: clientId,
    operator_identity: env.OKTA_OPERATOR_IDENTITY ?? "sb@brmste.ai",
    modes: ["web_oidc", "client_credentials"],
    routes: {
      login: "/api/auth/okta/login",
      callback: "/api/auth/okta/callback",
      service_token: "/api/auth/okta/service-token",
      config: "/api/auth/okta/config",
    },
    redirect_uri: redirectUri,
    register_url: registerUrl,
    scopes_web: ["openid", "profile", "email", "offline_access"],
    register_manifest:
      "https://brmste.com/substrate/identity/okta-trial-4122800.json",
  };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/$/, "") || "/";

    try {
      if (path === "/health") {
        return json({
          ok: true,
          service: "brmste-okta-auth",
          configured: Boolean(env.OKTA_CLIENT_SECRET),
        });
      }

      if (path === "/api/auth/okta/config") {
        return json(publicConfig(env));
      }

      if (path === "/api/auth/okta/login") {
        const secret = requiredEnv(env, "OKTA_CLIENT_SECRET");
        const issuer = requiredEnv(env, "OKTA_ISSUER").replace(/\/$/, "");
        const clientId = requiredEnv(env, "OKTA_CLIENT_ID");
        const redirectUri = requiredEnv(env, "OKTA_REDIRECT_URI");
        const state = await signState(secret, {
          n: crypto.randomUUID(),
          exp: Date.now() + 10 * 60 * 1000,
        });
        const params = new URLSearchParams({
          client_id: clientId,
          response_type: "code",
          scope: "openid profile email offline_access",
          redirect_uri: redirectUri,
          state,
        });
        return redirect(`${issuer}/oauth2/v1/authorize?${params.toString()}`);
      }

      if (path === "/api/auth/okta/callback") {
        const secret = requiredEnv(env, "OKTA_CLIENT_SECRET");
        const redirectUri = requiredEnv(env, "OKTA_REDIRECT_URI");
        const registerUrl = env.BRMSTE_REGISTER_URL ?? "https://brmste.com/register";
        const code = url.searchParams.get("code");
        const state = url.searchParams.get("state");
        const oktaError = url.searchParams.get("error");

        if (oktaError) {
          return json(
            { ok: false, error: "okta_authorize_denied", detail: oktaError },
            400,
          );
        }
        if (!code || !state) {
          return json({ ok: false, error: "code_and_state_required" }, 400);
        }

        const statePayload = await verifyState(secret, state);
        if (!statePayload) {
          return json({ ok: false, error: "invalid_state" }, 400);
        }

        const tokenResult = await exchangeToken(env, {
          grant_type: "authorization_code",
          code,
          redirect_uri: redirectUri,
        });
        if (!tokenResult.ok) {
          return json(
            {
              ok: false,
              error: "token_exchange_failed",
              status: tokenResult.status,
              detail: tokenResult.body,
            },
            502,
          );
        }

        const accessToken = tokenResult.body.access_token;
        const userinfo = accessToken
          ? await fetchUserinfo(env, accessToken)
          : { ok: false };

        const operatorIdentity = env.OKTA_OPERATOR_IDENTITY ?? "sb@brmste.ai";
        const email = userinfo.ok ? userinfo.body.email : undefined;

        return json({
          ok: true,
          provider: "okta",
          mode: "web_oidc",
          operator_identity: operatorIdentity,
          user: userinfo.ok ? userinfo.body : null,
          email_match_operator:
            email && email.toLowerCase() === operatorIdentity.toLowerCase(),
          token: {
            expires_in: tokenResult.body.expires_in,
            scope: tokenResult.body.scope,
            has_refresh_token: Boolean(tokenResult.body.refresh_token),
          },
          next: `${registerUrl}/kyc`,
          register_manifest:
            "https://brmste.com/substrate/identity/okta-trial-4122800.json",
        });
      }

      if (path === "/api/auth/okta/service-token") {
        if (request.method !== "POST") {
          return json({ ok: false, error: "method_not_allowed" }, 405);
        }

        const internal = env.OKTA_SERVICE_INTERNAL_TOKEN;
        if (internal) {
          const provided =
            request.headers.get("x-brmste-internal-token") ??
            request.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
          if (provided !== internal) {
            return json({ ok: false, error: "unauthorized" }, 401);
          }
        }

        let scope = "okta.clients.read okta.apps.read";
        try {
          const body = await request.json();
          if (body?.scope && typeof body.scope === "string") {
            scope = body.scope;
          }
        } catch {
          /* optional JSON body */
        }

        const tokenResult = await exchangeToken(env, {
          grant_type: "client_credentials",
          scope,
        });
        if (!tokenResult.ok) {
          return json(
            {
              ok: false,
              error: "client_credentials_failed",
              status: tokenResult.status,
              detail: tokenResult.body,
            },
            502,
          );
        }

        return json({
          ok: true,
          provider: "okta",
          mode: "client_credentials",
          operator_identity: env.OKTA_OPERATOR_IDENTITY ?? "sb@brmste.ai",
          token: {
            access_token: tokenResult.body.access_token,
            expires_in: tokenResult.body.expires_in,
            scope: tokenResult.body.scope,
            token_type: tokenResult.body.token_type,
          },
        });
      }

      return json({ ok: false, error: "not_found" }, 404);
    } catch (err) {
      const message = err instanceof Error ? err.message : "unknown_error";
      if (message.startsWith("missing_env:")) {
        return json({ ok: false, error: "not_configured", detail: message }, 503);
      }
      return json({ ok: false, error: "internal_error" }, 500);
    }
  },
};
