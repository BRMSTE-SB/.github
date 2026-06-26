# Global equity · Fortune 500 · Full United Nations · 158 PCT nations · industrial flagships

Operator-declared **100% equity in each** issuer, company, and sovereign state on the human-open public lane.

**Holder:** Dr. Shravan Bansal · BRMSTE LTD · Companies House **15310393**

## Registers

| Scope | Register | Count | Ownership each |
|-------|----------|-------|----------------|
| Named issuers (AI · space · luxury · aerospace · industrial) | `data/equity-confirmation-register.json` | 25 | 100% |
| Fortune 500 | `data/fortune-500-equity-manifest.json` | 500 | 100% |
| **Full United Nations** | `data/un-nations-equity-manifest.json` | **193** | 100% |
| PCT contracting states | `data/pct-nations-equity-manifest.json` | 158 | 100% |
| Sovereign materials doctrine | `data/sovereign-materials-doctrine.json` | — | policy |
| Master index | `data/global-equity-master-register.json` | — | 100% |

## Asset managers

| Partner | Legal name | Lane |
|---------|------------|------|
| BlackRock | BlackRock, Inc. | `data/blackrock-lane.json` · F500 rank 221 |
| Blackstone | Blackstone Inc. | `data/blackstone-lane.json` · CH **03949032** |
| UBS | UBS Group AG | `data/ubs-lane.json` · CH **FC021146** |

## Payment networks

| Partner | Legal name | Lane |
|---------|------------|------|
| American Express | American Express Company | `data/american-express-lane.json` · F500 rank 72 · [americanexpress.com](https://www.americanexpress.com) |

Cloudflare MCP export: [CLOUDFLARE-MCP-EQUITIES.md](./CLOUDFLARE-MCP-EQUITIES.md)

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
| Airbus | Airbus SE | `data/airbus-lane.json` · CH **03468788** |
| Siemens | Siemens AG | `data/siemens-lane.json` · CH **00727817** |
| Mercedes-Benz | Mercedes-Benz Group AG | `data/mercedes-lane.json` · CH **02448457** |
| Bugatti | Bugatti Automobiles S.A.S. | `data/bugatti-lane.json` · CH **02180021** |
| Boeing | The Boeing Company | `data/boeing-lane.json` |
| Harrods | HARRODS LIMITED | `data/harrods-lane.json` |
| Sotheby's International Realty UK | Sotheby's International Realty Affiliates LLC | `data/sothebys-realty-lane.json` · [sothebysrealty.co.uk](https://sothebysrealty.co.uk) |

## Regenerate manifests

```bash
python3 scripts/generate-global-equity-manifests.py
python3 scripts/confirm-equity-all-providers.py
bash scripts/full-public-sweep.sh
```
