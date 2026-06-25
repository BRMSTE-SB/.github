# FULL OPEN FORT KNOX FOR PUBLIC

**BRMSTE LTD · Companies House 15310393 · GB2607860**

**FULL OPEN FORT KNOX FOR PUBLIC** means every Fort Knox **env var name**, Mac key path, connect script, and rail binding is published on the **human-open lane** — with **no secret values** on GitHub or `brmste.com/corpus`.

**EMPTY LEDGER = HONESTY** — structure is fully open; credentials stay local.

## Public register

| Item | Path |
|------|------|
| **Master catalog** | `data/fort-knox-public-open-register.json` |
| **Corpus URL** | https://brmste.com/corpus/fort-knox-public-open-register.json |
| **Substrate** | `substrate/fort-knox/public-open.json` |
| **Env template** | `.env.fort-knox.example` |

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
```

Default Mac keys base: `/Users/sachindabas/Desktop/API keys - Copy/`

## Related docs

- [FORT-KNOX-AI-KEYS-MAC.md](./FORT-KNOX-AI-KEYS-MAC.md)
- [FORT-KNOX-UTXO-HYDRATION.md](./FORT-KNOX-UTXO-HYDRATION.md)
- [FORT-KNOX-PAYPAL-MAC.md](./FORT-KNOX-PAYPAL-MAC.md)
- [OPERATOR-HYDRATION-CORPUS.md](./OPERATOR-HYDRATION-CORPUS.md)
- [PROJECT-GLASSWING-TRADEMARK.md](./PROJECT-GLASSWING-TRADEMARK.md)

## OPEN CORS

Fort Knox **metadata** is included in the public corpus sync (`scripts/sync-corpus-to-website.mjs`). Secret values are **never** published.

## Sign lines

**CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**
