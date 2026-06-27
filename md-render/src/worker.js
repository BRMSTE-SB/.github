// BRMSTE branded MD render — Cloudflare Worker (edge + HSTS)
// BRMSTE LTD · Companies House 15310393 · GB2607860
//
// Serves the pre-rendered dist/ via ASSETS. Mount at /docs on brmste.com / brmste.ai.

import { SECURITY_HEADERS, contentType } from "../headers.mjs";

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

function stripDocsPrefix(pathname) {
  if (pathname === "/docs") return "/";
  if (pathname.startsWith("/docs/")) return pathname.slice(5) || "/";
  return pathname;
}

export default {
  async fetch(request, env) {
    try {
      const url = new URL(request.url);
      const assetPath = stripDocsPrefix(url.pathname);

      if (assetPath === "/health" || assetPath === "/healthz") {
        return withHeaders(
          new Response(
            JSON.stringify({
              ok: true,
              service: "brmste-md-render",
              page: env.BRMSTE_PAGE ?? "brmste-md-render-v1",
              edge: "cloudflare",
            }),
            { headers: { "Content-Type": "application/json" } },
          ),
        );
      }

      const assetUrl = new URL(assetPath === "/" ? "/index.html" : assetPath, request.url);
      const assetResponse = await env.ASSETS.fetch(new Request(assetUrl, request));

      if (assetResponse.status === 404 || !assetResponse.ok) {
        const fallback = await env.ASSETS.fetch(new URL("/index.html", request.url));
        if (fallback.ok) {
          return withHeaders(fallback, {
            "Content-Type": "text/html; charset=utf-8",
            "Cache-Control": "public, max-age=300",
          });
        }
        return new Response("", { status: 404, headers: SECURITY_HEADERS });
      }

      return withHeaders(assetResponse, {
        "Content-Type": contentType(assetPath),
        "Cache-Control": assetPath.endsWith(".html") || assetPath === "/index.html"
          ? "public, max-age=300"
          : "public, max-age=3600",
      });
    } catch {
      return new Response("Internal error", {
        status: 500,
        headers: { "Content-Type": "text/plain", ...SECURITY_HEADERS },
      });
    }
  },
};
