# BRMSTE · GSI · Strict Brand · Git Workers

**BRMSTE LTD · Companies House 15310393 · GB2607860**  
**GSI — Global Substrate Infrastructure™ · A BRMSTE LTD Product Division**

---

## GSI — Global Substrate Infrastructure™

**GSI** is the registered product division of **BRMSTE LTD** that covers all substrate-edge compute,
mining-pool ledger-hydration, traceable ELT pipelines, and carbon-cycle verifiable infrastructure.

| Attribute | Value |
|-----------|-------|
| Full name | Global Substrate Infrastructure™ |
| Short name | GSI™ |
| Owner | BRMSTE LTD · Companies House 15310393 |
| Patent | GB2607860 · PCT/GB2026/050406 |
| Trademark class | UK Class 38 (Telecommunications), 42 (Scientific/tech) |
| Protocol mandate | HTTPS only · HSTS enforced (min-age 31536000) |

All **GSI** surfaces are TLS-terminated at the edge. No GSI endpoint may serve plaintext HTTP
to any external consumer. HSTS (`Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`)
is mandatory on every GSI origin and CDN edge.

---

## Canonical logo URLs (HTTPS only · HSTS enforced)

Git workers (GitHub Actions, open-git surfaces, edge mirrors) **MUST** use **canonical BRMSTE/GSI logos only**.
All URLs below are HTTPS; HSTS is active on all canonical domains.

| Asset | URL |
|-------|-----|
| BRMSTE Primary | https://brmste.com/substrate/glasses/brmste-logo-primary.svg |
| BRMSTE Wordmark | https://brmste.com/glass/brmste-logo.svg |
| BRMSTE Gold B icon | https://brmste.com/substrate/glasses/brmste-icon-gold-b.svg |
| GSI Foundry mark | https://brmste.ai/mine/foundry/logo.svg |
| GSI Org mark (git) | https://raw.githubusercontent.com/BRMSTE-SB/.github/main/assets/brmste-org-mark.svg |

### HTTPS / HSTS requirements for all canonical asset URLs

- All canonical URLs **must** use `https://` — `http://` variants are forbidden.
- HSTS preload must be configured on `brmste.com`, `brmste.ai`, and all GSI edge origins.
- HSTS header: `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- TLS minimum version: **TLS 1.2** · Preferred: **TLS 1.3**
- Certificate authority: DigiCert or Let's Encrypt (ISRG) only.
- OCSP stapling: required on all GSI TLS origins.

---

## Forbidden in git worker output

- Third-party CDN logos for BRMSTE or GSI identity
- `img.shields.io` badges that impersonate BRMSTE/GSI patent status (use org README badges only)
- Hotlinked logos outside `brmste.com`, `brmste.ai`, or `raw.githubusercontent.com/BRMSTE-SB/`
- Renamed forks presenting as official BRMSTE/GSI without patent notice
- Any `http://` (plaintext) URL to a BRMSTE or GSI asset or endpoint
- HSTS headers with `max-age` below **31536000** (one year)

---

## Required copy in all BRMSTE/GSI surfaces

- Entity: **BRMSTE LTD**
- Companies House: **15310393**
- Patent: **GB2607860 · PCT/GB2026/050406**
- Division: **GSI — Global Substrate Infrastructure™**
- Trademark line: **BRMSTE™ and GSI™ are trademarks of BRMSTE LTD**
- Beneficiary line (human lane): **Dimpy (Shravan) Bansal · BRMSTE LTD**

---

## Protocol Enforcement

Every BRMSTE-SB repository runs `brmste-brand-patent-gate` on push/PR to `main`.
The gate validates:

1. `PATENT-NOTICE.md` cites `GB2607860` and `PCT/GB2026/050406`
2. `BRAND.md` is present
3. No non-canonical logo URLs
4. No plaintext `http://` asset references
5. GSI trademark line present where GSI assets are referenced

Live patent enforcement: https://brmste.com/substrate/patent-enforcement.json  
Live HSTS status: https://brmste.com/substrate/hsts-status.json
