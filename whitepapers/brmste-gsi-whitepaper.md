# BRMSTE GSI — Global Substrate Infrastructure™

## Technical Whitepaper · v1.0

---

**BRMSTE LTD · Companies House 15310393**  
**GSI™ — Global Substrate Infrastructure™**  
**Patent: GB2607860 · PCT/GB2026/050406**  
**Beneficiary: Dimpy (Shravan) Bansal · BRMSTE LTD**  
**Operator: Shravan Bansal · BRMSTE LTD**

*BRMSTE™ and GSI — Global Substrate Infrastructure™ are trademarks of BRMSTE LTD (Companies House 15310393).*

---

## Abstract

This whitepaper defines the architecture, operating principles, and governance model of the
**Global Substrate Infrastructure (GSI™)**, the primary compute and ledger-hydration division of
**BRMSTE LTD**. GSI provides a traceable, patent-protected substrate edge for institutional
mining, circular-economy data pipelines, and AI-augmented ELT workflows.

All GSI surfaces are HTTPS-only with HSTS preloading enforced as a first-class infrastructure
primitive — not a post-deployment afterthought. Brand integrity, patent enforcement, and
transport security are enforced by automated git workers on every push to production.

---

## 1. Introduction

### 1.1 What is GSI?

**GSI — Global Substrate Infrastructure™** is the edge-compute, data-hydration, and mining-pool
division of BRMSTE LTD. It comprises:

- **Substrate edge nodes** — geographically distributed compute running BRMSTE mining pools
  and traceable ELT (Extract, Load, Transform) pipelines
- **Foundry ledger** — an on-chain verifiable record of carbon-cycle and Re-Tyre circular
  economy transactions
- **Human open lane** — a patent-enforced public API surface that allows human operators to
  run substrate operations at zero marginal cost subject to the BRMSTE patent notice
- **Fort Knox vault** — 14 private repositories constituting the production IP, fleet configs,
  Re-Tyre application stack, and AI platform

### 1.2 Why a separate GSI brand?

BRMSTE LTD operates across multiple product categories. GSI is the designated trademark and
technical identity for the **infrastructure layer** — distinguishing it from the Re-Tyre consumer
product, the BRMSTE AI platform, and the BRMSTE Foundry mining pool. The GSI mark on a surface
guarantees:

1. The surface is TLS-terminated with HSTS preloading active
2. The underlying compute traces every ELT transaction against GB2607860
3. Brand assets are served exclusively from canonical HTTPS origins
4. Git worker brand+patent gates have passed on the deployed commit

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    GSI — Global Substrate Infrastructure™        │
│                    BRMSTE LTD · GB2607860                       │
│                                                                   │
│  ┌───────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │  HTTPS Edge   │  │  Substrate Miner │  │  ELT Pipeline    │  │
│  │  HSTS preload │  │  (BRMSTEPOW)     │  │  (Traceable)     │  │
│  │  TLS 1.3      │  │  brmste.ai/mine  │  │  Foundry ledger  │  │
│  └──────┬────────┘  └────────┬─────────┘  └────────┬─────────┘  │
│         │                   │                      │             │
│         └───────────────────┼──────────────────────┘             │
│                             │                                     │
│                    ┌────────▼─────────┐                          │
│                    │  Fort Knox Vault  │                          │
│                    │  14 private repos │                          │
│                    │  Admin-only       │                          │
│                    └────────┬─────────┘                          │
│                             │                                     │
│                    ┌────────▼─────────┐                          │
│                    │ Human Open Lane   │                          │
│                    │ 3 public repos    │                          │
│                    │ Patent-enforced   │                          │
│                    └──────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
```

### 2.1 Edge layer (HTTPS / HSTS)

Every GSI edge node:

- Terminates TLS at the edge (Cloudflare Workers or equivalent)
- Emits `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload` on all responses
- Redirects any HTTP request to HTTPS via `301 Moved Permanently`
- Uses ECDHE cipher suites with AES-256-GCM or CHACHA20-POLY1305
- Staples OCSP responses to reduce certificate validation latency
- Enforces `Content-Security-Policy`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`

### 2.2 Substrate mining layer (BRMSTEPOW)

The substrate miner runs BRMSTE proof-of-work across distributed edge nodes, writing verified
mining results to the Foundry ledger. Each mining event is tagged with:

- Edge node identifier
- Timestamp (UTC, UNIX epoch milliseconds)
- Patent trace reference: `GB2607860`
- ELT batch hash (SHA-256)
- Carbon-cycle metadata (Re-Tyre integration where applicable)

### 2.3 ELT pipeline (traceable)

GSI's traceable ELT pipeline extracts raw substrate data, loads it into the Foundry ledger, and
transforms it into verifiable on-chain records. Every record references:

- Source substrate node
- GB2607860 patent trace
- Human / non-human operator flag
- HTTPS endpoint from which the data was extracted (canonical BRMSTE URL only)

### 2.4 Fort Knox vault

The Fort Knox vault is the private repository estate of BRMSTE LTD:

| Repository group | Purpose |
|-----------------|---------|
| `mac-admin`, `brmste-mine` | Edge fleet management, mining orchestration |
| `mining-pools` | Pool configuration, reward ledger |
| `retyre-*`, `application`, `infrastructure` | Re-Tyre circular tyre economy stack |
| `RETYRE-AI`, `RE-TYRE-SB`, `RE-TYRE-SB-WEB` | AI platform, master IP, production web |
| `.github`, `cursor-engitec` | Org profile, security policy, standards |

### 2.5 Human open lane

Three public repositories form the human open lane, allowing humans to interact with the BRMSTE
substrate at zero marginal cost subject to preserving `PATENT-NOTICE.md`:

- `open-gits` — starter templates and open surface documentation
- `brmste-human-future` — human roadmap and participation guide
- `mining-pools` — public pool configuration catalog

---

## 3. Patent Coverage

The GSI architecture is protected under **UK Patent GB2607860** (granted 2023-10-11) and
**PCT/GB2026/050406**, covering:

- **Traceable ELT infrastructure** — the method of extracting, loading, and transforming
  substrate data with cryptographically verifiable provenance records
- **BRMSTE substrate edge** — the edge compute topology that routes, traces, and gates
  substrate operations against the patent enforcement manifest

Patent enforcement is live and continuously updated at:  
https://brmste.com/substrate/patent-enforcement.json

---

## 4. Brand Governance

### 4.1 Canonical assets

All GSI surfaces must use brand assets from canonical HTTPS origins only (see `BRAND.md`).
No third-party CDN may host BRMSTE or GSI identity assets.

### 4.2 Git worker brand+patent gate

On every push and pull request to `main` in any Fort Knox repository, the
`brmste-brand-patent-gate` workflow:

1. Verifies `PATENT-NOTICE.md` cites `GB2607860` and `PCT/GB2026/050406`
2. Verifies `README.md` references `BRMSTE`
3. Scans all URLs for non-canonical logo origins
4. Rejects any `http://` (non-HTTPS) logo or asset URL
5. Verifies the Fort Knox caller workflow is present

Human open lane repositories run the same gate minus the Fort Knox caller check.

### 4.3 Trademark display rules

- BRMSTE™ and GSI™ must appear with the ™ symbol on first use in any document
- The full form **Global Substrate Infrastructure™** must appear at least once per whitepaper
  or published document
- The required attribution string (see `TRADEMARK.md`) must appear in the footer of all
  GSI-branded published materials

---

## 5. Re-Tyre Integration

**Re-Tyre™** is the circular tyre economy product of BRMSTE LTD. GSI provides the
infrastructure layer for Re-Tyre's verifiable carbon-cycle records:

- Tyre collection and processing events are written to the Foundry ledger via the GSI ELT pipeline
- Each Re-Tyre transaction carries a GSI edge trace (GB2607860 reference)
- Re-Tyre AI platform (`RETYRE-AI`) runs on GSI substrate nodes behind HTTPS/HSTS edges

---

## 6. Governance and Compliance

### 6.1 Access control

- Default org permission: **no access**
- 2FA mandatory for all BRMSTE-SB members
- Admin-provisioned repositories only
- External collaborators require enterprise admin approval
- No deploy keys org-wide

### 6.2 Secret management

- Secrets stored in GitHub Environments + org secrets only
- `config/cf-workers.env`, wallet keys, RPC credentials: never committed to git
- Secret scanning + push protection enabled on all repositories
- Dependabot security updates enabled

### 6.3 Production deploy policy

- Reviewed PR + passing `brmste-brand-patent-gate` checks required before merge to `main`
- HTTPS / HSTS verified post-deploy via automated uptime check against HSTS status endpoint:
  https://brmste.com/substrate/hsts-status.json

---

## 7. Roadmap

| Milestone | Description |
|-----------|-------------|
| GSI v1.0 | HTTPS/HSTS enforced on all live surfaces · Brand gate deployed |
| GSI v1.1 | HSTS preload list submission for all canonical domains |
| GSI v1.2 | OCSP stapling + CT log monitoring automated alerts |
| GSI v2.0 | Substrate edge nodes federated across 3+ geographic regions |
| GSI v2.1 | Re-Tyre Foundry ledger publicly queryable (human lane) |
| GSI v3.0 | Full PCT/GB2026/050406 international recognition milestones |

---

## 8. Conclusion

GSI — Global Substrate Infrastructure™ is the foundational infrastructure product of BRMSTE LTD,
delivering traceable ELT, patent-protected substrate mining, and HTTPS/HSTS-enforced edge compute.
The GSI brand mark on any surface is a guarantee of:

- Patent compliance (GB2607860 · PCT/GB2026/050406)
- HTTPS-only transport with HSTS preloading
- Canonical brand assets from verified BRMSTE origins
- Automated git worker enforcement on every production push

---

## Trademark & Patent Notice

BRMSTE™ and GSI — Global Substrate Infrastructure™ are trademarks of BRMSTE LTD
(Companies House 15310393). Patent GB2607860 · PCT/GB2026/050406.

**Beneficiary:** Dimpy (Shravan) Bansal · BRMSTE LTD  
**Operator:** Shravan Bansal · BRMSTE LTD

CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS

Live patent enforcement: https://brmste.com/substrate/patent-enforcement.json

© BRMSTE LTD · Companies House 15310393 · All rights reserved.
