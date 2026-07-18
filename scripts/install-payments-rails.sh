#!/usr/bin/env bash
# Install BRMSTE payment-rail SDKs: openUSD (web3), Coinbase CDP (cdp-sdk),
# and LNbits Lightning invoice client (requests + bolt11).
# MCP-strict: this installs SDKs only. It never collects or writes credentials.
# Credentials are read from the environment at runtime (see AGENTS.md).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PYTHON:-python3}"
VENV="${PAYMENTS_VENV:-$ROOT/.venv-payments}"

echo "BRMSTE payments-rails install → $VENV"

"$PY" -m venv "$VENV"
# shellcheck disable=SC1091
source "$VENV/bin/activate"

pip install --upgrade pip >/dev/null

# openUSD / on-chain USD + Coinbase CDP + LNbits client
pip install \
  "cdp-sdk" \
  "web3" \
  "requests" \
  "bolt11"

echo "--- installed versions ---"
python - <<'PY'
import importlib.metadata as m
for pkg in ("cdp-sdk", "web3", "requests", "bolt11"):
    print(f"{pkg} == {m.version(pkg)}")
PY

echo "BRMSTE payments-rails install OK"
echo "Next: bash scripts/verify-payments-rails.sh"
echo "Arm LNbits invoices: LNBITS_URL=... LNBITS_INVOICE_KEY=... python scripts/lnbits_invoice.py --amount 1000 --memo 'BRMSTE'"
