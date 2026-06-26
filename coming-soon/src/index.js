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

const RETYRE_HOSTS = new Set(["re-tyre.com", "www.re-tyre.com"]);

const RETYRE_ENTITY = {
  name: "RE-TYRE FINANCE LTD",
  companiesHouse: "15310148",
  doctrine: "Carbon Justice = RE-TYRE LTD",
  edge: "https://re-tyre.com",
  api: "https://re-tyre.com/api/retyre",
};

const PAGES = {
  "/": { file: "/index.html", surface: "home" },
  "/brand": { file: "/brand.html", surface: "brand" },
  "/open": { file: "/open.html", surface: "open" },
  "/portfolio": { file: "/portfolio.html", surface: "portfolio" },
  "/broadcast": { file: "/broadcast.html", surface: "broadcast" },
  "/re-tyre": { file: "/re-tyre.html", surface: "re-tyre" },
  "/go-live": { file: "/go-live.html", surface: "go-live-cinematic" },
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

function normalizePath(pathname) {
  if (pathname !== "/" && pathname.endsWith("/")) {
    return pathname.slice(0, -1);
  }
  return pathname;
}

function jsonResponse(obj, status = 200) {
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
    {
      "X-BRMSTE-Cinematic": "active",
      "X-BRMSTE-Network": "retyre-circular",
      "X-BRMSTE-Lane": "retyre-go-live",
    },
  );
}

function handleRetyreApi(pathname, method) {
  if (method === "OPTIONS") {
    return new Response(null, {
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
    return new Response("", { status: 404, headers: SECURITY_HEADERS });
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
            }),
            { headers: { "Content-Type": "application/json" } },
          ),
        );
      }

      if (pathname.startsWith("/api/retyre")) {
        return handleRetyreApi(pathname, request.method);
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

      if (RETYRE_HOSTS.has(hostname) && pathname === "/") {
        return servePage(env, request, PAGES["/go-live"]);
      }

      const page = PAGES[pathname];
      if (page) {
        return servePage(env, request, page);
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
