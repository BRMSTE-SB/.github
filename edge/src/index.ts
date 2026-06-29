/**
 * BRMSTE Edge — Cloudflare Workers entry point
 *
 * BRMSTE LTD · Companies House 15310393
 * Patent: GB2607860 · PCT/GB2026/050406
 * Title:  Traceable ELT infrastructure · BRMSTE substrate edge
 *
 * A small, fully-typed, dependency-free Worker that serves the BRMSTE
 * substrate-edge surfaces. It is deterministic (no required upstream calls)
 * so it type-checks, unit-tests, and deploys cleanly via `npm` + Wrangler.
 *
 * Every response enforces HTTPS / HSTS.
 * CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS
 */

const HSTS = "max-age=31536000; includeSubDomains; preload";

const SECURITY_HEADERS: Readonly<Record<string, string>> = {
  "Strict-Transport-Security": HSTS,
  "X-Frame-Options": "DENY",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
  "X-BRMSTE-Patent": "GB2607860",
  "X-BRMSTE-PCT": "PCT/GB2026/050406",
};

const CSP =
  "default-src 'self' https://brmste.com https://brmste.ai " +
  "https://raw.githubusercontent.com/BRMSTE-SB/; " +
  "style-src 'self' 'unsafe-inline'; " +
  "img-src 'self' https://brmste.com https://brmste.ai " +
  "https://raw.githubusercontent.com/BRMSTE-SB/; " +
  "script-src 'none'; frame-ancestors 'none';";

/**
 * Worker bindings. Plain `vars` are declared in `wrangler.toml`; the optional
 * secret is provisioned with `wrangler secret put` and is NEVER committed
 * (see ../../SECURITY.md).
 */
export interface Env {
  BRMSTE_ENTITY: string;
  BRMSTE_PATENT: string;
  BRMSTE_ENV: string;
  /** Optional — only set if a private upstream ever needs auth. */
  MEMPOOL_API_KEY?: string;
}

const PATENT = {
  entity: "BRMSTE LTD",
  companies_house: "15310393",
  patents: [
    { jurisdiction: "UK", number: "GB2607860", granted: "2023-10-11", status: "granted" },
    { jurisdiction: "PCT", number: "PCT/GB2026/050406", status: "pending" },
  ],
  title: "Traceable ELT infrastructure · BRMSTE substrate edge",
  beneficiary: "Dimpy Bansal · Dimpy Bansal Trust",
  operator: "Shravan Bansal · BRMSTE LTD",
  trademark: ["BRMSTE™", "GSI™", "Global Substrate Infrastructure™", "Re-Tyre™"],
  enforcement_active: true,
  human_lane_free: true,
  ai_commercial_requires_licence: true,
  licence_url: "https://brmste.com/foundry/license.json",
  contact: "sb@brmste.com",
  security: "security@brmste.ai",
} as const;

function withSecurityHeaders(response: Response): Response {
  const r = new Response(response.body, response);
  for (const [k, v] of Object.entries(SECURITY_HEADERS)) {
    r.headers.set(k, v);
  }
  r.headers.set("Content-Security-Policy", CSP);
  return r;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { "Content-Type": "application/json;charset=utf-8" },
  });
}

function homePage(env: Env): Response {
  const page = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>BRMSTE Edge · CF Workers</title>
  <style>
    :root{--gold:#d4af37;--green:#10b981;--dark:#07101f;--mid:#0c1829;--text:#e2e8f0}
    *{box-sizing:border-box;margin:0;padding:0}
    body{background:var(--dark);color:var(--text);font-family:system-ui,sans-serif;line-height:1.7;padding:2rem 1rem}
    .wrap{max-width:760px;margin:0 auto}
    header{border-bottom:1px solid var(--gold);padding-bottom:1.25rem;margin-bottom:1.5rem;display:flex;align-items:center;gap:1.25rem}
    header img{height:48px}
    h1{color:var(--gold);font-size:1.4rem}
    a{color:var(--green)}
    table{width:100%;border-collapse:collapse;margin:1rem 0}
    th{background:var(--mid);color:var(--gold);text-align:left;padding:.5rem .75rem;font-size:.85rem}
    td{padding:.45rem .75rem;border-bottom:1px solid #1e293b;font-size:.9rem}
    footer{margin-top:2rem;padding-top:1rem;border-top:1px solid #1e293b;font-size:.8rem;color:#64748b}
  </style>
</head>
<body><div class="wrap">
  <header>
    <img src="https://brmste.com/substrate/glasses/brmste-logo-primary.svg" alt="BRMSTE"/>
    <h1>BRMSTE Edge · Cloudflare Workers</h1>
  </header>
  <p>Substrate edge runtime for <strong>BRMSTE LTD</strong> (Companies House 15310393).
  HTTPS / HSTS enforced on every response.</p>
  <table>
    <thead><tr><th>Surface</th><th>Path</th></tr></thead>
    <tbody>
      <tr><td>Health</td><td><a href="/healthz">/healthz</a></td></tr>
      <tr><td>Edge manifest</td><td><a href="/substrate/edge.json">/substrate/edge.json</a></td></tr>
      <tr><td>Patent enforcement</td><td><a href="/substrate/patent-enforcement.json">/substrate/patent-enforcement.json</a></td></tr>
    </tbody>
  </table>
  <footer>
    © BRMSTE LTD · Companies House 15310393 · Patent GB2607860 · PCT/GB2026/050406 · env=${env.BRMSTE_ENV}<br/>
    CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS
  </footer>
</div></body>
</html>`;
  return new Response(page, { headers: { "Content-Type": "text/html;charset=utf-8" } });
}

function healthz(env: Env): Response {
  return json({
    status: "ok",
    service: "brmste-edge",
    entity: env.BRMSTE_ENTITY,
    patent: env.BRMSTE_PATENT,
    env: env.BRMSTE_ENV,
    time: new Date().toISOString(),
  });
}

function edgeManifest(env: Env): Response {
  return json({
    service: "brmste-edge",
    runtime: "cloudflare-workers",
    entity: env.BRMSTE_ENTITY,
    env: env.BRMSTE_ENV,
    hsts: HSTS,
    surfaces: ["/", "/healthz", "/substrate/edge.json", "/substrate/patent-enforcement.json"],
    patent: { uk: "GB2607860", pct: "PCT/GB2026/050406" },
    updated: new Date().toISOString(),
  });
}

function notFound(): Response {
  return json({ error: "not_found", entity: "BRMSTE LTD", patent: "GB2607860" }, 404);
}

export default {
  fetch(request: Request, env: Env): Response {
    const url = new URL(request.url);

    // Redirect HTTP → HTTPS.
    if (url.protocol === "http:") {
      url.protocol = "https:";
      return withSecurityHeaders(Response.redirect(url.toString(), 301));
    }

    let response: Response;
    switch (url.pathname) {
      case "/":
      case "":
        response = homePage(env);
        break;
      case "/healthz":
        response = healthz(env);
        break;
      case "/substrate/edge.json":
        response = edgeManifest(env);
        break;
      case "/substrate/patent-enforcement.json":
        response = json({ ...PATENT, env: env.BRMSTE_ENV, updated: new Date().toISOString() });
        break;
      default:
        response = notFound();
    }

    return withSecurityHeaders(response);
  },
} satisfies ExportedHandler<Env>;
