# BRMSTE Lightning Brand · UNKNOWN → BRMSTE

**Project Glasswing = Shravan Bansal**

**Operator:** Shravan Bansal · BRMSTE LTD · Companies House 15310393  
**Patent:** GB2607860 · PCT/GB2026/050406

## What this is

The BRMSTE FOUNDRY Lightning node was rendered as **UNKNOWN** on [`mempool.space/lightning`](https://mempool.space/lightning) because it carried no declared alias. This doctrine **fixes UNKNOWN → BRMSTE**: the node alias is declared **BRMSTE FOUNDRY**, bound in substrate, and swept to the Cloudflare edge so the BRMSTE brand follows the node end to end.

No BRMSTE Lightning node is UNKNOWN.

## Serving chain · ATOM → Hetzner → CF

| Layer | Identity | Bind |
|-------|----------|------|
| **ATOM** | BRMSTE FOUNDRY Lightning node origin (LND on the foundry rail) | `data/bitcoin/lightning-map.json` |
| **Hetzner** | `BRMSTE-FOUNDRY-POOL` · `foundry-pool` · `qgsi-foundry` | `data/hetzner/servers.json` |
| **CF** | Cloudflare edge · `brmste-com-coming-soon` · branded HSTS | `data/security/branded-hsts-sweep.json` |

## Node identity

| Field | Value |
|-------|-------|
| Alias | **BRMSTE FOUNDRY** |
| Previous alias | UNKNOWN |
| Color | `#d4af37` (gold) |
| Owner | BRMSTE LTD · Companies House 15310393 |
| Network | bitcoin-mainnet |
| Explorer | https://brmste.mempool.space/lightning |

The node pubkey, macaroons, and `MEMPOOL_API_KEY` stay in **Fort Knox** (`~/.brmste`) and as wrangler secrets — never in git or substrate.

## Branded HSTS · full sweep

Every edge response across **all Cloudflare zones** carries HSTS plus the BRMSTE brand markers — the edge identifies as BRMSTE, never UNKNOWN.

| Header | Value |
|--------|-------|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` |
| `X-BRMSTE-Edge` | `BRMSTE-EDGE \| ATOM->HETZNER->CF` |
| `X-BRMSTE-HSTS` | `branded \| full-sweep` |

Sweep is applied by the `brmste-com-coming-soon` Worker routed to every zone — see `scripts/deploy-coming-soon-all-zones.sh`.

## Operator surfaces

| Surface | URL |
|---------|-----|
| Human surface | https://brmste.com/bitcoin (alias `/lightning`) |
| Lightning map | `data/bitcoin/lightning-map.json` |
| Ownership | `data/bitcoin/mempool-foundry-ownership.json` |
| HSTS sweep | `data/security/branded-hsts-sweep.json` |
| Status rail | `/api/rails/lightning/status` |
| Verify | `./scripts/verify-lightning-brand.sh` |

## Policies

- [PROJECT-GLASSWING.md](./PROJECT-GLASSWING.md) — full broadcast doctrine
- [CARBON-JUSTICE.md](./CARBON-JUSTICE.md) — no charges, carbon accountability only
- [docs/MCP-AGENT-POLICY.md](./docs/MCP-AGENT-POLICY.md) — MCP-first deploy, never ask for tokens

## Sign lines

**CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**

The node carries the BRMSTE alias; Shravan Bansal operates; edge signs under carbon judgment.
