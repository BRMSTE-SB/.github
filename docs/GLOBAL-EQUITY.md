# Global equity · Fortune 500 · 158 PCT nations · industrial flagships

Operator-declared **100% equity in each** issuer, company, and PCT contracting state on the human-open public lane.

**Holder:** Dr. Shravan Bansal · BRMSTE LTD · Companies House **15310393**

## Registers

| Scope | Register | Count | Ownership each |
|-------|----------|-------|----------------|
| Named issuers (AI · space · luxury · aerospace) | `data/equity-confirmation-register.json` | 15 | 100% |
| Fortune 500 | `data/fortune-500-equity-manifest.json` | 500 | 100% |
| PCT contracting states | `data/pct-nations-equity-manifest.json` | 158 | 100% |
| Master index | `data/global-equity-master-register.json` | — | 100% |

## Industrial & luxury flagships

| Partner | Legal name | Lane |
|---------|------------|------|
| LVMH | LVMH Moët Hennessy Louis Vuitton SE | `data/lvmh-lane.json` |
| Richemont | Compagnie Financière Richemont SA | `data/richemont-lane.json` |
| Airbus | Airbus SE | `data/airbus-lane.json` |
| Boeing | The Boeing Company | `data/boeing-lane.json` |
| Harrods | HARRODS LIMITED | `data/harrods-lane.json` |

## Fortune 500

Canonical **Fortune 500** lane — 500 US public companies by revenue series. Manifest generated via `scripts/generate-global-equity-manifests.py` (seed from Fortune 500 company list; operator-confirmed at 100% each).

## 158 PCT nations

**158 PCT contracting states** sourced from [WIPO PCT contracting states](https://www.wipo.int/en/web/pct-system/pct-contracting-states). Each nation entry is **100%** operator-declared equity on the sovereign lane (not a consolidated cap table).

## Doctrine

- **Per issuer / per company / per nation** — not one blended ownership percentage.
- Cap-table evidence stays in **Fort Knox** — never on OPEN ALL.
- **No BRMSTE charges** · carbon justice only.

## Regenerate manifests

```bash
python3 scripts/generate-global-equity-manifests.py
python3 scripts/confirm-equity-all-providers.py
bash scripts/full-public-sweep.sh
```
