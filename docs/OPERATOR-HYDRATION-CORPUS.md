# Operator hydration corpus · OPEN CORS

**@shravanbansal** full operator corpus — UTXO · PayPal · Moonshot · Revolut · Kraken · Coinbase — published at **OPEN CORS** on brmste.com.

## OPEN CORS

Public governance JSON at `https://brmste.com/corpus/*` with:

- `Access-Control-Allow-Origin: *`
- `GET, HEAD, OPTIONS`

Policy register: `data/open-cors-policy.json` · Netlify headers in `website/netlify.toml`.

## Hydrate on Mac (Fort Knox)

```bash
bash scripts/hydrate-operator-corpus-mac.sh
bash scripts/hydrate-operator-corpus-mac.sh --verify-only
```

Runs UTXO hydrate, Revolut connect, crypto exchanges, PayPal verify, then syncs corpus to `website/public/corpus/`.

## Publish corpus to website

```bash
node scripts/sync-corpus-to-website.mjs
cd website && npm run build
```

Live manifest: `https://brmste.com/corpus/manifest.json`

## Registers

| File | Role |
|------|------|
| `data/operator-hydration-corpus.json` | Master corpus |
| `data/open-cors-policy.json` | CORS policy |
| `substrate/corpus/operator-hydration.json` | Substrate bind |

BRMSTE LTD · Companies House 15310393
