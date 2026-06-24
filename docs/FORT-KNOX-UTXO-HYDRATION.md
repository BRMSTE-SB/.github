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

## Revolut keys (optional Mac folder)

```
/Users/sachindabas/Desktop/API keys - Copy/Revolut/
├── REVOLUT-API-KEY.txt
├── REVOLUT-MERCHANT-ID.txt
└── REVOLUT-WEBHOOK-SECRET.txt
```

Add to `.env.fort-knox` manually or extend the hydrate script folder — credentials stay Fort Knox only.

## Security

- Never commit `OPERATOR-UTXOS.json` or `.env.fort-knox`
- Rotate any key or UTXO detail shared in chat
- Public lane = register **status** only (`hydrated`)

BRMSTE LTD · Companies House 15310393
