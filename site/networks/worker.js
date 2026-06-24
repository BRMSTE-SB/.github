/**
 * BRMSTE Networks edge worker.
 *
 * Serves the self-contained BRMSTE Networks page at `brmste.com/networks`
 * WITHOUT touching the main brmste.com SPA. Because this worker is bound to the
 * route `brmste.com/networks*` (see wrangler.toml), it intercepts those requests
 * at Cloudflare's edge before they reach the SPA origin.
 *
 * The page itself is static and pulls live Bitcoin/Lightning data client-side
 * from mempool.space (CORS-enabled), so this worker only needs to serve assets.
 */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Normalise the /networks route to the page, and map any sub-asset request
    // (e.g. future /networks/foo.css) onto the asset directory.
    if (url.pathname === "/networks" || url.pathname === "/networks/") {
      url.pathname = "/index.html";
    } else {
      url.pathname = url.pathname.replace(/^\/networks/, "") || "/index.html";
    }

    const res = await env.ASSETS.fetch(new Request(url, request));
    // Keep the live page fresh but cacheable at the edge for a short window.
    const headers = new Headers(res.headers);
    if (!headers.has("cache-control")) {
      headers.set("cache-control", "public, max-age=60, stale-while-revalidate=300");
    }
    return new Response(res.body, { status: res.status, headers });
  },
};
