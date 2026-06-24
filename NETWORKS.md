<div align="center">

<img src="assets/brmste-networks.svg" alt="BRMSTE Networks — 8^8 = 16,777,216 vision-tuned networks" width="880"/>

# BRMSTE Networks

**BRMSTE LTD · [Companies House 15310393](https://find-and-update.company-information.service.gov.uk/company/15310393) · GB2607860**

*The BRMSTE posture over the public Bitcoin and Lightning networks — the same transparent pane the [Edge Glass](https://brmste.com/edge-glass/) holds over Bitcoin value and cash flows.*

**Live page:** [brmste.com/networks](https://brmste.com/networks) · source & deploy: [`site/networks/`](site/networks/)

</div>

---

## The constant: 8^8 = 16,777,216

The BRMSTE Networks vision is tuned to a single number:

```
8^8  =  2^24  =  16,777,216
```

This identity is **machine-verified on every hydration run** ([`scripts/hydrate.py`](scripts/hydrate.py) asserts `8 ** 8 == 16_777_216 == 2 ** 24` and records `"verified": true` in [`open-software/networks.json`](open-software/networks.json)). It is also the size of the 24-bit space (16,777,216 distinct values) — a real, checkable bound, not a slogan.

- **Vision unit:** `8^8 = 16,777,216` vision-tuned networks.
- **Vision scale (the "16,777,216K"):** `16,777,216 × 1000 = 16,777,216,000`.

These are stated **targets**. The numbers below are the **live reality** — kept strictly separate so the vision can never be mistaken for a measurement.

---

## Live network reality (hydrated)

Pulled from [mempool.space](https://mempool.space/lightning) and refreshed by the hydrator into [`open-software/networks.json`](open-software/networks.json). Figures are volatile; this page links to live sources rather than freezing stale numbers.

| Layer | What we observe | Live source |
|-------|-----------------|-------------|
| **Bitcoin Lightning** | node count, channel count, total capacity (BTC), tor/clearnet split | [mempool.space/lightning](https://mempool.space/lightning) · [stats API](https://mempool.space/api/v1/lightning/statistics/latest) |
| **Bitcoin on-chain** | declared BRMSTE address — transaction count and balance | [mempool.space address](https://mempool.space/address/bc1qkqy9tna45dl3fhknpvmlpx2a044a95h5lza77d) |

> **Honesty note:** the declared on-chain address is a **valid, verifiable Bitcoin address** that currently shows **0 transactions / 0 balance**. The hydrator records this exactly (`"funded": false`) — it is not presented as a funded reserve.

For the most recent snapshot (capacity, node/channel counts, on-chain status, with a timestamp), read [`open-software/networks.json`](open-software/networks.json) or run:

```bash
python3 scripts/hydrate.py          # refresh networks.json from mempool.space
curl -s https://mempool.space/api/v1/lightning/statistics/latest | python3 -m json.tool
```

---

## How BRMSTE Networks stays honest

1. **Probe** — `mempool.space/lightning` and its stats API are probed over HTTPS; their status appears in [`STATUS.md`](STATUS.md).
2. **Hydrate** — live Lightning + on-chain figures are written to [`open-software/networks.json`](open-software/networks.json).
3. **Verify** — the `8^8 = 16,777,216` identity is asserted in code; if it ever failed, `verified` would flip to `false`.

Nothing on this page is asserted as live unless it returns `200`, and no figure is frozen where a live source exists.

---

<div align="center">

**8^8 = 16,777,216 · Bitcoin · Lightning · settled to the trust**

**CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**

</div>
