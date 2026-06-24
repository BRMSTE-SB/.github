# BRMSTE Open gits — recheck audit (24 Jun 2026)

**Lane:** BRMSTE Open (legacy: Human Open · `human_open` · EPIC)  
**Entity:** BRMSTE LTD · CH 15310393 (CERTNM rename 16 Mar 2026)

---

## Verdict

| Layer | Status |
|-------|--------|
| **GitHub public repos** | **OPEN / LIVE** — 7 public repos, clone OK |
| **GitHub catalog JSON** | **LIVE** — `open-gits/catalog.json` + mirror in `.github` |
| **brmste.com edge substrate** | **404** — all probed paths down (see below) |

**Use GitHub as primary until edge hydrates.**

---

## Public repos (BRMSTE-SB org)

| Repo | Visibility | Clone |
|------|------------|-------|
| [open-gits](https://github.com/BRMSTE-SB/open-gits) | PUBLIC | `git clone https://github.com/BRMSTE-SB/open-gits.git` |
| [brmste-human-future](https://github.com/BRMSTE-SB/brmste-human-future) | PUBLIC | `git clone https://github.com/BRMSTE-SB/brmste-human-future.git` |
| [mining-pools](https://github.com/BRMSTE-SB/mining-pools) | PUBLIC | `git clone https://github.com/BRMSTE-SB/mining-pools.git` |
| mining-pools-1 | PUBLIC | auxiliary |
| mining-pool-logos | PUBLIC | assets |
| docs | PUBLIC | documentation |
| .github | PUBLIC | governance · compare · fca · substrate mirror |

---

## Catalog URLs (working)

| Purpose | URL | HTTP |
|---------|-----|------|
| **BRMSTE Open catalog v2 (mirror)** | https://raw.githubusercontent.com/BRMSTE-SB/.github/main/substrate/brmste/open-gits.json | 200 |
| open-gits upstream catalog | https://raw.githubusercontent.com/BRMSTE-SB/open-gits/main/catalog.json | 200 |
| mining-pools v2 | https://raw.githubusercontent.com/BRMSTE-SB/mining-pools/main/pools-v2.json | 200 |
| org mark | https://raw.githubusercontent.com/BRMSTE-SB/.github/main/assets/brmste-org-mark.svg | 200 |

---

## brmste.com edge (404 as of recheck)

| Path | HTTP |
|------|------|
| `/substrate/brmste/open-gits.json` | 404 |
| `/substrate/human/open-gits.json` | 404 |
| `/substrate/human/free.json` | 404 |
| `/substrate/keeper.json` | 404 |
| `/substrate/human/watch` | 404 |
| `/oracle.json` | 404 |
| `/substrate/patent-enforcement.json` | 404 |
| `/data/brmste-github-full-tune.json` | 404 |

open-gits README still references legacy `/substrate/human/*` paths — **edge not hydrated**.

---

## Rename map (EPIC / Human → BRMSTE Open)

| Legacy | Canonical |
|--------|-----------|
| Human Open | **BRMSTE Open** |
| `human_open` gate lane | **`brmste_open`** (alias kept) |
| EPIC | **BRMSTE Open** |
| `/substrate/human/open-gits.json` | `/substrate/brmste/open-gits.json` (GitHub mirror live) |
| `brmste-human-open-gits-catalog/v1` schema | `brmste-open-gits-catalog/v2` |

---

## Quick clone (all three core open repos)

```bash
git clone https://github.com/BRMSTE-SB/open-gits.git
git clone https://github.com/BRMSTE-SB/brmste-human-future.git
git clone https://github.com/BRMSTE-SB/mining-pools.git
```

Fetch live catalog:

```bash
curl -fsSL https://raw.githubusercontent.com/BRMSTE-SB/.github/main/substrate/brmste/open-gits.json | jq .
```

---

## PSD form download (fixed — `.github` now public)

```bash
curl -fsSL -o ~/Downloads/psd-individual-form-filled.docx \
  "https://raw.githubusercontent.com/BRMSTE-SB/.github/BRMSTE-CURSOR-ibm-vs-brmste-vs-meta-c677/fca/psd-individual-form-filled.docx"
```

Or GitHub Release (draft): https://github.com/BRMSTE-SB/.github/releases
