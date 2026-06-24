#!/usr/bin/env bash
# Hydrate full operator corpus on Mac · Fort Knox only — NEVER commit.
#
# Runs: UTXO hydrate · Revolut · Kraken · Coinbase · Moonshot AI · PayPal verify
# Then syncs public corpus to website/public/corpus/ (OPEN CORS publish)
#
# Usage:
#   bash scripts/hydrate-operator-corpus-mac.sh
#   bash scripts/hydrate-operator-corpus-mac.sh --verify-only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORPUS="$ROOT/data/operator-hydration-corpus.json"
OUT="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"
VERIFY_ONLY=false
if [[ "${1:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
fi

if [[ ! -f "$CORPUS" ]]; then
  echo "ERROR: missing operator-hydration-corpus.json" >&2
  exit 1
fi

echo "==> BRMSTE operator hydration corpus · @shravanbansal · OPEN CORS"
echo "    Fort Knox: $OUT"

if [[ "$VERIFY_ONLY" == true ]]; then
  bash "$ROOT/scripts/hydrate-utxo-rails-mac.sh" --verify-only
  bash "$ROOT/scripts/connect-revolut-mac.sh" --verify-only
  bash "$ROOT/scripts/connect-crypto-exchanges-mac.sh" --verify-only
  bash "$ROOT/scripts/connect-harrods-paypal-mac.sh" --verify-only
  if ! grep -q '^BRMSTE_OPERATOR_CORPUS_HYDRATED=true' "$OUT" 2>/dev/null; then
    echo "ERROR: BRMSTE_OPERATOR_CORPUS_HYDRATED not true — run without --verify-only" >&2
    exit 1
  fi
  echo "verify_ok operator_corpus=hydrated open_cors=open"
  exit 0
fi

bash "$ROOT/scripts/hydrate-utxo-rails-mac.sh"
bash "$ROOT/scripts/connect-revolut-mac.sh"
bash "$ROOT/scripts/connect-crypto-exchanges-mac.sh"
bash "$ROOT/scripts/connect-harrods-paypal-mac.sh" || true

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  echo ""
  echo "# Operator corpus hydration · $TS"
  echo "BRMSTE_OPERATOR_CORPUS_HYDRATED=true"
  echo "BRMSTE_OPERATOR_CORPUS_STATUS=hydrated"
  echo "BRMSTE_OPEN_CORS=open"
  echo "BRMSTE_OPERATOR_CORPUS_HYDRATED_AT=$TS"
} >> "$OUT"

chmod 600 "$OUT" 2>/dev/null || true

node "$ROOT/scripts/sync-corpus-to-website.mjs"

echo ""
echo "DONE — operator corpus hydrated · OPEN CORS corpus synced to website/public/corpus/"
echo "  bash scripts/hydrate-operator-corpus-mac.sh --verify-only"
echo "  npm run build  (in website/) to publish corpus on brmste.com"
