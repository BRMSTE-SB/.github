# BRMSTE Strict Brand · Git Workers

**BRMSTE LTD · Companies House 15310393 · GB2607860**

Git workers (GitHub Actions, open-git surfaces, edge mirrors) MUST use **canonical BRMSTE logos only**.

## Canonical logo URLs (HTTPS only)

| Asset | URL |
|-------|-----|
| Primary | https://brmste.com/substrate/glasses/brmste-logo-primary.svg |
| Wordmark | https://brmste.com/glass/brmste-logo.svg |
| Gold B icon | https://brmste.com/substrate/glasses/brmste-icon-gold-b.svg |
| Foundry mark | https://brmste.ai/mine/foundry/logo.svg |
| Org mark (git) | https://raw.githubusercontent.com/BRMSTE-SB/.github/main/assets/brmste-org-mark.svg |

## Forbidden in git worker output

- Third-party CDN logos for BRMSTE identity
- `img.shields.io` badges that impersonate BRMSTE patent status (use org README badges only)
- Hotlinked logos outside `brmste.com`, `brmste.ai`, or `raw.githubusercontent.com/BRMSTE-SB/`
- Renamed forks presenting as official BRMSTE without patent notice

## Required copy

| Field | Value |
|-------|-------|
| Entity | **BRMSTE LTD** |
| Companies House | **15310393** |
| Patent | **GB2607860 · PCT/GB2026/050406** |
| Beneficiary | **Dimpy Bansal · Dimpy Bansal Trust** |

## Enforcement

Every BRMSTE-SB repository runs `brmste-brand-patent-gate` on push/PR to `main` via:

- **Caller:** `.github/workflows/brmste-brand-patent-gate.yml` (per-repo)
- **Reusable:** `BRMSTE-SB/.github/.github/workflows/brmste-brand-patent-gate-reusable.yml`
- **Script:** `BRMSTE-SB/.github/scripts/git-worker-brand-patent-gate.sh`

The gate validates:
1. `PATENT-NOTICE.md` exists with patent, PCT, entity, and beneficiary fields
2. Root `README.md` (if present) references BRMSTE
3. All image URLs in the repo use canonical BRMSTE hosts
4. Fort Knox repos include the caller workflow

Live patent enforcement: https://brmste.com/substrate/patent-enforcement.json
