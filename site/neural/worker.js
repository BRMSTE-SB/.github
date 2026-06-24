// BRMSTE Brainstem · Non-Invasive Neural Edge — Cloudflare Worker.
// Serves the static edge console at the public route brmste.com/neural* without
// touching the main brmste.com SPA. Static files are uploaded via the [assets]
// binding (see wrangler.toml); this Worker only rewrites the /neural prefix.

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // brmste.com/neural        -> /index.html
    // brmste.com/neural/       -> /index.html
    // brmste.com/neural/app.js -> /app.js
    let path = url.pathname.replace(/^\/neural\/?/, "/");
    if (path === "/" || path === "") path = "/index.html";

    const assetRequest = new Request(new URL(path, url.origin), request);
    const res = await env.ASSETS.fetch(assetRequest);

    // Single-file SPA fallback: unknown sub-path returns the console.
    if (res.status === 404) {
      return env.ASSETS.fetch(new Request(new URL("/index.html", url.origin), request));
    }
    return res;
  },
};
