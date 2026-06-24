# Revolut hydrate · @shravanbansal full corpus

Operator **Dr. Shravan Bansal** (`@shravanbansal` · [LinkedIn](https://www.linkedin.com/in/shravanbansall/)) — full Revolut hydration corpus across UTXO ledger, Fort Knox credentials, and public registers.

## What “full corpus” means

| Layer | Action | Result |
|-------|--------|--------|
| UTXO hydrate | `hydrate-utxo-rails-mac.sh` | `BRMSTE_REVOLUT_HYDRATED=true` |
| Revolut connect | `connect-revolut-mac.sh` | Live Business API keys in Fort Knox |
| Public registers | JSON corpus in repo | Sweep + brmste.com lane bound |

**Does not move fiat automatically** — see [FORT-KNOX-UTXO-HYDRATION.md](./FORT-KNOX-UTXO-HYDRATION.md).

## Mac sequence (Fort Knox only)

```bash
# 1. UTXO flags for all three rails
bash scripts/hydrate-utxo-rails-mac.sh
bash scripts/hydrate-utxo-rails-mac.sh --verify-only

# 2. Revolut Business API keys
bash scripts/connect-revolut-mac.sh
bash scripts/connect-revolut-mac.sh --verify-only
# Expect: revolut_api=ok live_api_reachable
```

## Revolut key folder

```
/Users/sachindabas/Desktop/API keys - Copy/Revolut/
├── REVOLUT-API-KEY.txt
├── REVOLUT-MERCHANT-ID.txt
├── REVOLUT-WEBHOOK-SECRET.txt   (optional)
└── BRMSTE-REVOLUT-EMAIL.txt     (optional)
```

## Registers (full corpus)

| File | Role |
|------|------|
| `data/revolut-hydration-corpus.json` | Master corpus · @shravanbansal |
| `data/revolut-lane.json` | Platform lane |
| `data/brmste-revolut-rails.json` | Banking rails |
| `data/utxo-ledger-hydration.json` | UTXO master hydration |
| `substrate/payments/revolut-rails.json` | Substrate mirror |

## Bound lanes

- **Secret Benefits** — PayPal + Revolut payment rails
- **Operator profile** — handle + Revolut corpus ref
- **OPEN ALL** — `revolut_hydration_corpus` block

BRMSTE LTD · Companies House 15310393
