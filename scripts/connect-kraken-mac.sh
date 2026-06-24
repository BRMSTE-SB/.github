#!/usr/bin/env bash
# Connect BRMSTE Kraken exchange channel · Fort Knox only — NEVER commit.
#
# Default folder (Mac):
#   /Users/sachindabas/Desktop/API keys - Copy/Kraken
#
# Usage:
#   bash scripts/connect-kraken-mac.sh
#   bash scripts/connect-kraken-mac.sh --verify-only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RAILS="$ROOT/data/brmste-kraken-rails.json"
OUT="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"

KRAKEN_DIR="${1:-${BRMSTE_KRAKEN_DIR:-/Users/sachindabas/Desktop/API keys - Copy/Kraken}}"
VERIFY_ONLY=false
if [[ "${1:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
  KRAKEN_DIR="${BRMSTE_KRAKEN_DIR:-/Users/sachindabas/Desktop/API keys - Copy/Kraken}"
elif [[ "${2:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
fi

if [[ ! -f "$RAILS" ]]; then
  echo "ERROR: missing Kraken rail register." >&2
  exit 1
fi

echo "==> BRMSTE Kraken exchange channel connect"
echo "    Keys: $KRAKEN_DIR"
echo "    Fort Knox: $OUT"

python3 - <<'PY' "$RAILS" "$KRAKEN_DIR" "$OUT" "$VERIFY_ONLY"
import base64, hashlib, hmac, json, pathlib, re, sys, time, urllib.request

rails_path, kraken_dir, out_path, verify_only = (
    pathlib.Path(sys.argv[1]),
    pathlib.Path(sys.argv[2]),
    pathlib.Path(sys.argv[3]),
    sys.argv[4].lower() == "true",
)
rails = json.loads(rails_path.read_text())

file_map = {
    "KRAKEN_API_KEY": "KRAKEN-API-KEY.txt",
    "KRAKEN_API_SECRET": "KRAKEN-API-SECRET.txt",
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
    val = read_key(kraken_dir / fname)
    if val:
        new_vars[env_var] = val

merged = {**existing, **new_vars}

if verify_only:
    for r in ("KRAKEN_API_KEY", "KRAKEN_API_SECRET"):
        if not merged.get(r):
            raise SystemExit(f"verify fail: missing {r}")
    if merged.get("BRMSTE_KRAKEN_CONNECTED") != "true":
        raise SystemExit("verify fail: run connect-kraken-mac.sh first")
    print("verify_ok kraken=connected")
    sys.exit(0)

skip_prefixes = tuple(f"{k}=" for k in file_map) + (
    "BRMSTE_KRAKEN_CONNECTED=",
    "BRMSTE_KRAKEN_CONNECTED_AT=",
)
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
    f"# Kraken connect · {ts}",
    f"# kraken_dir={kraken_dir}",
]
for k in file_map:
    if merged.get(k):
        lines.append(f"{k}={merged[k]}")
lines.append("BRMSTE_KRAKEN_CONNECTED=true")
lines.append(f"BRMSTE_KRAKEN_CONNECTED_AT={ts}")
out_path.write_text("\n".join(lines).strip() + "\n", encoding="utf-8")

key = merged.get("KRAKEN_API_KEY", "")
secret = merged.get("KRAKEN_API_SECRET", "")
if key and secret:
    try:
        api_path = "/0/private/Balance"
        nonce = str(int(time.time() * 1000))
        postdata = f"nonce={nonce}"
        message = api_path.encode() + hashlib.sha256((nonce + postdata).encode()).digest()
        sig = base64.b64encode(
            hmac.new(base64.b64decode(secret), message, hashlib.sha512).digest()
        ).decode()
        req = urllib.request.Request(
            f"https://api.kraken.com{api_path}",
            data=postdata.encode(),
            headers={"API-Key": key, "API-Sign": sig, "Content-Type": "application/x-www-form-urlencoded"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=20) as resp:
            body = json.loads(resp.read().decode())
        if "result" in body:
            btc = body.get("result", {}).get("XXBT", body.get("result", {}).get("BTC", "?"))
            print(f"kraken_api=ok balance_btc_field={btc}")
        else:
            print(f"kraken_api=warn response={str(body)[:120]}")
    except Exception as e:
        print(f"kraken_api=skip ({type(e).__name__}) — check keys in Fort Knox")

print(f"rail=Kraken status={rails['status']}")
PY

chmod 600 "$OUT" 2>/dev/null || true
echo "DONE — verify: bash scripts/connect-kraken-mac.sh --verify-only"
