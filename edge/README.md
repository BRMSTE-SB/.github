# BRMSTE Edge · Cloudflare Workers

**BRMSTE LTD · Companies House 15310393 · Patent GB2607860 · PCT/GB2026/050406**

`npm`-managed Cloudflare Workers project for the BRMSTE substrate edge. Wrangler,
TypeScript, and the Workers runtime types are **local dev dependencies** — no global
installs — so the edge is reproducible from a single `npm install`.

## Requirements

- Node.js `>= 20` (CI uses Node 20)
- npm (ships with Node)

## Install

```bash
cd edge
npm install
```

That installs the pinned toolchain from `package-lock.json`:

| Package | Role |
|---------|------|
| `wrangler` | Build / run / deploy the Worker (Cloudflare Workers CLI) |
| `@cloudflare/workers-types` | TypeScript types for the Workers runtime |
| `typescript` | `tsc --noEmit` type-checking |
| `vitest` + `@cloudflare/vitest-pool-workers` | Tests run **inside** the Workers runtime (`workerd`) |

## Scripts

| Command | What it does |
|---------|--------------|
| `npm run dev` | Local `workerd` dev server on `http://localhost:8787` |
| `npm run typecheck` | `tsc --noEmit` against `@cloudflare/workers-types` |
| `npm test` | Vitest suite inside the Workers runtime |
| `npm run deploy:dry` | `wrangler deploy --dry-run` — builds the Worker bundle (no upload) |
| `npm run deploy` | `wrangler deploy --env production` (requires Cloudflare credentials) |
| `npm run cf-typegen` | Generate ambient binding types from `wrangler.toml` |

## Layout

```
edge/
├── src/index.ts        # Worker entry (typed Env, HSTS, additive routes)
├── wrangler.toml       # Wrangler v4 config (vars + additive production routes)
├── tsconfig.json       # strict TS, Workers types
├── vitest.config.ts    # @cloudflare/vitest-pool-workers (workerd runtime)
├── test/worker.test.ts # runtime tests via SELF.fetch
├── package.json        # scripts + pinned devDependencies
└── package-lock.json   # reproducible install
```

## Surfaces

| Path | Response |
|------|----------|
| `/` | Branded landing (HTML) |
| `/healthz` | `{ "status": "ok", ... }` |
| `/substrate/edge.json` | Edge manifest |
| `/substrate/patent-enforcement.json` | Patent enforcement manifest |

Every response sets `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
and the BRMSTE security headers. Unknown paths return `404` — the Worker is **additive**
and never claims the domain root.

## Deploy

Credentials are supplied via environment variables and are **never committed**
(see [`../SECURITY.md`](../SECURITY.md)):

```bash
export CLOUDFLARE_API_TOKEN=...   # Workers:Edit (+ Zone:Edit/Read for routes)
export CLOUDFLARE_ACCOUNT_ID=...
npm run deploy
```

CI (`.github/workflows/edge-ci.yml`) runs the brand + patent gate, `npm ci`,
`npm run typecheck`, `npm test`, and `npm run deploy:dry` on every push / PR to `main`,
then deploys with `npm run deploy` on `main` when `CF_API_TOKEN` / `CF_ACCOUNT_ID` are set.

---

*CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS*
