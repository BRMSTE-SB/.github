/**
 * BRMSTE · Companies House live filings + streaming on Cloudflare Workers
 * Routes: /api/ch/*
 */

const WATCH_DEFAULT =
  "15310393,00030209,FC021146,01833139,03949032,00727817,02448457,02180021,03468788,00874867";

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "access-control-allow-origin": "*",
    },
  });
}

function basicAuth(key) {
  const token = btoa(`${key}:`);
  return `Basic ${token}`;
}

function watchSet(env) {
  const raw = env.CH_WATCH_NUMBERS || WATCH_DEFAULT;
  return new Set(raw.split(",").map((s) => s.trim()).filter(Boolean));
}

async function chGet(env, path, bearer = false) {
  const base = env.CH_API_BASE || "https://api.company-information.service.gov.uk";
  const headers = {};
  if (bearer) {
    const token = env.COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN;
    if (!token) throw new Error("missing_oauth_access_token");
    headers.authorization = `Bearer ${token}`;
  } else {
    const key = env.COMPANIES_HOUSE_API_KEY;
    if (!key) throw new Error("missing_api_key");
    headers.authorization = basicAuth(key);
  }
  const res = await fetch(`${base}${path}`, { headers });
  const text = await res.text();
  let body;
  try {
    body = text ? JSON.parse(text) : {};
  } catch {
    body = { raw: text.slice(0, 500) };
  }
  return { status: res.status, body };
}

function roaCompareKey(addr) {
  if (!addr) return "";
  let line1 = String(addr.address_line_1 || "").trim().toLowerCase();
  const premises = String(addr.premises || "").trim().toLowerCase();
  if (premises && !line1.includes(premises)) line1 = `${premises} ${line1}`.trim();
  const countryRaw = String(addr.country || "").trim().toLowerCase();
  let countryNorm = countryRaw;
  let regionNorm = String(addr.region || "").trim().toLowerCase();
  if (["england", "united kingdom", "uk", "great britain"].includes(countryRaw)) {
    countryNorm = "uk";
    regionNorm = "";
  }
  return [
    line1,
    String(addr.address_line_2 || "").trim().toLowerCase(),
    String(addr.locality || "").trim().toLowerCase(),
    regionNorm,
    String(addr.postal_code || "").trim().toLowerCase().replace(/\s/g, ""),
    countryNorm,
  ].join("|");
}

async function loadBundle(env) {
  const raw = await env.CH_STATE.get("companies-house-live.json");
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function syncCompanyStatuses(env) {
  const watch = watchSet(env);
  const results = [];
  for (const num of watch) {
    const profile = await chGet(env, `/company/${num}`);
    const roa = await chGet(env, `/company/${num}/registered-office-address`);
    const history = await chGet(env, `/company/${num}/filing-history?items_per_page=3`);
    const entry = {
      company_number: num,
      profile_status: profile.status,
      company_name: profile.body?.company_name,
      company_status: profile.body?.company_status,
      registered_office: roa.body,
      latest_filings: (history.body?.items || []).map((i) => ({
        type: i.type,
        description: i.description,
        date: i.date,
        category: i.category,
      })),
      synced_at: new Date().toISOString(),
    };
    await env.CH_STATE.put(`ch:company:${num}`, JSON.stringify(entry));
    results.push({ company_number: num, ok: profile.status === 200 });
  }
  await env.CH_STATE.put(
    "ch:sync:last",
    JSON.stringify({ at: new Date().toISOString(), count: results.length, results })
  );
  return results;
}

async function pullStreamFilings(env, maxLines = 40) {
  const key = env.COMPANIES_HOUSE_STREAMING_API_KEY;
  if (!key) return { skipped: true, reason: "no_streaming_key" };

  const streamId = "filings";
  const tpKey = `ch:stream:${streamId}:timepoint`;
  const prevTp = await env.CH_STATE.get(tpKey);
  const base = env.CH_STREAM_BASE || "https://stream.companieshouse.gov.uk";
  let url = `${base}/filings`;
  if (prevTp) url += `?timepoint=${encodeURIComponent(prevTp)}`;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 22000);
  const watch = watchSet(env);
  const matched = [];

  try {
    const res = await fetch(url, {
      headers: { authorization: basicAuth(key), accept: "application/json" },
      signal: controller.signal,
    });
    if (!res.ok) {
      return { error: `stream_http_${res.status}`, url };
    }
    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    let lines = 0;
    let lastTimepoint = prevTp;

    while (lines < maxLines) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const parts = buffer.split("\n");
      buffer = parts.pop() || "";
      for (const line of parts) {
        if (!line.trim()) continue;
        lines += 1;
        try {
          const payload = JSON.parse(line);
          const cn =
            payload.data?.company_number ||
            payload.data?.companyNumber ||
            (payload.resource_uri?.includes("/company/")
              ? payload.resource_uri.split("/company/")[1]?.split("/")[0]
              : null);
          if (payload.event?.timepoint) lastTimepoint = String(payload.event.timepoint);
          if (cn && watch.has(cn)) {
            matched.push({
              company_number: cn,
              resource_kind: payload.resource_kind,
              type: payload.event?.type,
              published_at: payload.event?.published_at,
              timepoint: payload.event?.timepoint,
              resource_uri: payload.resource_uri,
            });
            await env.CH_STATE.put(
              `ch:stream:event:${cn}:${payload.event?.timepoint || Date.now()}`,
              JSON.stringify(payload)
            );
          }
        } catch {
          /* skip bad line */
        }
        if (lines >= maxLines) break;
      }
    }
    reader.cancel().catch(() => {});
    if (lastTimepoint && lastTimepoint !== prevTp) {
      await env.CH_STATE.put(tpKey, lastTimepoint);
    }
    await env.CH_STATE.put(
      "ch:stream:last_pull",
      JSON.stringify({
        at: new Date().toISOString(),
        stream: streamId,
        lines_read: lines,
        matched: matched.length,
        timepoint: lastTimepoint,
      })
    );
    return { lines_read: lines, matched, timepoint: lastTimepoint };
  } catch (e) {
    return { error: String(e?.message || e) };
  } finally {
    clearTimeout(timeout);
  }
}

async function refreshOAuthToken(env) {
  const clientId = env.COMPANIES_HOUSE_OAUTH_CLIENT_ID;
  const clientSecret = env.COMPANIES_HOUSE_OAUTH_CLIENT_SECRET;
  const refresh = env.COMPANIES_HOUSE_OAUTH_REFRESH_TOKEN;
  if (!clientId || !clientSecret || !refresh) {
    throw new Error("missing_oauth_refresh_credentials");
  }
  const base = env.CH_IDENTITY_BASE || "https://identity.company-information.service.gov.uk";
  const body = new URLSearchParams({
    grant_type: "refresh_token",
    refresh_token: refresh,
    client_id: clientId,
    client_secret: clientSecret,
  });
  const res = await fetch(`${base}/oauth/token`, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body,
  });
  const data = await res.json();
  if (!res.ok) throw new Error(`token_refresh_${res.status}:${JSON.stringify(data)}`);
  await env.CH_KV.put(
    "ch:oauth",
    JSON.stringify({
      refreshed_at: new Date().toISOString(),
      expires_in: data.expires_in,
      scope: data.scope,
      has_refresh: Boolean(data.refresh_token),
    })
  );
  return data;
}

async function getAccessToken(env) {
  if (env.COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN) {
    return env.COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN;
  }
  const tokens = await refreshOAuthToken(env);
  return tokens.access_token;
}

async function fileBrmsteRoa(env) {
  const bundle = await loadBundle(env);
  const canonical =
    bundle?.brmste?.roa_canonical ||
    bundle?.brmste?.registered_office?.address;
  if (!canonical) throw new Error("missing_roa_canonical_in_bundle");

  const num = "15310393";
  const roa = await chGet(env, `/company/${num}/registered-office-address`);
  if (roa.status !== 200) throw new Error(`roa_fetch_${roa.status}`);

  const needs = roaCompareKey(roa.body) !== roaCompareKey(canonical);
  if (!needs) {
    return { action: "aligned", company_number: num, message: "ROA matches canonical Basingstoke" };
  }

  const etag = roa.body?.etag;
  if (!etag) throw new Error("missing_roa_etag");

  const token = await getAccessToken(env);
  const base = env.CH_API_BASE || "https://api.company-information.service.gov.uk";
  const auth = { authorization: `Bearer ${token}`, "content-type": "application/json" };

  const txnRes = await fetch(`${base}/transactions`, {
    method: "POST",
    headers: auth,
    body: JSON.stringify({ company_number: num }),
  });
  const txn = await txnRes.json();
  if (!txnRes.ok) throw new Error(`create_txn_${txnRes.status}:${JSON.stringify(txn)}`);
  const txnId = txn.id || txn.transaction_id;
  if (!txnId) throw new Error("missing_transaction_id");

  const roaBody = {
    accept_appropriate_office_address_statement: canonical.accept_appropriate_office_address_statement ?? true,
    premises: canonical.premises,
    address_line_1: canonical.address_line_1,
    address_line_2: canonical.address_line_2,
    locality: canonical.locality,
    region: canonical.region,
    postal_code: canonical.postal_code,
    country: canonical.country || "United Kingdom",
    reference_etag: etag,
  };
  const fileRes = await fetch(`${base}/transactions/${txnId}/registered-office-address`, {
    method: "POST",
    headers: auth,
    body: JSON.stringify(roaBody),
  });
  const fileBody = await fileRes.json();
  if (!fileRes.ok) throw new Error(`file_roa_${fileRes.status}:${JSON.stringify(fileBody)}`);

  const closeRes = await fetch(`${base}/transactions/${txnId}`, {
    method: "PUT",
    headers: auth,
    body: JSON.stringify({ status: "closed" }),
  });
  const closeBody = await closeRes.json();

  await env.CH_STATE.put(
    `ch:pending_txn:${txnId}`,
    JSON.stringify({
      company_number: num,
      kind: "registered_office_address",
      created_at: new Date().toISOString(),
      close_status: closeRes.status,
    })
  );

  return {
    action: "filed",
    company_number: num,
    transaction_id: txnId,
    close: { status: closeRes.status, body: closeBody },
  };
}

async function pollTransaction(env, txnId) {
  const token = await getAccessToken(env);
  const base = env.CH_API_BASE || "https://api.company-information.service.gov.uk";
  const res = await fetch(`${base}/transactions/${txnId}`, {
    headers: { authorization: `Bearer ${token}` },
  });
  const body = await res.json();
  return { status: res.status, body };
}

function authorizeInternal(request, env) {
  const expected = env.CH_WORKER_INTERNAL_TOKEN;
  if (!expected) return false;
  const header = request.headers.get("x-ch-worker-token") || "";
  const auth = request.headers.get("authorization") || "";
  if (header === expected) return true;
  if (auth === `Bearer ${expected}`) return true;
  return false;
}

async function handleOAuthCallback(request, env) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  if (!code) return json({ error: "missing_code" }, 400);

  const clientId = env.COMPANIES_HOUSE_OAUTH_CLIENT_ID;
  const clientSecret = env.COMPANIES_HOUSE_OAUTH_CLIENT_SECRET;
  const redirect =
    env.CH_OAUTH_REDIRECT_URI || "https://brmste.com/api/ch/oauth/callback";
  if (!clientId || !clientSecret) return json({ error: "missing_oauth_client" }, 500);

  const base = env.CH_IDENTITY_BASE || "https://identity.company-information.service.gov.uk";
  const body = new URLSearchParams({
    grant_type: "authorization_code",
    code,
    redirect_uri: redirect,
    client_id: clientId,
    client_secret: clientSecret,
  });
  const res = await fetch(`${base}/oauth/token`, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body,
  });
  const data = await res.json();
  if (!res.ok) return json({ error: "exchange_failed", detail: data }, res.status);

  await env.CH_KV.put(
    "ch:oauth",
    JSON.stringify({
      exchanged_at: new Date().toISOString(),
      state,
      expires_in: data.expires_in,
      scope: data.scope,
      note: "Update wrangler secrets COMPANIES_HOUSE_OAUTH_ACCESS_TOKEN and REFRESH_TOKEN from Mac",
    })
  );

  return json({
    status: "ok",
    message: "OAuth exchange OK — copy access_token and refresh_token to wrangler secrets on Mac",
    expires_in: data.expires_in,
    scope: data.scope,
    access_token_hint: data.access_token ? `${data.access_token.slice(0, 8)}…` : null,
  });
}

async function handleRequest(request, env) {
  const url = new URL(request.url);
  const path = url.pathname.replace(/^\/api\/ch/, "") || "/";

  if (path === "/health" || path === "/") {
    return json({
      worker: "brmste-companies-house-live",
      status: "live",
      routes: ["/api/ch/status", "/api/ch/sync", "/api/ch/file/brmste-roa", "/api/ch/oauth/callback"],
    });
  }

  if (path === "/status") {
    const bundle = await loadBundle(env);
    const lastSync = await env.CH_STATE.get("ch:sync:last");
    const lastStream = await env.CH_STATE.get("ch:stream:last_pull");
    return json({
      bundle_refreshed_at: bundle?.refreshed_at,
      brmste_status: bundle?.brmste?.register_status,
      last_sync: lastSync ? JSON.parse(lastSync) : null,
      last_stream_pull: lastStream ? JSON.parse(lastStream) : null,
      watch: [...watchSet(env)],
    });
  }

  if (path === "/oauth/callback") {
    return handleOAuthCallback(request, env);
  }

  if (path.startsWith("/company/")) {
    const num = path.split("/")[2];
    if (!num) return json({ error: "missing_company_number" }, 400);
    const kind = path.split("/")[3] || "profile";
    if (kind === "profile" || !path.split("/")[3]) {
      const r = await chGet(env, `/company/${num}`);
      return json(r.body, r.status);
    }
    if (kind === "registered-office-address") {
      const r = await chGet(env, `/company/${num}/registered-office-address`);
      return json(r.body, r.status);
    }
    if (kind === "filing-history") {
      const r = await chGet(env, `/company/${num}/filing-history?items_per_page=5`);
      return json(r.body, r.status);
    }
    return json({ error: "unknown_subpath" }, 404);
  }

  if (path === "/sync" && request.method === "POST") {
    if (!authorizeInternal(request, env)) return json({ error: "unauthorized" }, 401);
    const sync = await syncCompanyStatuses(env);
    const stream = await pullStreamFilings(env);
    return json({ sync, stream });
  }

  if (path === "/file/brmste-roa" && request.method === "POST") {
    if (!authorizeInternal(request, env)) return json({ error: "unauthorized" }, 401);
    try {
      const result = await fileBrmsteRoa(env);
      return json(result);
    } catch (e) {
      return json({ error: String(e?.message || e) }, 500);
    }
  }

  if (path.startsWith("/transaction/")) {
    const txnId = path.split("/")[2];
    if (!txnId) return json({ error: "missing_transaction_id" }, 400);
    if (!authorizeInternal(request, env)) return json({ error: "unauthorized" }, 401);
    try {
      const result = await pollTransaction(env, txnId);
      return json(result.body, result.status);
    } catch (e) {
      return json({ error: String(e?.message || e) }, 500);
    }
  }

  return json({ error: "not_found", path }, 404);
}

async function handleScheduled(event, env, ctx) {
  ctx.waitUntil(
    (async () => {
      try {
        await syncCompanyStatuses(env);
        await pullStreamFilings(env);
      } catch (e) {
        await env.CH_STATE.put(
          "ch:cron:last_error",
          JSON.stringify({ at: new Date().toISOString(), error: String(e?.message || e) })
        );
      }
    })()
  );
}

export default {
  async fetch(request, env, ctx) {
    try {
      return await handleRequest(request, env);
    } catch (e) {
      return json({ error: String(e?.message || e) }, 500);
    }
  },
  async scheduled(event, env, ctx) {
    return handleScheduled(event, env, ctx);
  },
};
