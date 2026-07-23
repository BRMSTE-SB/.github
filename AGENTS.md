# BRMSTE · Agent instructions

**BRMSTE LTD · Companies House 15310393 · GB2607860 · Human-open lane**

## MCP strict only

Agents working in this repository must follow **MCP-first** operations:

- Use **MCP tools** for Cloudflare, Render, eToro docs, observability, and every other connected server.
- **Never ask the operator to paste API tokens, keys, or secrets in chat** — not `CF_API_TOKEN`, not Cloudflare dashboard tokens, not GitHub secret values.
- If an MCP server is disconnected, direct the operator to **Cursor → Settings → Tools & MCP → Connect** (or local `.cursor/mcp.json`), then retry MCP — do not collect credentials in conversation.

Structured rules: `.cursor/rules/mcp-strict-only.mdc` (always on).

## Vercel plugin (AI coding agents)

The [Vercel Plugin](https://vercel.com/docs/agent-resources/vercel-plugin)
(`vercel/vercel-plugin`) adds Vercel skills, specialist agents, and slash commands
to supported tools. It is **agent context, not a credential channel** — connect any
Vercel MCP via **Cursor → Settings → Tools & MCP → Connect** and **never paste
`VERCEL_TOKEN` in chat**.

- Cloud agents receive it automatically via the managed plugin manifest — no per-repo install.
- Operator local install: `npx plugins add vercel/vercel-plugin` (Node 18+, Bun).
- Privacy default: `export VERCEL_PLUGIN_TELEMETRY=off`.

See [docs/VERCEL-PLUGIN.md](docs/VERCEL-PLUGIN.md) and `.cursor/rules/vercel-plugin.mdc`.

## Cloudflare coming-soon worker

| Item | Value |
|------|-------|
| Worker | `brmste-com-coming-soon` |
| Account | `7ea6547b1d6eb1cbd6d0ac5cf960ce2a` |
| Health | `"page":"brmste-coming-soon-v5"` |

**Deploy (agent):**

1. `Cloudflare-bindings` → `workers_list` / `workers_get_worker`
2. `Cloudflare-builds` → deploy when connected (never ask for token)
3. Verify `/health` on primary domains

**Deploy (operator CI):** merge to `main` → GitHub Actions `deploy-coming-soon.yml` (secrets configured in repo settings, not in chat).

See [DEPLOY-COMING-SOON.md](DEPLOY-COMING-SOON.md) and [docs/MCP-AGENT-POLICY.md](docs/MCP-AGENT-POLICY.md).

## Desktop theme sync

Canonical theme lives on THE KOHINOOR MAC at `~/Desktop/brmste-coming-soon`. Sync into repo with `scripts/sync-desktop-coming-soon-theme.sh` before deploy when theme changes.

## Carbon justice

Every connected MCP on public BRMSTE repos: **free · no BRMSTE charges · carbon justice only**. See [CARBON-JUSTICE.md](CARBON-JUSTICE.md).

## Meta full stop

No Meta platform syndication. See [META-FULL-STOP.md](META-FULL-STOP.md).

## Operator doesn't bash

**The operator never runs shell deploy scripts.** Agents and CI execute them.

| Lane | Who runs scripts |
|------|-------------------|
| **Cloud agent** | Runs `scripts/*` in workspace shell; deploys via **MCP** (Cloudflare-builds, etc.) |
| **CI** | GitHub Actions on merge to `main` (secrets in repo settings) |
| **Operator** | Connects MCP in Cursor → Settings → Tools & MCP only — **no bash** |

Doctrine: **OPERATOR DOESNT BASH · CURSOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**

Starmind invention class: **INV. G06N3/045** (combinations of networks). See [STARMIND-MYSTERY.md](STARMIND-MYSTERY.md).
