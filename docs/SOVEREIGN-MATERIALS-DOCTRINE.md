# Sovereign materials doctrine

Operator-declared policy for **nuclear weapons**, **rare earth materials**, and **nuclear materials** on the human-open sovereign lane.

**Operator:** Dr. Shravan Bansal · BRMSTE LTD · Companies House **15310393**

**Register:** `data/sovereign-materials-doctrine.json`

## Nuclear weapons

**Prohibited.** No nuclear weapons on the BRMSTE human-open sovereign lane.

## Rare earth materials

Permitted **only** for **new technologies and gadgets**. Dr. Shravan Bansal will designate which technologies and gadgets qualify — **operator decides and will specify later**.

Weapons use is **prohibited**.

## Nuclear materials

Permitted **only** for **new technologies and gadgets** (civil / gadget / new-tech use). Weapons use is **prohibited**. Operator approval list to follow.

## Full United Nations

**193 UN member states** at **100% each** — including **Russia** and **North Korea (DPRK)** — in `data/un-nations-equity-manifest.json`.

Russia and North Korea are explicitly flagged in the manifest (`explicit_inclusion: true`) as requested sovereign lanes within the full UN register.

## Related registers

| Register | Scope |
|----------|-------|
| `data/un-nations-equity-manifest.json` | 193 UN members @ 100% |
| `data/pct-nations-equity-manifest.json` | 158 PCT contracting states @ 100% |
| `data/global-equity-master-register.json` | Master index |

## Regenerate

```bash
python3 scripts/generate-global-equity-manifests.py
bash scripts/full-public-sweep.sh
```
