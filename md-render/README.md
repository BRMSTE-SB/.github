# BRMSTE branded MD render — Hetzner origin · Cloudflare HSTS

**BRMSTE LTD · Companies House 15310393 · GB2607860 · GSI Governance**

Renders every Markdown doc in this repo into one **branded**, self-contained
HTML page (dark BRMSTE shell + canonical GSI Carbon Collider mark) and serves it
from the **Hetzner fleet** as origin, behind **Cloudflare** with **HSTS**
enforced at both the edge and the origin.

```
            ┌──────────────────────────── Cloudflare ────────────────────────────┐
 visitor ──▶│  proxy (orange-cloud) · TLS · HSTS (max-age 63072000; preload)      │──▶ Hetzner node :8787
            └────────────────────────────────────────────────────────────────────┘     serve.mjs / Caddy
                                                                                          (HSTS also at origin)
```

## Components

| File | Role |
|------|------|
| `build.mjs` | Discovers all repo `*.md` → renders branded `dist/index.html` (uses `marked`) |
| `serve.mjs` | Zero-dependency Node origin server; applies HSTS + security headers to every response; binds `0.0.0.0:$PORT` |
| `headers.mjs` | Shared HSTS / CSP / security-header policy (single source of truth) |
| `Caddyfile` | Static origin alternative (no Node runtime needed on the node) |
| `Dockerfile` | Container image (build renders docs; run serves with HSTS) |
| `brmste-md-render.service` | systemd unit for the Hetzner nodes |
| `../scripts/deploy-md-render-hetzner.sh` | Build + deploy to the fleet (Kohinoor Mac) |

The HSTS value (`max-age=63072000; includeSubDomains; preload`) is identical to
the `brmste-com-coming-soon` worker, so the policy matches across the estate.

## Local development

```bash
cd md-render
npm install
npm run build          # render repo docs -> dist/index.html
npm run serve          # origin server on http://0.0.0.0:8787 (HSTS on every response)
npm test               # vitest: render + HSTS + path-safety
curl -sI http://127.0.0.1:8787/ | grep -i strict-transport-security
```

## Deploy (operator — Kohinoor Mac)

SSH to the 15 Hetzner nodes is Mac-only (see `docs/HETZNER-MAC-COLLECT.md`);
cloud agents cannot reach the fleet.

```bash
bash scripts/deploy-md-render-hetzner.sh --dry-run     # build only
bash scripts/deploy-md-render-hetzner.sh               # build + rsync + systemd on the fleet
# or per node subset:
MD_RENDER_NODES="brmste-lucifer brmste-leading" bash scripts/deploy-md-render-hetzner.sh
```

Container alternative (any node with Docker):

```bash
docker build -f md-render/Dockerfile -t brmste-md-render .
docker run -p 8787:8787 brmste-md-render
```

## Cloudflare front (HSTS at the edge)

1. Proxy the docs hostname (e.g. `brmste.com/docs` route or `docs.brmste.com`)
   to the node(s) on `:8787` (orange-cloud / Tunnel).
2. **SSL/TLS → Edge Certificates → HTTP Strict Transport Security (HSTS)** →
   enable: `max-age 63072000`, **includeSubDomains**, **preload**.
3. The origin (`serve.mjs` / Caddy) also returns HSTS, so the policy holds even
   on direct-to-origin requests.

> No DNS/Email-Routing/HSTS tools exist on the connected Cloudflare MCP, and SSH
> to the fleet is Mac-only — so deploy (Hetzner) and the edge HSTS toggle
> (Cloudflare) are operator steps. Everything else is built and tested here.
