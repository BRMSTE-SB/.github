# FULL OPEN FORT KNOX FOR PUBLIC

**BRMSTE LTD · Companies House 15310393 · GB2607860**

**FULL OPEN FORT KNOX FOR PUBLIC** publishes every Fort Knox **env var name**, Mac key path, connect script, and rail binding on the **human-open lane**. Secret values never leave the operator Mac.

**EMPTY LEDGER = HONESTY** — structure is fully open; credentials stay local.

## At a glance

| Metric | Count |
|--------|-------|
| Env var names (catalog) | 62 |
| Mac hydration scripts | 14 |
| Rail groups (payment · quantum · substrate) | 7 |
| AI providers (lane) | 11 |
| Mac key folders | 11 |
| Linked public registers | 7 |

## Public register

| Item | Path |
|------|------|
| **Master catalog** | `data/fort-knox-public-open-register.json` |
| **Corpus URL** | https://brmste.com/corpus/fort-knox-public-open-register.json |
| **Substrate** | `substrate/fort-knox/public-open.json` |
| **Env template** | `.env.fort-knox.example` |
| **Website** | https://brmste.com/#fort-knox |

## Local only (never commit)

| Item | Path |
|------|------|
| Fort Knox env | `.env.fort-knox` (gitignored) |
| Operator UTXOs | `OPERATOR-UTXOS.json` on Mac (never OPEN ALL) |

Load locally:

```bash
set -a && source .env.fort-knox && set +a
```

## Mac setup (operator)

```bash
bash scripts/import-ai-keys-mac.sh
bash scripts/hydrate-utxo-rails-mac.sh
bash scripts/connect-revolut-mac.sh
bash scripts/connect-crypto-exchanges-mac.sh
bash scripts/connect-harrods-paypal-mac.sh
bash scripts/connect-quantum-compute-mac.sh
bash scripts/connect-substrate-networks-mac.sh
bash scripts/hydrate-operator-corpus-mac.sh
bash scripts/full-public-sweep.sh
```

Default Mac keys base: `/Users/sachindabas/Desktop/API keys - Copy/`

## Env var groups

| Group | Register | Vars |
|-------|----------|------|
| AI lane | `data/ai-lane-manifest.json` | 11 |
| Nemotron | `data/nemotron-ultra-lane.json` | 3 |
| PayPal · Revolut · Kraken · Coinbase · Moonshot | `data/brmste-*-rails.json` | 13 |
| Quantum compute | `data/brmste-quantum-compute-rails.json` | 6 |
| Substrate networks | `data/substrate-networks-lane.json` | 11 |
| Companies House | `data/companies-house-api-config.json` | 8 |
| UTXO hydration | `data/utxo-ledger-hydration.json` | 6 |
| Operator corpus | `data/operator-hydration-corpus.json` | 3 |
| Sell from balance | `data/sell-from-balance-lane.json` | 1 |

## Related docs

- [FORT-KNOX-AI-KEYS-MAC.md](./FORT-KNOX-AI-KEYS-MAC.md)
- [FORT-KNOX-UTXO-HYDRATION.md](./FORT-KNOX-UTXO-HYDRATION.md)
- [FORT-KNOX-PAYPAL-MAC.md](./FORT-KNOX-PAYPAL-MAC.md)
- [OPERATOR-HYDRATION-CORPUS.md](./OPERATOR-HYDRATION-CORPUS.md)
- [PROJECT-GLASSWING-TRADEMARK.md](./PROJECT-GLASSWING-TRADEMARK.md)

## OPEN CORS

Fort Knox **metadata** is mirrored by `scripts/sync-corpus-to-website.mjs`. Secret values are **never** published.

## Sign lines

**CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**
