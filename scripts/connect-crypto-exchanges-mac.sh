#!/usr/bin/env bash
# Connect all BRMSTE crypto channels: Kraken · Coinbase · Moonshot (AI verify).
# Fort Knox only — NEVER commit. Does NOT trade or withdraw BTC.
#
# Usage on Mac:
#   bash scripts/connect-crypto-exchanges-mac.sh
#   bash scripts/connect-crypto-exchanges-mac.sh --verify-only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERIFY_FLAG=""
if [[ "${1:-}" == "--verify-only" ]]; then
  VERIFY_FLAG="--verify-only"
fi

echo "==> BRMSTE crypto channels · Kraken · Coinbase · Moonshot"
echo "    BTC → fiat → Revolut: use Kraken or Coinbase (not Moonshot AI)"
echo ""

bash "$ROOT/scripts/connect-kraken-mac.sh" $VERIFY_FLAG
echo ""
bash "$ROOT/scripts/connect-coinbase-mac.sh" $VERIFY_FLAG
echo ""

if [[ -n "$VERIFY_FLAG" ]]; then
  if ! grep -q '^MOONSHOT_API_KEY=' "${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}" 2>/dev/null; then
    echo "WARN: MOONSHOT_API_KEY missing — run: bash scripts/import-ai-keys-mac.sh"
  else
    echo "moonshot_ai=ok key_present (Kimi API — not BTC exchange)"
  fi
else
  echo "==> Moonshot (Kimi AI API — not exchange)"
  bash "$ROOT/scripts/import-ai-keys-mac.sh" 2>/dev/null || echo "WARN: import-ai-keys-mac.sh skipped"
fi

echo ""
echo "Next for BTC → Revolut:"
echo "  1. Deposit/sell BTC on Kraken or Coinbase (app or exchange UI)"
echo "  2. Withdraw GBP/EUR to Revolut Business bank details"
echo "  3. bash scripts/connect-revolut-mac.sh --verify-only"
echo ""
echo "See docs/CRYPTO-EXCHANGE-CHANNELS.md"
