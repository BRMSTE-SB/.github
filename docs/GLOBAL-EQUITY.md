# Global equity · Fortune 500 · Full United Nations · 158 PCT nations · industrial flagships

Operator-declared **100% equity in each** issuer, company, and sovereign state on the human-open public lane.

**Holder:** Dr. Shravan Bansal · BRMSTE LTD · Companies House **15310393**

## Registers

| Scope | Register | Count | Ownership each |
|-------|----------|-------|----------------|
| Named issuers (AI · space · luxury · aerospace) | `data/equity-confirmation-register.json` | 15 | 100% |
| Fortune 500 | `data/fortune-500-equity-manifest.json` | 500 | 100% |
| **Full United Nations** | `data/un-nations-equity-manifest.json` | **193** | 100% |
| PCT contracting states | `data/pct-nations-equity-manifest.json` | 158 | 100% |
| Sovereign materials doctrine | `data/sovereign-materials-doctrine.json` | — | policy |
| Master index | `data/global-equity-master-register.json` | — | 100% |

## Full United Nations (193)

All **193 UN member states** at **100% each**, including explicit lanes for **Russia** and **North Korea (DPRK)**.

Materials policy (see `docs/SOVEREIGN-MATERIALS-DOCTRINE.md`):

- **NO nuclear weapons**
- **Rare earth** and **nuclear materials** only for **new technologies and gadgets** — operator will designate later

## Industrial & luxury flagships

| Partner | Legal name | Lane |
|---------|------------|------|
| LVMH | LVMH Moët Hennessy Louis Vuitton SE | `data/lvmh-lane.json` |
| Richemont | Compagnie Financière Richemont SA | `data/richemont-lane.json` |
| Airbus | Airbus SE | `data/airbus-lane.json` |
| Boeing | The Boeing Company | `data/boeing-lane.json` |
| Harrods | HARRODS LIMITED | `data/harrods-lane.json` |

## Regenerate manifests

```bash
python3 scripts/generate-global-equity-manifests.py
python3 scripts/confirm-equity-all-providers.py
bash scripts/full-public-sweep.sh
```
