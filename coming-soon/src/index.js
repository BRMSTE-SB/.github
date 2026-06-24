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

/** Hostnames that serve Leading Metals green ops at apex (not generic coming-soon). */
const LEADING_METALS_HOSTS = new Set([
  "leadingmetals.com",
  "www.leadingmetals.com",
]);

function extOf(pathname) {
  const i = pathname.lastIndexOf(".");
  return i === -1 ? "" : pathname.slice(i).toLowerCase();
}

function normalizeHost(hostname) {
  return (hostname || "").toLowerCase().split(":")[0];
}

function isLeadingMetalsHost(hostname) {
  return LEADING_METALS_HOSTS.has(normalizeHost(hostname));
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

async function serveAsset(env, request, pathname) {
  const assetResponse = await env.ASSETS.fetch(
    new Request(new URL(pathname, request.url).toString(), request),
  );
  if (assetResponse.status === 404 || !assetResponse.ok) {
    return null;
  }
  const mime = MIME[extOf(pathname)] || "application/octet-stream";
  return withHeaders(assetResponse, {
    "Content-Type": mime,
    "Cache-Control": "public, max-age=3600",
  });
}

async function serveTickers(env, request) {
  const tickerRequest = new URL("/public/data/ad-leading-lse.json", request.url);
  const tickerResponse = await env.ASSETS.fetch(
    new Request(tickerRequest.toString(), request),
  );
  if (tickerResponse.ok) {
    return withHeaders(tickerResponse, {
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=300",
      "X-BRMSTE-Surface": "leadingmetals-tickers",
    });
  }
  return withHeaders(
    new Response(JSON.stringify({ error: "ticker manifest not found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    }),
  );
}

async function serveHtml(env, request, pagePath, surface) {
  const pageResponse = await env.ASSETS.fetch(new URL(pagePath, request.url));
  if (pageResponse.status === 404 || !pageResponse.ok) {
    return new Response("", { status: 404, headers: SECURITY_HEADERS });
  }
  return withHeaders(pageResponse, {
    "Content-Type": "text/html; charset=utf-8",
    "Cache-Control": "no-store",
    "X-BRMSTE-Surface": surface,
  });
}

function healthJson(env, host) {
  const page = env.BRMSTE_PAGE ?? "brmste-coming-soon-v5";
  const leadingMetals = isLeadingMetalsHost(host);
  return JSON.stringify({
    ok: true,
    port: 3033,
    page,
    host: normalizeHost(host),
    surface: leadingMetals ? "leadingmetals" : "coming-soon",
    edge: "cloudflare-workers",
  });
}

function resolveDefaultPage(pathname, hostname) {
  if (isLeadingMetalsHost(hostname)) {
    return { pagePath: "/leadingmetals.html", surface: "leadingmetals" };
  }
  if (pathname === "/brand" || pathname === "/brand/") {
    return { pagePath: "/brand.html", surface: "brand" };
  }
  if (pathname === "/leadingmetals" || pathname === "/leadingmetals/") {
    return { pagePath: "/leadingmetals.html", surface: "leadingmetals" };
  }
  return { pagePath: "/index.html", surface: "coming-soon" };
}

export default {
  async fetch(request, env) {
    try {
      const url = new URL(request.url);
      const pathname = decodeURIComponent(url.pathname);
      const host = normalizeHost(url.hostname);

      if (pathname === "/health") {
        return withHeaders(
          new Response(healthJson(env, host), {
            headers: { "Content-Type": "application/json" },
          }),
        );
      }

      if (pathname.startsWith("/public/")) {
        const asset = await serveAsset(env, request, pathname);
        return asset ?? new Response("", { status: 404, headers: SECURITY_HEADERS });
      }

      if (pathname === "/api/gi/leadingmetals/tickers") {
        return await serveTickers(env, request);
      }

      const { pagePath, surface } = resolveDefaultPage(pathname, host);
      return await serveHtml(env, request, pagePath, surface);
    } catch {
      return new Response("Internal error", {
        status: 500,
        headers: { "Content-Type": "text/plain", ...SECURITY_HEADERS },
      });
    }
  },
};
