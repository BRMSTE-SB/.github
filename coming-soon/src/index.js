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
  "/broadcast": { file: "/broadcast.html", surface: "broadcast" },
  "/shravan-bansal": { file: "/shravan-bansal.html", surface: "operator" },
};

// Root SEO files served verbatim with explicit content types.
const ROOT_FILES = {
  "/robots.txt": "text/plain; charset=utf-8",
  "/sitemap.xml": "application/xml; charset=utf-8",
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

export default {
  async fetch(request, env) {
    try {
      const url = new URL(request.url);
      const pathname = decodeURIComponent(normalizePath(url.pathname));

      if (pathname === "/health") {
        return withHeaders(
          new Response(
            JSON.stringify({
              ok: true,
              port: 3033,
              page: env.BRMSTE_PAGE ?? "brmste-site-v1",
            }),
            { headers: { "Content-Type": "application/json" } },
          ),
        );
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

      const rootFileType = ROOT_FILES[pathname];
      if (rootFileType) {
        const assetResponse = await env.ASSETS.fetch(
          new URL(pathname, request.url),
        );
        if (assetResponse.status === 404 || !assetResponse.ok) {
          return new Response("", { status: 404, headers: SECURITY_HEADERS });
        }
        return withHeaders(assetResponse, {
          "Content-Type": rootFileType,
          "Cache-Control": "public, max-age=3600",
        });
      }

      const page = PAGES[pathname];
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
