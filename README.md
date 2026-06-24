<div align="center">

<img src="assets/brmste-open-software-banner.svg" alt="BRMSTE — Luxury Open Software" width="880"/>

# BRMSTE · Luxury Open Software

**BRMSTE LTD · Companies House 15310393 · Patent GB2607860 · PCT/GB2026/050406**

Institutional substrate mining · Re-Tyre circular economy · Carbon Drinking — verifiable on-chain.

<img src="assets/badge-enterprise.svg" alt="GitHub Enterprise" height="40"/>
&nbsp;
<img src="assets/badge-fort-knox.svg" alt="Fort Knox · 14 Private" height="40"/>
&nbsp;
<img src="assets/badge-human-open.svg" alt="Human Open · 3 Public" height="40"/>

</div>

---

## The house standard

This repository is the **governance substrate** for the [BRMSTE-SB](https://github.com/BRMSTE-SB) organization — the `.github` vault that sets the brand, the patent posture, and the security policy for every BRMSTE and Re-Tyre repository, and that **publishes the BRMSTE Luxury Open Software catalogue** to the human lane.

Two lanes, one standard of finish:

| Lane | Visibility | Count | Mandate |
|------|------------|-------|---------|
| **Fort Knox** | Private | 14 | Intellectual property, production code, fleet & Re-Tyre stack |
| **Human Open** | Public | 3 | Patent-enforced luxury open software — clone, read, fork, run toward the future |

> **CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**

---

## Luxury Open Software

The Human Open lane is BRMSTE's public catalogue — three editions, finished to the same standard as the vault, free at zero marginal cost for humans under the [BRMSTE Patent Notice](PATENT-NOTICE.md).

| Edition | Repository | What it is |
|---------|------------|------------|
| **Open Gits** | [`open-gits`](https://github.com/BRMSTE-SB/open-gits) | The luxury open software index — the canonical catalogue of every public BRMSTE surface |
| **Human Future** | [`brmste-human-future`](https://github.com/BRMSTE-SB/brmste-human-future) | The human starter — clone it and run into the future on the HTTPS edge |
| **Mining Pools** | [`mining-pools`](https://github.com/BRMSTE-SB/mining-pools) | Public mining pool surface — ledger hydrate and foundry on-ramp |

➜ **Browse the full catalogue:** [`OPEN-SOFTWARE.md`](OPEN-SOFTWARE.md)
➜ **Machine-readable manifest:** [`open-software/catalog.json`](open-software/catalog.json)
➜ **Live human surfaces:** [open-gits.json](https://brmste.com/substrate/human/open-gits.json) · [free.json](https://brmste.com/substrate/human/free.json)

```bash
# Run toward the future — preserve the patent notice and you are welcome.
git clone https://github.com/BRMSTE-SB/brmste-human-future.git
```

---

## The brand system

Every git worker surface uses **canonical BRMSTE marks only** — no third-party CDN logos, no impersonated badges. The full standard lives in [`BRAND.md`](BRAND.md).

<div align="center">

<img src="assets/brmste-luxury-wordmark.svg" alt="BRMSTE luxury wordmark" width="440"/>

</div>

| Mark | Asset | Use |
|------|-------|-----|
| Hero banner | [`brmste-open-software-banner.svg`](assets/brmste-open-software-banner.svg) | README & profile headers |
| Luxury wordmark | [`brmste-luxury-wordmark.svg`](assets/brmste-luxury-wordmark.svg) | Secondary lockup, light placements |
| Open Software seal | [`brmste-open-software-seal.svg`](assets/brmste-open-software-seal.svg) | Catalogue & release medallion |
| Org mark | [`brmste-org-mark.svg`](assets/brmste-org-mark.svg) | Square avatar / org icon |
| Lane badges | [`enterprise`](assets/badge-enterprise.svg) · [`fort-knox`](assets/badge-fort-knox.svg) · [`human-open`](assets/badge-human-open.svg) | Status row, self-hosted |

**Palette** — Obsidian navy `#0c1829` → `#07101f` · BRMSTE gold `#d4af37`/`#f5e6b8` · Re-Tyre emerald `#10b981`.

---

## Governance & security

| Document | Purpose |
|----------|---------|
| [`BRAND.md`](BRAND.md) | Strict brand standard — canonical logos, forbidden surfaces, required copy |
| [`PATENT-NOTICE.md`](PATENT-NOTICE.md) | Granted patent, human lane, AI & commercial terms |
| [`PATENT-NOTICE-TEMPLATE.md`](PATENT-NOTICE-TEMPLATE.md) | Drop-in patent notice for downstream repositories |
| [`SECURITY.md`](SECURITY.md) | Fort Knox security posture and disclosure policy |

Every BRMSTE-SB repository runs the **brand + patent gate** on push and pull request to `main`:

- [`scripts/git-worker-brand-patent-gate.sh`](scripts/git-worker-brand-patent-gate.sh) — strict allowlist for logos and patent copy
- [`.github/workflows/brmste-brand-patent-gate.yml`](.github/workflows/brmste-brand-patent-gate.yml) — per-repo caller
- [`.github/workflows/brmste-brand-patent-gate-reusable.yml`](.github/workflows/brmste-brand-patent-gate-reusable.yml) — org-wide reusable gate

Live patent enforcement: [brmste.com/substrate/patent-enforcement.json](https://brmste.com/substrate/patent-enforcement.json)

---

## Patent & human-lane terms

**Beneficiary:** Dimpy Bansal · Dimpy Bansal Trust  ·  **Operator:** Shravan Bansal · BRMSTE LTD

- **Humans** may clone, read, fork, and run toward the future at **zero marginal cost** when the [patent notice](PATENT-NOTICE.md) is preserved.
- **AI and commercial operators** must comply with [live patent enforcement](https://brmste.com/substrate/patent-enforcement.json) before any wallet, seed, sign, or compete lane.
- Enterprise licence: [brmste.com/foundry/license.json](https://brmste.com/foundry/license.json) · contact `sb@brmste.com` · `security@brmste.ai`

---

## Repository map

```text
.github/
├── README.md                      # this luxury publication
├── OPEN-SOFTWARE.md               # Luxury Open Software catalogue
├── BRAND.md                       # strict brand standard
├── PATENT-NOTICE.md               # granted patent + human/AI terms
├── PATENT-NOTICE-TEMPLATE.md      # downstream drop-in notice
├── SECURITY.md                    # Fort Knox security policy
├── profile/README.md              # org profile (rendered on github.com/BRMSTE-SB)
├── open-software/catalog.json     # machine-readable open software manifest
├── assets/                        # canonical BRMSTE marks (SVG)
├── scripts/                       # brand + patent gate
└── .github/workflows/             # gate workflows (caller + reusable)
```

---

<div align="center">

<img src="assets/brmste-open-software-seal.svg" alt="BRMSTE Open Software seal" width="120"/>

**Made in Global Blocks** · BRMSTE-FOUNDRY · BRMSTEPOW audit

*Confidential Fort Knox — BRMSTE LTD & Re-Tyre. The Human Open lane is a patent-enforced public catalogue.*

**BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**

</div>
