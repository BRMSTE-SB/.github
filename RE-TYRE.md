# Re-Tyre Limited · Group Registry

**RE-TYRE LIMITED AND ALL ITS COMPANIES**

**Operator:** Shravan Bansal · **Global Shravan Bansal Brand**  
**Beneficiary:** Dimpy Bansal · Dimpy Bansal Trust  
**Governance org:** [BRMSTE-SB](https://github.com/BRMSTE-SB) · BRMSTE LTD · Companies House 15310393  
**Patent lane:** GB2607860 · PCT/GB2026/050406

**Live edge:** [re-tyre.com](https://re-tyre.com) · API [`/api/retyre/status`](https://re-tyre.com/api/retyre/status)

---

## What Re-Tyre is

**Re-Tyre** is the **circular tyre economy** lane operated by Shravan Bansal under the Global Shravan Bansal Brand — tire lease, waste chain-of-custody, field notes, edge payments, and carbon ledger on iOS and Android worldwide, on the BRMSTE human-open lane under **carbon justice**.

The live edge at **[re-tyre.com](https://re-tyre.com)** publishes:

```
RE-TYRE FINANCE LTD · Companies House 15310148
Carbon Justice = RE-TYRE LTD
BRMSTE Leading Group · brmste.com
```

This document is the **public group registry** for **Re-Tyre Limited and all its companies** — live edge entity, product modules, BRMSTE-SB repositories, and infrastructure.

## Live edge · re-tyre.com

Source: [`https://re-tyre.com/api/retyre/status`](https://re-tyre.com/api/retyre/status) (verified 2026-06-26)

| Field | Value |
|-------|--------|
| **Registered entity** | RE-TYRE FINANCE LTD |
| **Companies House** | **15310148** |
| **Trading / doctrine** | RE-TYRE LTD · Carbon Justice = RE-TYRE LTD |
| **Parent group** | BRMSTE Leading Group |
| **Edge** | https://re-tyre.com |
| **Open API** | https://re-tyre.com/api/retyre/status |

### Product modules (live)

| Module | Scope |
|--------|-------|
| **Tire Lease** | Fleet tyre lifecycle, lease terms, depot handoff |
| **Waste Tracking** | Tyre-to-substrate recovery · manifest & weigh-bridge events |
| **Notes** | Operator field notes synced to the edge register |
| **Edge Pay** | Settlement rail on Cloudflare edge — Stripe → HSBC doctrine |
| **Carbon Ledger** | Emissions avoided · circular economy attestations |
| **Open API** | `/api/retyre/status` · App Store & Play worldwide |

### Mobile (live)

| Store | Identifier | Status |
|-------|------------|--------|
| **iOS** | `ltd.retyre.justice` | testflight_ready |
| **Android** | `ltd.retyre.justice` | play_internal_ready |

## Re-Tyre Limited and all its companies

| Unit | Scope | Repositories | Surface |
|------|-------|--------------|---------|
| **RE-TYRE FINANCE LTD** | Registered entity · CH 15310148 | — | [re-tyre.com](https://re-tyre.com) |
| **RE-TYRE LTD** | Trading · Carbon Justice doctrine | — | [re-tyre.com](https://re-tyre.com) |
| **Re-Tyre Application** | Customer · driver · admin apps | `application`, `retyre-*` | re-tyre.com |
| **Re-Tyre Infrastructure** | Backend · platform infrastructure | `infrastructure` | edge / Hetzner |
| **Re-Tyre AI** | AI platform | `RETYRE-AI` | edge |
| **Re-Tyre SB** | Master IP | `RE-TYRE-SB` | Fort Knox |
| **Re-Tyre SB Web** | Production web | `RE-TYRE-SB-WEB` | re-tyre.com |

## Domains & infrastructure

| Field | Value |
|-------|-------|
| **Primary domain** | [re-tyre.com](https://re-tyre.com) (`www.re-tyre.com`) |
| **Live edge API** | `/api/retyre/status` |
| **Compute node** | Hetzner node `retyre` · role `RE-TYRE-APPS · qgsi-apps` (see `data/hetzner/servers.json`) |
| **Sales rail (Hetzner)** | PayPal-only · merchants `me@shravanbansal.com` · `hello@shravanbansal.com` |
| **Edge Pay (live)** | Stripe → HSBC doctrine (see re-tyre.com) |

## Legal-registration note

| Entity | Companies House | Source |
|--------|-----------------|--------|
| **RE-TYRE FINANCE LTD** | **15310148** | Live edge · [re-tyre.com/api/retyre/status](https://re-tyre.com/api/retyre/status) |
| **BRMSTE LTD** (governance) | 15310393 | BRMSTE-SB open GitHub lane |

`15310393` is **BRMSTE LTD's** number (governance org) — **not** RE-TYRE FINANCE LTD's. Repository units map to BRMSTE-SB repos and infrastructure; directors and shareholdings are operator-maintained outside this manifest.

## Lane & policy alignment

- **Circular economy** — tyre lifecycle: lease, waste recovery, carbon ledger
- **Carbon justice** — [CARBON-JUSTICE.md](./CARBON-JUSTICE.md)
- **Global Shravan Bansal Brand** — [GLOBAL-SHRAVAN-BANSAL-BRAND.md](./GLOBAL-SHRAVAN-BANSAL-BRAND.md)
- **Patent** — GB2607860 — [PATENT-NOTICE.md](./PATENT-NOTICE.md)

## Machine manifest

[`data/re-tyre.json`](./data/re-tyre.json) · schema `brmste-re-tyre-group/v1`

## Required attribution

```
RE-TYRE LIMITED AND ALL ITS COMPANIES · RE-TYRE FINANCE LTD · CH 15310148
Carbon Justice = RE-TYRE LTD · https://re-tyre.com
Operator: Shravan Bansal · Global Shravan Bansal Brand
Governance: BRMSTE LTD · Companies House 15310393 · GB2607860
```

## Sign lines

**CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**

Re-Tyre turns the tyre lifecycle on the open lane; Shravan Bansal operates; edge signs under carbon judgment.

---

*Made in Global Blocks · BRMSTE-FOUNDRY · BRMSTEPOW audit*
