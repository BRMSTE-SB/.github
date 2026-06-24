#!/usr/bin/env bash
# Connect BRMSTE Coinbase exchange channel · Fort Knox only — NEVER commit.
#
# Default folder (Mac):
#   /Users/sachindabas/Desktop/API keys - Copy/Coinbase
#
# Usage:
#   bash scripts/connect-coinbase-mac.sh
#   bash scripts/connect-coinbase-mac.sh --verify-only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RAILS="$ROOT/data/brmste-coinbase-rails.json"
OUT="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"

COINBASE_DIR="${1:-${BRMSTE_COINBASE_DIR:-/Users/sachindabas/Desktop/API keys - Copy/Coinbase}}"
VERIFY_ONLY=false
if [[ "${1:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
  COINBASE_DIR="${BRMSTE_COINBASE_DIR:-/Users/sachindabas/Desktop/API keys - Copy/Coinbase}"
elif [[ "${2:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
fi

if [[ ! -f "$RAILS" ]]; then
  echo "ERROR: missing Coinbase rail register." >&2
  exit 1
fi

echo "==> BRMSTE Coinbase exchange channel connect"
echo "    Keys: $COINBASE_DIR"
echo "    Fort Knox: $OUT"

python3 - <<'PY' "$RAILS" "$COINBASE_DIR" "$OUT" "$VERIFY_ONLY"
import base64, hashlib, hmac, json, pathlib, re, sys, time, urllib.request

rails_path, coinbase_dir, out_path, verify_only = (
    pathlib.Path(sys.argv[1]),
    pathlib.Path(sys.argv[2]),
    pathlib.Path(sys.argv[3]),
    sys.argv[4].lower() == "true",
)
rails = json.loads(rails_path.read_text())

file_map = {
    "COINBASE_API_KEY": "COINBASE-API-KEY.txt",
    "COINBASE_API_SECRET": "COINBASE-API-SECRET.txt",
    "COINBASE_API_PASSPHRASE": "COINBASE-PASSPHRASE.txt",
}

def read_key(path: pathlib.Path) -> str:
    if not path.is_file():
        return ""
    raw = path.read_text(encoding="utf-8", errors="replace").strip()
    for line in raw.splitlines():
        line = line.strip().strip('"').strip("'")
        if line and not line.startswith("#"):
            return re.sub(r"[\r\n]", "", line)
    return ""

existing = {}
if out_path.is_file():
    for line in out_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        existing[k.strip()] = v.strip()

new_vars = {}
for env_var, fname in file_map.items():
    val = read_key(coinbase_dir / fname)
    if val:
        new_vars[env_var] = val

merged = {**existing, **new_vars}

if verify_only:
    for r in ("COINBASE_API_KEY", "COINBASE_API_SECRET"):
        if not merged.get(r):
            raise SystemExit(f"verify fail: missing {r}")
    if merged.get("BRMSTE_COINBASE_CONNECTED") != "true":
        raise SystemExit("verify fail: run connect-coinbase-mac.sh first")
    print("verify_ok coinbase=connected")
    sys.exit(0)

skip_keys = list(file_map.keys()) + ["BRMSTE_COINBASE_CONNECTED", "BRMSTE_COINBASE_CONNECTED_AT"]
skip_prefixes = tuple(f"{k}=" for k in skip_keys)
keep = []
if out_path.is_file():
    for line in out_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if any(line.startswith(p) for p in skip_prefixes):
            continue
        keep.append(line)

from datetime import datetime, timezone
ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
lines = keep + [
    "",
    f"# Coinbase connect · {ts}",
    f"# coinbase_dir={coinbase_dir}",
]
for k in file_map:
    if merged.get(k):
        lines.append(f"{k}={merged[k]}")
lines.append("BRMSTE_COINBASE_CONNECTED=true")
lines.append(f"BRMSTE_COINBASE_CONNECTED_AT={ts}")
out_path.write_text("\n".join(lines).strip() + "\n", encoding="utf-8")

key = merged.get("COINBASE_API_KEY", "")
secret = merged.get("COINBASE_API_SECRET", "")
passphrase = merged.get("COINBASE_API_PASSPHRASE", "")
if key and secret:
  try:
    method = "GET"
    path = "/accounts"
    timestamp = str(int(time.time()))
    message = timestamp + method + path
    hmac_key = base64.b64decode(secret)
    signature = base64.b64encode(hmac.new(hmac_key, message.encode(), hashlib.sha256).digest()).decode()
    req = urllib.request.Request(
        f"https://api.exchange.coinbase.com{path}",
        headers={
            "CB-ACCESS-KEY": key,
            "CB-ACCESS-SIGN": signature,
            "CB-ACCESS-TIMESTAMP": timestamp,
            "CB-ACCESS-PASSPHRASE": passphrase,
        },
        method=method,
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        body = json.loads(resp.read().decode())
    if isinstance(body, list):
        print(f"coinbase_api=ok exchange_accounts={len(body)}")
    else:
        print(f"coinbase_api=warn response={str(body)[:120]}")
  except Exception as e:
    print(f"coinbase_api=skip ({type(e).__name__}) — try CDP keys or check Fort Knox")

print(f"status={rails['status']}")
PY

chmod 600 "$OUT" 2>/dev/null || true
echo "DONE — verify: bash scripts/connect-coinbase-mac.sh --verify-only"
