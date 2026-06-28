import { valuationFromPnlResponse } from "./lib/networth.js";

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
};

const PAGES = {
  "/": { file: "/index.html", surface: "home" },
  "/brand": { file: "/brand.html", surface: "brand" },
  "/open": { file: "/open.html", surface: "open" },
  "/portfolio": { file: "/portfolio.html", surface: "portfolio" },
  "/banking": { file: "/banking.html", surface: "banking" },
  "/companies-house": { file: "/companies-house.html", surface: "companies-house" },
  "/broadcast": { file: "/broadcast.html", surface: "broadcast" },
  "/carbon-justice": { file: "/carbon-justice.html", surface: "carbon-justice" },
};

const ETORO_BASE_URL = "https://public-api.etoro.com/api/v1";
const CARBON_JUSTICE_HOSTS = new Set(["carbonjustice.uk", "www.carbonjustice.uk"]);

function isCarbonJusticeHost(hostname) {
  return CARBON_JUSTICE_HOSTS.has(hostname.toLowerCase());
}

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

function normalizePath(pathname) {
  if (pathname !== "/" && pathname.endsWith("/")) {
    return pathname.slice(0, -1);
  }
  return pathname;
}

function jsonResponse(body, status = 200, extra = {}) {
  return withHeaders(
    new Response(JSON.stringify(body), {
      status,
      headers: { "Content-Type": "application/json" },
    }),
    { "Cache-Control": "no-store", ...extra },
  );
}

function requestId() {
  return crypto.randomUUID();
}

const BANKING_ENVIRONMENT = "real";

async function fetchNetworthValuation(env) {
  const apiKey = env.ETORO_API_KEY;
  const userKey = env.ETORO_USER_KEY;
  if (!apiKey || !userKey) {
    return {
      error: true,
      status: 503,
      body: {
        ok: false,
        liveOnly: true,
        message:
          "Banking valuation is live-only. Configure ETORO_API_KEY and ETORO_USER_KEY on the brmste-com-coming-soon worker.",
        manifest: "/public/banking/networth-valuation.json",
      },
    };
  }

  const environment = env.ETORO_ENV || BANKING_ENVIRONMENT;

  const pnlResponse = await fetch(
    `${ETORO_BASE_URL}/trading/info/${environment}/pnl`,
    {
      headers: {
        "x-api-key": apiKey,
        "x-user-key": userKey,
        "x-request-id": requestId(),
      },
    },
  );

  if (!pnlResponse.ok) {
    const detail =
      pnlResponse.status === 401
        ? "eToro credentials rejected — check real-environment API keys"
        : pnlResponse.status === 403
          ? "Insufficient permissions — banking requires real-environment keys"
          : `eToro PnL request failed (HTTP ${pnlResponse.status})`;
    return {
      error: true,
      status: pnlResponse.status === 429 ? 429 : 502,
      body: { ok: false, liveOnly: true, message: detail, environment },
    };
  }

  const payload = await pnlResponse.json();
  return {
    error: false,
    body: valuationFromPnlResponse(payload, { environment }),
  };
}

export default {
  async fetch(request, env) {
    try {
      const url = new URL(request.url);
      const pathname = decodeURIComponent(normalizePath(url.pathname));
      const hostname = url.hostname.toLowerCase();
      const carbonJusticeSite = isCarbonJusticeHost(hostname);

      if (pathname === "/health") {
        return withHeaders(
          new Response(
            JSON.stringify({
              ok: true,
              port: 3033,
              page: env.BRMSTE_PAGE ?? "brmste-site-v1",
              surfaces: Object.values(PAGES).map((p) => p.surface),
              banking: {
                liveOnly: true,
                environment: BANKING_ENVIRONMENT,
                configured: Boolean(env.ETORO_API_KEY && env.ETORO_USER_KEY),
                rails: {
                  trading: "etoro",
                  fiat: "hsbc-uk",
                  settlement: "coinbase",
                },
              },
              ...(carbonJusticeSite ? { domain: "carbonjustice.uk", surface: "carbon-justice" } : {}),
            }),
            { headers: { "Content-Type": "application/json" } },
          ),
        );
      }

      if (pathname === "/api/banking/networth") {
        const result = await fetchNetworthValuation(env);
        if (result.error) {
          return jsonResponse(result.body, result.status, {
            "X-BRMSTE-Surface": "banking-api",
          });
        }
        return jsonResponse(result.body, 200, {
          "X-BRMSTE-Surface": "banking-api",
        });
      }

      if (pathname.startsWith("/public/")) {
        const assetResponse = await env.ASSETS.fetch(request);
        if (assetResponse.status === 404 || !assetResponse.ok) {
          return new Response("", { status: 404, headers: SECURITY_HEADERS });
        }
        const mime = MIME[extOf(pathname)] || "application/octet-stream";
        return withHeaders(assetResponse, {
          "Content-Type": mime,
          "Cache-Control": "public, max-age=3600",
        });
      }

      const page =
        pathname === "/" && carbonJusticeSite
          ? { file: "/carbon-justice.html", surface: "carbon-justice" }
          : PAGES[pathname];
      if (page) {
        const pageResponse = await env.ASSETS.fetch(
          new URL(page.file, request.url),
        );
        if (pageResponse.status === 404 || !pageResponse.ok) {
          return new Response("", { status: 404, headers: SECURITY_HEADERS });
        }
        return withHeaders(pageResponse, {
          "Content-Type": "text/html; charset=utf-8",
          "Cache-Control": "no-store",
          "X-BRMSTE-Surface": page.surface,
        });
      }

      return new Response("", { status: 404, headers: SECURITY_HEADERS });
    } catch {
      return new Response("Internal error", {
        status: 500,
        headers: { "Content-Type": "text/plain", ...SECURITY_HEADERS },
      });
    }
  },
};
