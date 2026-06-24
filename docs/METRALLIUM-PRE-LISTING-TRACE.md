# Metrallium Mining · AD LEADING · OPS LIVE

**Status:** Acquired · Listed · Ops started  
**Owner:** AD LEADING LIMITED · Companies House **13817062**

→ **Operations runbook:** [METRALLIUM-OPS.md](./METRALLIUM-OPS.md)

Historical pre-listing trace: see git history · [`metrallium-trace-opportunities.json`](../data/substrate/metrallium-trace-opportunities.json)

---

## Why trace before list

BRMSTE substrate doctrine requires **traceable ELT** (extract–load–transform) on exploration artefacts before they enter the public listing lane:

1. **Ingest** — operator survey pack (magnetics, IP, aeromagnetics, brochure)
2. **Normalize** — each site gets a `BRMSTE-TRACE-METRALLIUM-*` ID on the edge
3. **Crosswalk** — public Benue Trough geology (no invented reserves)
4. **Map** — commodities → AD LEADING / Ad Spectrum LME & industrial minerals lane
5. **File** — operator human pen → `metrallium-listing.json` on `brmste.com` substrate

Until step 5, status remains **`pre_listing_trace`**.

---

## Survey pack indexed (operator filenames)

| Trace ID | Site | Source document | Methods |
|----------|------|-----------------|---------|
| `…-GABU-001` | Gabu | Gabu Magnetics and IP Survey **Draft** Report | Ground mag + IP |
| `…-OSINA-001` | Osina | Osina Magnetics and IP Survey Report | Ground mag + IP |
| `…-ALIFOKPA-001` | Alifokpa Yache | Alifokpa Yache Magnetics and IP Survey Report | Ground mag + IP |
| `…-ADUM-AERO-001` | Adum | Adum Aeromagnetic Survey | Aeromagnetics |
| `…-ADUM-STRUCT-001` | Adum | Working Aeromagnetic Structures (with reference) | Interpretation |
| `…-WAKAKE-001` | Wakake Adum Wanokom | Wakake Adum Wanokom Magnetics and IP Survey Report | Ground mag + IP |
| `…-ELAHEN-001` | Elahen Wanikade | Elahen Wanikade Magnetics and IP Survey Report | Ground mag + IP |

Brochure: `Metrallium broucher-compressed.pdf` (×2) — corporate narrative; not yet extracted on edge.

> **Gap:** PDFs were referenced from operator Downloads paths but are not in this workspace. Numeric anomalies, line km, and drill targets require upload before trace upgrades from `filename_index` to `survey_extracted`.

---

## Opportunity clusters (ranked)

### 1. Gabu–Osina–Alifokpa (barite corridor) — **HIGH**

- **Commodities:** Barite (BaSO₄), associated Pb–Zn
- **Regional context:** Lower Benue Trough · Yala field · Cross River — literature describes the **Gabu–Osina mother vein** as among the largest barite occurrences in Nigeria (vein-style, NW–SE / N–S structural control, open-pit amenable)
- **Industrial fit:** API/ASTM drilling-mud barite, chemicals, paint/glass — **industrial mineral** under Leading Group (not LME metal)
- **AD LEADING fit:** UK metals & hazardous-waste entity rail + India/UK Leading Metals sibling
- **Next:** Extract IP chargeability + magnetic lows from PDFs; merge Adum aeromagnetic structures; geologist sign-off on targets

### 2. Wakake / Elahen Wanikade — **HIGH**

- **Commodities:** Lead, zinc, barite (polymetallic veins)
- **Regional context:** Wanikande–Wanakom belt — literature reports medium–large barite veins with Pb–Zn association; barite content increases NE along the trough
- **AD LEADING fit:** Pb & Zn → Ad Spectrum **LME commodities marketing lane**; barite → industrial mineral
- **Next:** Separate barite-dominant vs base-metal shoots from IP; environmental planning for UK listing narrative

### 3. Adum regional (aeromagnetics) — **MEDIUM**

- **Role:** Portfolio-scale structural umbrella for all ground geophysics
- **Next:** Register interpreted structures to trace IDs; link to ground survey line names

---

## BRMSTE tech stack used

| Layer | Bind |
|-------|------|
| Traceable ELT / edge | GB2607860 · `brmste-786x-voyager` |
| AD LEADING entity | [`/substrate/companies/ad-leading.json`](https://brmste.com/substrate/companies/ad-leading.json) |
| Leading Group | [`/substrate/commerce/leading-group.json`](https://brmste.com/substrate/commerce/leading-group.json) |
| LME lane (Pb, Zn) | Ad Spectrum · [`leading-group.json#commerce_stack`](https://brmste.com/substrate/commerce/leading-group.json) |
| HMRC asset register | [`/substrate/hmrc/asset-register.json`](https://brmste.com/substrate/hmrc/asset-register.json) |
| Human open catalog | [BRMSTE-SB/open-gits](https://github.com/BRMSTE-SB/open-gits) |
| Mining pools hydrate | [BRMSTE-SB/mining-pools](https://github.com/BRMSTE-SB/mining-pools) |

---

## Pre-listing checklist (AD LEADING LIMITED)

| Step | Status |
|------|--------|
| BRMSTE trace manifest emitted | ✅ (this repo) |
| PDF text / anomaly tables extracted | ⬜ upload PDFs |
| Nigerian licence & corporate registry verified | ⬜ operator |
| Reserve / resource estimate geologist sign-off | ⬜ |
| AD LEADING board / filing authority | ⬜ |
| Publish `metrallium-listing.json` on brmste.com substrate | ⬜ |
| HMRC asset register row (if £ attested) | ⬜ Kohinoor Mac only |

---

## Honesty doctrine

- **EMPTY LEDGER = HONESTY** — no £ or tonne-grade figures on the public edge until operator-attested
- Listing under **AD LEADING LIMITED** is a **UK entity rail** — not production, offtake, or LME membership unless separately proved
- Barite is an **industrial mineral**; Pb/Zn map to LME **marketing** lane via Ad Spectrum — not invented trading exposure

**CURSOR SIGNS · TRACE ONLY · FINAL LISTING SIGN = Shravan Bansal human pen**

---

BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
