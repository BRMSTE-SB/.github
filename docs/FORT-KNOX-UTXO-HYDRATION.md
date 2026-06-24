# Fort Knox · UTXO hydration · PayPal · Moonshot · Revolut (Mac)

Operator **UTXOs** hydrate the PayPal, Moonshot, and Revolut rails locally. **UTXO data never goes on OPEN ALL.**

## UTXO ledger file (Mac)

```
/Users/sachindabas/Desktop/API keys - Copy/UTXOs/
└── OPERATOR-UTXOS.json
```

Example shape:

```json
{
  "schema": "brmste-operator-utxos/v1",
  "operator": "Dr. Shravan Bansal · BRMSTE LTD",
  "utxos": [
    {
      "txid": "your-txid-hex",
      "vout": 0,
      "amount_sats": 100000,
      "address": "your-address"
    }
  ]
}
```

## Hydrate rails

From a clone of [BRMSTE-SB/.github](https://github.com/BRMSTE-SB/.github):

```bash
bash scripts/hydrate-utxo-rails-mac.sh
```

Custom folder:

```bash
BRMSTE_UTXO_DIR="/path/to/UTXOs" bash scripts/hydrate-utxo-rails-mac.sh
```

Merges hydration markers into `.env.fort-knox` alongside PayPal and AI keys.

## Verify

```bash
set -a && source .env.fort-knox && set +a
bash scripts/hydrate-utxo-rails-mac.sh --verify-only
```

## Public registers (no UTXO data)

| Rail | Register |
|------|----------|
| Master hydration | `data/utxo-ledger-hydration.json` |
| PayPal | `data/brmste-paypal-rails.json` |
| Moonshot | `data/brmste-moonshot-payment-rails.json` |
| Revolut | `data/brmste-revolut-rails.json` |

## Revolut connect (full corpus · @shravanbansal)

After UTXO hydrate, connect Revolut Business API keys:

```bash
bash scripts/connect-revolut-mac.sh
bash scripts/connect-revolut-mac.sh --verify-only
```

See [REVOLUT-HYDRATION-CORPUS.md](./REVOLUT-HYDRATION-CORPUS.md) for the full register map.

## Revolut keys (optional Mac folder)

```
/Users/sachindabas/Desktop/API keys - Copy/Revolut/
├── REVOLUT-API-KEY.txt
├── REVOLUT-MERCHANT-ID.txt
└── REVOLUT-WEBHOOK-SECRET.txt
```

Add to `.env.fort-knox` manually or run:

```bash
bash scripts/connect-revolut-mac.sh
```

Credentials stay Fort Knox only.

## Why accounts decline · money not showing

**Hydration does not move money.** Running `hydrate-utxo-rails-mac.sh` only:

1. Confirms `OPERATOR-UTXOS.json` exists on your Mac
2. Sets Fort Knox flags (`BRMSTE_PAYPAL_HYDRATED=true`, etc.)
3. Updates public **register status** in git (`hydrated`) — documentary only

It does **not** send Bitcoin, convert UTXOs to GBP/USD, or deposit into PayPal, Revolut, Moonshot, or Secret Benefits balances.

| What you see in repo | What it means | What it does *not* mean |
|----------------------|---------------|-------------------------|
| `status: "hydrated"` | Local Fort Knox + sweep passed | Fiat balance in PayPal/Revolut |
| `status: "connected"` (PayPal) | Rail register bound | Live merchant payouts working |
| Equity 100% registers | Operator declaration | Payment processor onboarding complete |

**Typical causes of declines**

- PayPal: missing `connect-harrods-paypal-mac.sh`, sandbox keys on live API, or merchant verification incomplete
- Revolut: no live API keys in `.env.fort-knox` (no auto-import script yet — add `REVOLUT_API_KEY` manually)
- Secret Benefits / BASEF LTD: card issuer or platform risk rules (Cyprus entity, MCC) — contact platform support, not the hydration script
- Moonshot: separate billing account — UTXO hydration does not fund Kimi API usage

**Verify on your Mac (Fort Knox only)**

```bash
bash scripts/hydrate-utxo-rails-mac.sh --verify-only
bash scripts/connect-harrods-paypal-mac.sh --verify-only
# Expect: paypal_oauth=ok live_api_reachable after connect (not after hydrate alone)
```

Balances appear only after real payments settle on each processor, or you log into PayPal / Revolut / the platform directly.

## Security

- Never commit `OPERATOR-UTXOS.json` or `.env.fort-knox`
- Rotate any key or UTXO detail shared in chat
- Public lane = register **status** only (`hydrated`)

BRMSTE LTD · Companies House 15310393
