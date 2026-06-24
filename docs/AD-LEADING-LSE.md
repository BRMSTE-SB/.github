# AD LEADING LIMITED · LSE Lane · leadingmetals.com

**Entity:** AD LEADING LIMITED · Companies House **13817062**  
**Hostname:** [leadingmetals.com](https://leadingmetals.com/)  
**Edge page:** `/leadingmetals` · ticker API `/api/gi/leadingmetals/tickers`

## Important honesty note

Public records (Companies House, LSE search as of 2026-06-24) show **AD LEADING LIMITED as a UK private limited company**, not a confirmed Main Market or AIM listing with live exchange quotes.

This repository publishes:

| Item | Meaning |
|------|---------|
| **Reserved tickers** `ADLD` (equity) · `ADLG` (green bond) | Live on **BRMSTE substrate edge** and leadingmetals.com UI |
| **quote_live: false** | No fabricated last price — official LSE feed pending |
| **Operator attested** | Listing pathway acknowledged; RNS + ISIN required to flip live |

**Do not treat reserved symbols as exchange-confirmed until RNS is published.**

## Manifests

| File | Purpose |
|------|---------|
| [`data/substrate/ad-leading-lse.json`](../data/substrate/ad-leading-lse.json) | LSE lane · tickers · verification policy |
| [`data/substrate/leadingmetals-green-ops.json`](../data/substrate/leadingmetals-green-ops.json) | Green recycling + green mining ops |
| `coming-soon/site/leadingmetals.html` | Public surface (deploy to leadingmetals.com / edge) |

## Green ops stack

### Battery recycling

- **Leading Metalloys LLP** (India) — lead-acid battery recycling · [leadingmetalloys.com](https://leadingmetalloys.com/)
- **AD LEADING LIMITED** — UK hazardous waste SIC 38120 / 38220
- **GB2607860** — traceable ELT audit trail on BRMSTE edge
- **RE-TYRE FINANCE LIMITED** — circular economy rail

### Green mining

- **Metrallium Mining Company Ltd** — acquired · 6 active sites · [METRALLIUM-OPS.md](./METRALLIUM-OPS.md)

## Visual assets (nano-banana lane)

Generated green-ops art in `coming-soon/site/public/assets/leadingmetals/`:

- `hero.png` — green recycling + mining banner
- `battery-recycle-icon.png` — battery recycling mark

## LSE admission checklist (operator)

1. Appoint sponsor / nomad (if AIM)
2. Admission document or prospectus
3. Obtain **ISIN** and **SEDOL**
4. **RNS** announcement on admission
5. Update `ad-leading-lse.json`:
   - `tickers.equity.isin`
   - `tickers.equity.rns_url`
   - `tickers.equity.status` → `quote_live_true`
6. Sync leadingmetals.com ticker API from RNS bind

## Verify

```bash
bash scripts/verify-leadingmetals-lse.sh
```

---

BRMSTE LTD · GB2607860 · AD LEADING LIMITED · 13817062
