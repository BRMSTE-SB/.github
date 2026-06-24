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

export default {
  async fetch(request, env) {
    try {
      const url = new URL(request.url);
      const pathname = decodeURIComponent(url.pathname);

      if (pathname === "/health") {
        return withHeaders(
          new Response(
            JSON.stringify({
              ok: true,
              port: 3033,
              page: env.BRMSTE_PAGE ?? "brmste-coming-soon-v3",
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

      if (pathname === "/portfolio" || pathname === "/portfolio/") {
        const pageResponse = await env.ASSETS.fetch(
          new URL("/portfolio.html", request.url),
        );
        if (pageResponse.status === 404 || !pageResponse.ok) {
          return new Response("", { status: 404, headers: SECURITY_HEADERS });
        }
        return withHeaders(pageResponse, {
          "Content-Type": "text/html; charset=utf-8",
          "Cache-Control": "no-store",
          "X-BRMSTE-Surface": "portfolio",
        });
      }

      const pagePath =
        pathname === "/brand" || pathname === "/brand/"
          ? "/brand.html"
          : "/index.html";
      const surface =
        pagePath === "/brand.html" ? "brand" : "coming-soon";

      const pageResponse = await env.ASSETS.fetch(
        new URL(pagePath, request.url),
      );
      if (pageResponse.status === 404 || !pageResponse.ok) {
        return new Response("", { status: 404, headers: SECURITY_HEADERS });
      }
      return withHeaders(pageResponse, {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "no-store",
        "X-BRMSTE-Surface": surface,
      });
    } catch {
      return new Response("Internal error", {
        status: 500,
        headers: { "Content-Type": "text/plain", ...SECURITY_HEADERS },
      });
    }
  },
};
