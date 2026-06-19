/**
 * BRMSTE GSI — Global Substrate Infrastructure™
 * Cloudflare Worker · Whitepaper & Substrate Surface Deployment
 *
 * BRMSTE LTD · Companies House 15310393
 * Patent: GB2607860 · PCT/GB2026/050406
 * Beneficiary: Dimpy Bansal · Dimpy Bansal Trust
 *
 * All responses enforce HTTPS / HSTS (max-age=31536000; includeSubDomains; preload)
 * CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS
 */

const HSTS = "max-age=31536000; includeSubDomains; preload";

const SECURITY_HEADERS: Record<string, string> = {
  "Strict-Transport-Security": HSTS,
  "X-Frame-Options": "DENY",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
  "X-BRMSTE-Patent": "GB2607860",
  "X-BRMSTE-PCT": "PCT/GB2026/050406",
  "X-GSI-Division": "Global-Substrate-Infrastructure",
};

const CSP =
  "default-src 'self' https://brmste.com https://brmste.ai " +
  "https://raw.githubusercontent.com/BRMSTE-SB/; " +
  "style-src 'self' 'unsafe-inline'; " +
  "img-src 'self' https://brmste.com https://brmste.ai " +
  "https://raw.githubusercontent.com/BRMSTE-SB/ https://img.shields.io; " +
  "script-src 'none'; frame-ancestors 'none';";

function withSecurityHeaders(response: Response): Response {
  const r = new Response(response.body, response);
  for (const [k, v] of Object.entries(SECURITY_HEADERS)) {
    r.headers.set(k, v);
  }
  r.headers.set("Content-Security-Policy", CSP);
  return r;
}

function html(title: string, body: string): Response {
  const page = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>${title} · BRMSTE GSI™</title>
  <style>
    :root{--gold:#d4af37;--green:#10b981;--dark:#07101f;--mid:#0c1829;--text:#e2e8f0}
    *{box-sizing:border-box;margin:0;padding:0}
    body{background:var(--dark);color:var(--text);font-family:system-ui,sans-serif;line-height:1.7;padding:2rem 1rem}
    .wrap{max-width:860px;margin:0 auto}
    header{border-bottom:1px solid var(--gold);padding-bottom:1.5rem;margin-bottom:2rem;display:flex;align-items:center;gap:1.5rem}
    header img{height:56px}
    h1{color:var(--gold);font-size:1.6rem}
    h2{color:var(--gold);margin:2rem 0 .75rem;font-size:1.25rem}
    h3{color:var(--green);margin:1.5rem 0 .5rem;font-size:1rem}
    a{color:var(--green)}
    a:hover{color:var(--gold)}
    table{width:100%;border-collapse:collapse;margin:1rem 0}
    th{background:var(--mid);color:var(--gold);text-align:left;padding:.5rem .75rem;font-size:.85rem}
    td{padding:.45rem .75rem;border-bottom:1px solid #1e293b;font-size:.9rem}
    code{background:#1e293b;padding:.15rem .4rem;border-radius:4px;font-size:.85rem;font-family:monospace}
    pre{background:#1e293b;padding:1rem;border-radius:6px;overflow-x:auto;font-size:.85rem}
    .badge{display:inline-block;padding:.25rem .7rem;border-radius:9999px;font-size:.75rem;font-weight:700;margin:.15rem}
    .badge-gold{background:#78350f;color:var(--gold)}
    .badge-green{background:#064e3b;color:var(--green)}
    .badge-dark{background:var(--mid);color:var(--text)}
    footer{margin-top:3rem;padding-top:1.5rem;border-top:1px solid #1e293b;font-size:.8rem;color:#64748b}
    nav{margin-bottom:2rem}
    nav a{margin-right:1rem}
    .card{background:var(--mid);border:1px solid #1e293b;border-radius:8px;padding:1.25rem;margin:.75rem 0}
    .patent-bar{background:#1e293b;border-left:3px solid var(--gold);padding:.75rem 1rem;margin:1.5rem 0;font-size:.85rem}
  </style>
</head>
<body>
<div class="wrap">
  <header>
    <img src="https://brmste.com/substrate/glasses/brmste-logo-primary.svg" alt="BRMSTE"/>
    <div>
      <h1>${title}</h1>
      <div>
        <span class="badge badge-gold">BRMSTE LTD · 15310393</span>
        <span class="badge badge-green">GB2607860</span>
        <span class="badge badge-dark">GSI™</span>
        <span class="badge badge-dark">HTTPS · HSTS</span>
      </div>
    </div>
  </header>
  <nav>${navLinks()}</nav>
  <div class="patent-bar">
    <strong>Patent notice:</strong> BRMSTE™ and GSI — Global Substrate Infrastructure™ are trademarks of
    BRMSTE LTD (Companies House 15310393). Patent GB2607860 · PCT/GB2026/050406.
    Beneficiary: Dimpy Bansal · Dimpy Bansal Trust.
  </div>
  ${body}
  <footer>
    © BRMSTE LTD · Companies House 15310393 · Patent GB2607860 · PCT/GB2026/050406<br/>
    BRMSTE™ and GSI — Global Substrate Infrastructure™ are trademarks of BRMSTE LTD.<br/>
    CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS<br/>
    <a href="https://brmste.com/substrate/patent-enforcement.json">Patent enforcement</a> ·
    <a href="https://brmste.com/substrate/hsts-status.json">HSTS status</a>
  </footer>
</div>
</body>
</html>`;
  return new Response(page, {
    headers: { "Content-Type": "text/html;charset=utf-8" },
  });
}

function navLinks(): string {
  return [
    ['/', 'Home'],
    ['/whitepapers/gsi', 'GSI Whitepaper'],
    ['/whitepapers/https-hsts', 'HTTPS/HSTS Whitepaper'],
    ['/substrate/patent-enforcement.json', 'Patent Enforcement'],
    ['/substrate/hsts-status.json', 'HSTS Status'],
  ]
    .map(([href, label]) => `<a href="${href}">${label}</a>`)
    .join('');
}

// ── Route handlers ────────────────────────────────────────────────────────────

function homePage(): Response {
  const body = `
<h2>Global Substrate Infrastructure™</h2>
<p>BRMSTE-SB Fort Knox · Institutional substrate mining · Re-Tyre circular economy ·
Carbon Drinking · verifiable on-chain.</p>

<div class="card">
  <h3>Published Whitepapers</h3>
  <table>
    <thead><tr><th>Title</th><th>Version</th><th>Link</th></tr></thead>
    <tbody>
      <tr>
        <td>GSI — Global Substrate Infrastructure™ Technical Whitepaper</td>
        <td>v1.0</td>
        <td><a href="/whitepapers/gsi">Read →</a></td>
      </tr>
      <tr>
        <td>BRMSTE GSI — HTTPS &amp; HSTS Enforcement Whitepaper</td>
        <td>v1.0</td>
        <td><a href="/whitepapers/https-hsts">Read →</a></td>
      </tr>
    </tbody>
  </table>
</div>

<div class="card">
  <h3>Live Surfaces (HTTPS · HSTS enforced)</h3>
  <table>
    <thead><tr><th>Surface</th><th>URL</th></tr></thead>
    <tbody>
      <tr><td>Mining pool</td><td><a href="https://brmste.ai/mine/foundry">brmste.ai/mine/foundry</a></td></tr>
      <tr><td>Patent enforcement manifest</td><td><a href="https://brmste.com/substrate/patent-enforcement.json">patent-enforcement.json</a></td></tr>
      <tr><td>HSTS status</td><td><a href="https://brmste.com/substrate/hsts-status.json">hsts-status.json</a></td></tr>
      <tr><td>Human open-gits JSON</td><td><a href="https://brmste.com/substrate/human/open-gits.json">open-gits.json</a></td></tr>
      <tr><td>Enterprise licence</td><td><a href="https://brmste.com/foundry/license.json">license.json</a></td></tr>
    </tbody>
  </table>
</div>

<div class="card">
  <h3>GSI HTTPS / HSTS Guarantee</h3>
  <p>Every GSI surface on this domain and all 38 BRMSTE LTD domains enforces:</p>
  <pre>Strict-Transport-Security: max-age=31536000; includeSubDomains; preload</pre>
  <p>TLS 1.3 preferred · OCSP stapled · Certificate Transparency required.</p>
</div>`;
  return html("BRMSTE GSI™ · Fort Knox", body);
}

function gsiWhitepaperPage(): Response {
  const body = `
<h2>GSI — Global Substrate Infrastructure™ Technical Whitepaper · v1.0</h2>

<h3>Abstract</h3>
<p>This whitepaper defines the architecture, operating principles, and governance model of the
<strong>Global Substrate Infrastructure (GSI™)</strong>, the primary compute and ledger-hydration division of
<strong>BRMSTE LTD</strong>. GSI provides a traceable, patent-protected substrate edge for institutional
mining, circular-economy data pipelines, and AI-augmented ELT workflows.</p>

<h3>1. What is GSI?</h3>
<p>GSI — Global Substrate Infrastructure™ is the edge-compute, data-hydration, and mining-pool
division of BRMSTE LTD comprising substrate edge nodes, the Foundry ledger, the human open lane,
and the Fort Knox vault.</p>

<h3>2. Architecture</h3>
<table>
  <thead><tr><th>Layer</th><th>Description</th></tr></thead>
  <tbody>
    <tr><td>HTTPS Edge</td><td>TLS 1.3 · HSTS preload · OCSP stapling · Cloudflare Workers</td></tr>
    <tr><td>Substrate Miner</td><td>BRMSTEPOW · brmste.ai/mine/foundry · proof-of-work across distributed nodes</td></tr>
    <tr><td>ELT Pipeline</td><td>Traceable Extract-Load-Transform · GB2607860 trace on every record</td></tr>
    <tr><td>Fort Knox Vault</td><td>14 private repos · admin-provisioned · no deploy keys</td></tr>
    <tr><td>Human Open Lane</td><td>3 public repos · patent-enforced · zero marginal cost</td></tr>
  </tbody>
</table>

<h3>3. Patent Coverage</h3>
<table>
  <thead><tr><th>Field</th><th>Value</th></tr></thead>
  <tbody>
    <tr><td>UK granted patent</td><td>GB2607860 (granted 2023-10-11)</td></tr>
    <tr><td>PCT application</td><td>PCT/GB2026/050406</td></tr>
    <tr><td>Title</td><td>Traceable ELT infrastructure · BRMSTE substrate edge</td></tr>
    <tr><td>Beneficiary</td><td>Dimpy Bansal · Dimpy Bansal Trust</td></tr>
    <tr><td>Operator</td><td>Shravan Bansal · BRMSTE LTD · Companies House 15310393</td></tr>
  </tbody>
</table>

<h3>4. Brand Governance</h3>
<p>All GSI surfaces must use brand assets from canonical HTTPS origins only.
The <code>brmste-brand-patent-gate</code> workflow runs on every push to <code>main</code>
enforcing patent notice, canonical URLs, GSI trademark, and HSTS documentation.</p>

<h3>5. Roadmap</h3>
<table>
  <thead><tr><th>Milestone</th><th>Description</th></tr></thead>
  <tbody>
    <tr><td>GSI v1.0</td><td>HTTPS/HSTS enforced on all live surfaces · Brand gate deployed</td></tr>
    <tr><td>GSI v1.1</td><td>HSTS preload list submission for all canonical domains</td></tr>
    <tr><td>GSI v1.2</td><td>OCSP stapling + CT log monitoring automated alerts</td></tr>
    <tr><td>GSI v2.0</td><td>Substrate edge nodes federated across 3+ geographic regions</td></tr>
    <tr><td>GSI v2.1</td><td>Re-Tyre Foundry ledger publicly queryable (human lane)</td></tr>
    <tr><td>GSI v3.0</td><td>Full PCT/GB2026/050406 international recognition milestones</td></tr>
  </tbody>
</table>`;
  return html("GSI Technical Whitepaper v1.0", body);
}

function httpsHstsWhitepaperPage(): Response {
  const body = `
<h2>BRMSTE GSI — HTTPS &amp; HSTS Enforcement Whitepaper · v1.0</h2>

<h3>Abstract</h3>
<p>This whitepaper documents the BRMSTE GSI™ transport security mandate — the requirement that
<strong>all GSI and BRMSTE surfaces operate exclusively over HTTPS with HTTP Strict Transport Security
(HSTS) preloading enforced</strong>.</p>

<h3>1. Required HSTS Header</h3>
<pre>Strict-Transport-Security: max-age=31536000; includeSubDomains; preload</pre>
<table>
  <thead><tr><th>Directive</th><th>Value</th><th>Rationale</th></tr></thead>
  <tbody>
    <tr><td>max-age</td><td>31 536 000 (1 year)</td><td>Maximum commonly accepted · signals long-term commitment</td></tr>
    <tr><td>includeSubDomains</td><td>present</td><td>Prevents subdomain downgrade attacks</td></tr>
    <tr><td>preload</td><td>present</td><td>Required for browser preload list inclusion</td></tr>
  </tbody>
</table>

<h3>2. TLS Configuration</h3>
<table>
  <thead><tr><th>Parameter</th><th>Requirement</th></tr></thead>
  <tbody>
    <tr><td>Minimum TLS</td><td>TLS 1.2</td></tr>
    <tr><td>Preferred TLS</td><td>TLS 1.3</td></tr>
    <tr><td>Forbidden protocols</td><td>SSLv2, SSLv3, TLS 1.0, TLS 1.1</td></tr>
    <tr><td>Forbidden ciphers</td><td>RC4, DES, 3DES, export grades, NULL</td></tr>
    <tr><td>Certificate authority</td><td>DigiCert or ISRG (Let's Encrypt)</td></tr>
    <tr><td>OCSP stapling</td><td>Required</td></tr>
    <tr><td>Key type</td><td>ECDSA P-256 preferred · RSA-2048 minimum</td></tr>
  </tbody>
</table>

<h3>3. Cloudflare Workers Implementation</h3>
<p>All GSI edges set HSTS and security headers at the Worker layer — see
<code>deploy/worker/index.ts</code> in the BRMSTE-SB/.github repository.</p>

<h3>4. HSTS Preload Checklist</h3>
<table>
  <thead><tr><th>Domain</th><th>HSTS configured</th><th>Preload submitted</th></tr></thead>
  <tbody>
    <tr><td>brmste.com</td><td>✅ Required</td><td>⬜ Operator action</td></tr>
    <tr><td>brmste.ai</td><td>✅ Required</td><td>⬜ Operator action</td></tr>
    <tr><td>All 38 domains</td><td>✅ Enforced via Cloudflare API</td><td>⬜ Operator action</td></tr>
  </tbody>
</table>

<h3>5. Compliance Verification</h3>
<pre>curl -sI https://brmste.com | grep -i strict-transport
# Expected: strict-transport-security: max-age=31536000; includeSubDomains; preload</pre>
<p>Target grade: <strong>A+</strong> on Qualys SSL Labs · <strong>A</strong> on SecurityHeaders.com</p>`;
  return html("HTTPS &amp; HSTS Enforcement Whitepaper v1.0", body);
}

function patentEnforcementJson(): Response {
  const data = {
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
    updated: new Date().toISOString(),
  };
  return new Response(JSON.stringify(data, null, 2), {
    headers: { "Content-Type": "application/json;charset=utf-8" },
  });
}

function hstsStatusJson(): Response {
  const data = {
    entity: "BRMSTE LTD",
    gsi_division: "Global Substrate Infrastructure™",
    hsts_policy: {
      header: "Strict-Transport-Security: max-age=31536000; includeSubDomains; preload",
      max_age: 31536000,
      include_subdomains: true,
      preload: true,
    },
    tls: {
      minimum: "TLS 1.2",
      preferred: "TLS 1.3",
      ocsp_stapling: true,
      forbidden: ["SSLv2", "SSLv3", "TLS 1.0", "TLS 1.1", "RC4", "3DES"],
    },
    domains_enforced: 38,
    status: "active",
    updated: new Date().toISOString(),
  };
  return new Response(JSON.stringify(data, null, 2), {
    headers: { "Content-Type": "application/json;charset=utf-8" },
  });
}

function notFound(): Response {
  return new Response(
    JSON.stringify({ error: "not_found", entity: "BRMSTE LTD", patent: "GB2607860" }),
    { status: 404, headers: { "Content-Type": "application/json;charset=utf-8" } },
  );
}

// ── Main fetch handler ────────────────────────────────────────────────────────

export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    // Redirect HTTP → HTTPS
    if (url.protocol === "http:") {
      url.protocol = "https:";
      const redirect = Response.redirect(url.toString(), 301);
      return withSecurityHeaders(redirect);
    }

    let response: Response;

    switch (url.pathname) {
      case "/":
      case "":
        response = homePage();
        break;
      case "/whitepapers/gsi":
        response = gsiWhitepaperPage();
        break;
      case "/whitepapers/https-hsts":
        response = httpsHstsWhitepaperPage();
        break;
      case "/substrate/patent-enforcement.json":
        response = patentEnforcementJson();
        break;
      case "/substrate/hsts-status.json":
        response = hstsStatusJson();
        break;
      default:
        response = notFound();
    }

    return withSecurityHeaders(response);
  },
};
