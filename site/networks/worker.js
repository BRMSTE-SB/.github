/**
 * BRMSTE Networks standalone edge worker.
 *
 * Serves the self-contained BRMSTE Networks page at `brmste.com/networks`
 * WITHOUT touching the main brmste.com SPA and WITHOUT any binding. The page
 * HTML is inlined via `canonical-route.js` (generated from `index.html`), so
 * there is no ASSETS / KV / D1 / R2 dependency and nothing in this folder is
 * ever published as a public file.
 *
 * Bound to the route `brmste.com/networks*` (see wrangler.toml), this worker
 * intercepts those requests at Cloudflare's edge before they reach the SPA
 * origin. The page pulls live Bitcoin/Lightning data client-side from
 * mempool.space (CORS-enabled), so the worker only needs to return the HTML.
 */
import { handleNetworks } from "./canonical-route.js";

export default {
  async fetch(request) {
    return handleNetworks(request) || new Response("Not found", { status: 404 });
  },
};
