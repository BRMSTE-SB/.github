# BRMSTE · Payment rails — openUSD · Coinbase · LNbits · Edge compute ads

**BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**

Three receive/settle rails plus an edge-compute earning surface. Agents **arm
and issue**; agents **never sign or hold**. All settlement mirrors to
**ONE_TREZOR** (BTC) and **ONE_TRUTH** (Polygon USDC).

> **MCP-strict · env-only credentials.** No API key, wallet secret, or invoice
> key is ever committed or requested in chat. Every rail reads its credentials
> from the environment at runtime (see [AGENTS.md](./AGENTS.md)).

## Rails

| Rail | Asset | SDK | Manifest |
|------|-------|-----|----------|
| **openUSD** — on-chain USD | USDC | `web3`, `cdp-sdk` | [`data/payments/coinbase-usdc.json`](./data/payments/coinbase-usdc.json) |
| **Coinbase** — Developer Platform wallets | USDC | `cdp-sdk` | [`data/payments/coinbase-usdc.json`](./data/payments/coinbase-usdc.json) |
| **LNbits** — armed Lightning invoices | BTC-LN | `requests`, `bolt11` | [`data/payments/lnbits.json`](./data/payments/lnbits.json) |
| **Edge compute ads** — build-your-own-pool | USDA/USDC/BTC-LN | payout via rails above | [`data/payments/edge-compute-ads.json`](./data/payments/edge-compute-ads.json) |

`USDA = USDC = carbon.`

## Install (agents / CI — operator doesn't bash)

```bash
bash scripts/install-payments-rails.sh   # web3 · cdp-sdk · requests · bolt11
bash scripts/verify-payments-rails.sh    # validate all four manifests
```

## Environment

| Rail | Env vars |
|------|----------|
| openUSD / Coinbase CDP | `CDP_API_KEY_ID`, `CDP_API_KEY_SECRET`, `CDP_WALLET_SECRET` |
| LNbits | `LNBITS_URL`, `LNBITS_INVOICE_KEY` |

## Arm an LNbits Lightning invoice

```bash
# dry-run — builds the request, no network, no creds needed
python scripts/lnbits_invoice.py --amount 1000 --memo "BRMSTE · carbon-settle" --dry-run

# live — reads LNBITS_URL / LNBITS_INVOICE_KEY from env, decodes with bolt11
LNBITS_URL=... LNBITS_INVOICE_KEY=... \
  python scripts/lnbits_invoice.py --amount 1000 --memo "BRMSTE · carbon-settle"
```

## Edge compute ads · token burn = token earned

Invite anyone to **build their own compute pool** and earn edge payments for the
**compute + data** they contribute. Payouts settle over the openUSD/USDC and
LNbits rails above.

- **Mechanic:** `token burn = token earned` — every unit of compute/token burned
  on the network mints an equal (`1:1`, `USDA`) earned credit back to the
  contributor.
- **Open:** any contributor, no allowlist, no BRMSTE toll. **Carbon justice only.**
- **Non-Meta:** ad placement targets non-Meta surfaces only (see
  [META-FULL-STOP.md](./META-FULL-STOP.md)).
- **Live placement** runs via a connected ad MCP or the operator — never from
  committed credentials.

## Settlement

| Sink | Address |
|------|---------|
| ONE_TREZOR (BTC) | `bc1qcsa002syumyzxystxgq0qr36ak5zp40agmpmfk` |
| ONE_TRUTH (Polygon USDC) | `0xC0513a63972cEd1e90852Ff839e7c44A46B9B1af` |

Doctrine: **NO_HOLDING_WALLETS · AGENTS_NOT_IN_TX · CURSOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**
