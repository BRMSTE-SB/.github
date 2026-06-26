// BRMSTE branded MD render — origin server (Hetzner nodes)
// BRMSTE LTD · Companies House 15310393 · GB2607860
//
// Zero-dependency static server for dist/. Applies HSTS + security headers to
// every response so the policy holds even on direct-to-origin requests.
// Binds 0.0.0.0:$PORT; Cloudflare proxies it and also enforces HSTS at the edge.

import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { join, normalize, dirname } from "node:path";
import { SECURITY_HEADERS, contentType } from "./headers.mjs";

const HERE = dirname(new URL(import.meta.url).pathname);
const DIST = process.env.MD_RENDER_DIST || join(HERE, "dist");
const PORT = Number(process.env.PORT) || 8787;
const HOST = process.env.HOST || "0.0.0.0";

// Prevent path traversal: resolve under DIST or reject.
export function safeJoin(root, urlPath) {
  const clean = normalize(decodeURIComponent(urlPath.split("?")[0]));
  const full = join(root, clean);
  if (full !== root && !full.startsWith(root + "/")) return null;
  return full;
}

function send(res, status, body, headers = {}) {
  res.writeHead(status, { ...SECURITY_HEADERS, ...headers });
  res.end(body);
}

export async function handle(req, res) {
  const url = req.url || "/";
  if (url === "/healthz") {
    return send(res, 200, JSON.stringify({ ok: true, service: "brmste-md-render" }), {
      "Content-Type": "application/json; charset=utf-8",
    });
  }

  let target = url === "/" ? join(DIST, "index.html") : safeJoin(DIST, url);
  if (!target) return send(res, 403, "Forbidden", { "Content-Type": "text/plain" });

  try {
    const info = await stat(target);
    if (info.isDirectory()) target = join(target, "index.html");
    const data = await readFile(target);
    return send(res, 200, data, {
      "Content-Type": contentType(target),
      "Cache-Control": "public, max-age=300",
    });
  } catch {
    // SPA-style fallback to the single rendered page.
    try {
      const data = await readFile(join(DIST, "index.html"));
      return send(res, 200, data, { "Content-Type": "text/html; charset=utf-8" });
    } catch {
      return send(res, 404, "Not found", { "Content-Type": "text/plain" });
    }
  }
}

export function startServer() {
  const server = createServer(handle);
  server.listen(PORT, HOST, () => {
    console.log(`brmste-md-render serving ${DIST} on http://${HOST}:${PORT}`);
  });
  return server;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  startServer();
}
