const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".webp": "image/webp",
  ".json": "application/json",
};

const SECURITY_HEADERS = {
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
  "X-BRMSTE-HTTPS-Truth": "enforced",
};

const HSTS_TRUTH = {
  header: "Strict-Transport-Security",
  value: SECURITY_HEADERS["Strict-Transport-Security"],
  max_age_seconds: 63072000,
  include_subdomains: true,
  preload: true,
};

const RETYRE_HOSTS = new Set(["re-tyre.com", "www.re-tyre.com"]);

const RETYRE_ENTITY = {
  name: "RE-TYRE FINANCE LTD",
  companiesHouse: "15310148",
  doctrine: "Carbon Justice = RE-TYRE LTD",
  edge: "https://re-tyre.com",
  api: "https://re-tyre.com/api/retyre",
};

const IP_ANCHOR_ADDRESS = "32i1m6gNcSHwiPX9nfTNXVjme9j5DU8y5g";
const IP_DOCTRINE = "1SAT = 1£";

const PAGES = {
  "/": { file: "/index.html", surface: "home" },
  "/brand": { file: "/brand.html", surface: "brand" },
  "/open": { file: "/open.html", surface: "open" },
  "/portfolio": { file: "/portfolio.html", surface: "portfolio" },
  "/broadcast": { file: "/broadcast.html", surface: "broadcast" },
  "/re-tyre": { file: "/re-tyre.html", surface: "re-tyre" },
  "/go-live": { file: "/go-live.html", surface: "go-live-cinematic" },
  "/on-chain": { file: "/on-chain.html", surface: "on-chain-cinematic" },
};

function extOf(pathname) {
  const i = pathname.lastIndexOf(".");
  return i === -1 ? "" : pathname.slice(i).toLowerCase();
}

function withHeaders(response, extra) {
  const headers = new Headers(response.headers);
  for (const [k, v] of Object.entries(SECURITY_HEADERS)) headers.set(k, v);
  if (extra) {
    for (const [k, v] of Object.entries(extra)) headers.set(k, v);
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function secureResponse(body, init = {}) {
  const headers = new Headers(init.headers ?? {});
  for (const [k, v] of Object.entries(SECURITY_HEADERS)) headers.set(k, v);
  return new Response(body, { ...init, headers });
}

function httpsRedirect(request) {
  const url = new URL(request.url);
  if (url.protocol !== "http:") return null;
  url.protocol = "https:";
  return secureResponse(null, {
    status: 308,
    headers: {
      Location: url.toString(),
      "Cache-Control": "no-store",
    },
  });
}

function normalizePath(pathname) {
  if (pathname !== "/" && pathname.endsWith("/")) {
    return pathname.slice(0, -1);
  }
  return pathname;
}

function jsonResponse(obj, status = 200, lane = "retyre-go-live") {
  const laneHeaders =
    lane === "ip-valuation-on-chain"
      ? {
          "X-BRMSTE-Cinematic": "active",
          "X-BRMSTE-Network": "bitcoin-mempool",
          "X-BRMSTE-Lane": "ip-valuation-on-chain",
        }
      : {
          "X-BRMSTE-Cinematic": "active",
          "X-BRMSTE-Network": "retyre-circular",
          "X-BRMSTE-Lane": "retyre-go-live",
        };

  return withHeaders(
    new Response(JSON.stringify(obj), {
      status,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "content-type",
      },
    }),
    laneHeaders,
  );
}

function formatGbp(amount) {
  return "£" + amount.toLocaleString("en-GB");
}

const IP_VALUATION_BASE = {
  schema: "brmste-ip-valuation/v1",
  patent_uk: "GB2607860",
  doctrine: { unit: IP_DOCTRINE },
  anchor: {
    network: "bitcoin-mainnet",
    address: IP_ANCHOR_ADDRESS,
    mempool_explorer: `https://mempool.space/address/${IP_ANCHOR_ADDRESS}`,
    brmste_console: "https://brmste.mempool.space/",
  },
  transfer_90_days: {
    days: 90,
    period_start: "2026-03-28",
    period_end: "2026-06-26",
    from: { name: "Shravan Bansal", role: "operator", brand: "Global Shravan Bansal Brand" },
    to: {
      name: "Kohinoor Bansal",
      role: "on_chain_recipient",
      machine: "THE KOHINOOR MAC",
    },
  },
  fellow_licensors: [
    {
      id: "siemens",
      name: "Siemens",
      lane: "BRMSTE-SIEMENS · industrial licensor lane",
      infra: { hetzner_ip: "46.224.23.51", project: "SIEMENS" },
    },
    {
      id: "porsche",
      name: "Porsche",
      lane: "Fellow licensor lane · automotive circular substrate",
      infra: null,
    },
  ],
  work_against_ip: [
    { id: "global_shravan_bansal_brand", title: "Global Shravan Bansal Brand", policy: "https://github.com/BRMSTE-SB/.github/blob/main/GLOBAL-SHRAVAN-BANSAL-BRAND.md" },
    { id: "project_glasswing", title: "Project Glasswing · Full Broadcast", policy: "https://github.com/BRMSTE-SB/.github/blob/main/PROJECT-GLASSWING.md" },
    { id: "re_tyre_cinematic", title: "Re-Tyre group · cinematic go-live", policy: "https://github.com/BRMSTE-SB/.github/blob/main/RE-TYRE.md" },
    { id: "mempool_foundry", title: "Mempool foundry anchor · valuation register", manifest: "https://github.com/BRMSTE-SB/.github/blob/main/data/hetzner/hydrated-logos.json" },
    { id: "hetzner_fleet", title: "Hetzner fleet · Siemens lane", manifest: "https://github.com/BRMSTE-SB/.github/blob/main/data/hetzner/servers.json" },
    { id: "thought_equity_portfolios", title: "AXP · BRK.B · AAPL · 100% sleeves", manifest: "https://github.com/BRMSTE-SB/.github/blob/main/data/portfolios/axp-brk-aapl-100.json" },
    { id: "open_all", title: "OPEN ALL · 7 public repos", manifest: "https://github.com/BRMSTE-SB/.github/blob/main/data/open-all.json" },
  ],
};

async function handleIpValuationApi(pathname, method) {
  if (method === "OPTIONS") {
    return secureResponse(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "content-type",
      },
    });
  }

  if (method !== "GET") {
    return jsonResponse({ error: "not_found" }, 404, "ip-valuation-on-chain");
  }

  const sub = pathname.slice("/api/ip-valuation".length) || "/";
  if (sub !== "/status") {
    return jsonResponse({ error: "not_found", path: sub }, 404, "ip-valuation-on-chain");
  }

  let chainStats = null;
  try {
    const chainRes = await fetch(`https://mempool.space/api/address/${IP_ANCHOR_ADDRESS}`);
    if (chainRes.ok) {
      chainStats = await chainRes.json();
    }
  } catch {
    chainStats = null;
  }

  const fundedSats = chainStats?.chain_stats?.funded_txo_sum ?? 601077282625;
  const txCount = chainStats?.chain_stats?.tx_count ?? 2081;
  const utxoCount = chainStats?.chain_stats?.funded_txo_count ?? 2081;

  return jsonResponse(
    {
      ok: true,
      service: "brmste-ip-valuation",
      cinematic: "90-days-shravan-to-kohinoor-on-chain",
      ...IP_VALUATION_BASE,
      valuation: {
        funded_satoshis: fundedSats,
        funded_btc: fundedSats / 1e8,
        valuation_gbp: fundedSats,
        valuation_gbp_formatted: formatGbp(fundedSats),
        utxo_count: utxoCount,
        tx_count: txCount,
        doctrine: IP_DOCTRINE,
        as_of: new Date().toISOString(),
        source: chainStats ? "mempool.space/api/address" : "manifest-fallback",
      },
      generatedAt: new Date().toISOString(),
    },
    200,
    "ip-valuation-on-chain",
  );
}

function handleRetyreApi(pathname, method) {
  if (method === "OPTIONS") {
    return secureResponse(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "content-type",
      },
    });
  }

  if (method !== "GET") {
    return jsonResponse({ error: "not_found" }, 404);
  }

  const sub = pathname.slice("/api/retyre".length) || "/";

  if (sub === "/status") {
    return jsonResponse({
      ok: true,
      service: "retyre-open-api",
      go_live: "cinematic",
      entity: RETYRE_ENTITY,
      modules: ["lease", "waste", "notes", "pay", "carbon"],
      stores: {
        ios: { bundleId: "ltd.retyre.justice", status: "testflight_ready" },
        android: { package: "ltd.retyre.justice", status: "play_internal_ready" },
      },
      substrate: "/substrate/re-tyre/apps.json",
      generatedAt: new Date().toISOString(),
    });
  }

  if (sub === "/carbon" || sub.startsWith("/carbon/")) {
    return jsonResponse({
      module: "carbon-justice",
      doctrine: RETYRE_ENTITY.doctrine,
      ledger: {
        totalKgAvoided: 128400,
        tyresRecovered: 4820,
        attestations: 12,
        period: "2026-H1",
      },
      entity: RETYRE_ENTITY.name,
    });
  }

  return jsonResponse({ error: "not_found", path: sub }, 404);
}

async function servePage(env, request, page) {
  const pageResponse = await env.ASSETS.fetch(new URL(page.file, request.url));
  if (pageResponse.status === 404 || !pageResponse.ok) {
    return secureResponse("", { status: 404 });
  }
  return withHeaders(pageResponse, {
    "Content-Type": "text/html; charset=utf-8",
    "Cache-Control": "no-store",
    "X-BRMSTE-Surface": page.surface,
    "X-BRMSTE-Cinematic": page.surface.includes("cinematic") ? "active" : "lane",
  });
}

export default {
  async fetch(request, env) {
    try {
      const redirect = httpsRedirect(request);
      if (redirect) return redirect;

      const url = new URL(request.url);
      const hostname = url.hostname.toLowerCase();
      const pathname = decodeURIComponent(normalizePath(url.pathname));

      if (pathname === "/health") {
        return withHeaders(
          new Response(
            JSON.stringify({
              ok: true,
              port: 3033,
              page: env.BRMSTE_PAGE ?? "brmste-site-v1",
              cinematic: "re-tyre-go-live",
              on_chain: "90-days-shravan-to-kohinoor",
              https: true,
              hsts: HSTS_TRUTH,
            }),
            { headers: { "Content-Type": "application/json" } },
          ),
        );
      }

      if (pathname.startsWith("/api/ip-valuation")) {
        return handleIpValuationApi(pathname, request.method);
      }

      if (pathname.startsWith("/api/retyre")) {
        return handleRetyreApi(pathname, request.method);
      }

      if (pathname.startsWith("/public/")) {
        const assetResponse = await env.ASSETS.fetch(request);
        if (assetResponse.status === 404 || !assetResponse.ok) {
          return secureResponse("", { status: 404 });
        }
        const mime = MIME[extOf(pathname)] || "application/octet-stream";
        return withHeaders(assetResponse, {
          "Content-Type": mime,
          "Cache-Control": "public, max-age=3600",
        });
      }

      if (RETYRE_HOSTS.has(hostname) && pathname === "/") {
        return servePage(env, request, PAGES["/go-live"]);
      }

      const page = PAGES[pathname];
      if (page) {
        return servePage(env, request, page);
      }

      return secureResponse("", { status: 404 });
    } catch {
      return secureResponse("Internal error", {
        status: 500,
        headers: { "Content-Type": "text/plain" },
      });
    }
  },
};
