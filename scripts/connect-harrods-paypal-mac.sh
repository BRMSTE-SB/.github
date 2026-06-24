#!/usr/bin/env bash
# Connect Harrods revenue rail → BRMSTE PayPal · Fort Knox credentials only — NEVER commit.
#
# Default PayPal key folder (Mac):
#   /Users/sachindabas/Desktop/API keys - Copy/PayPal
#
# Usage on Mac:
#   bash scripts/connect-harrods-paypal-mac.sh
#   BRMSTE_PAYPAL_DIR="/path/to/PayPal" bash scripts/connect-harrods-paypal-mac.sh
#   bash scripts/connect-harrods-paypal-mac.sh --verify-only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RAILS="$ROOT/data/brmste-paypal-rails.json"
REVENUE="$ROOT/data/harrods-revenue-rail.json"
OUT="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"

PAYPAL_DIR="${1:-${BRMSTE_PAYPAL_DIR:-/Users/sachindabas/Desktop/API keys - Copy/PayPal}}"
VERIFY_ONLY=false
if [[ "${1:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
  PAYPAL_DIR="${BRMSTE_PAYPAL_DIR:-/Users/sachindabas/Desktop/API keys - Copy/PayPal}"
elif [[ "${2:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
fi

if [[ ! -f "$RAILS" || ! -f "$REVENUE" ]]; then
  echo "ERROR: missing PayPal rail registers — clone BRMSTE-SB/.github first." >&2
  exit 1
fi

echo "==> BRMSTE Harrods → PayPal banking rail connect"
echo "    PayPal keys: $PAYPAL_DIR"
echo "    Fort Knox:   $OUT (never committed)"

python3 - <<'PY' "$RAILS" "$REVENUE" "$PAYPAL_DIR" "$OUT" "$VERIFY_ONLY"
import json, pathlib, re, sys, urllib.request, base64

rails_path, revenue_path, paypal_dir, out_path, verify_only = (
    pathlib.Path(sys.argv[1]),
    pathlib.Path(sys.argv[2]),
    pathlib.Path(sys.argv[3]),
    pathlib.Path(sys.argv[4]),
    sys.argv[5].lower() == "true",
)

rails = json.loads(rails_path.read_text())
revenue = json.loads(revenue_path.read_text())
env_map = rails["credentials_policy"]["env_vars"]

# Expected Mac key files (operator can create these)
file_map = {
    "BRMSTE_PAYPAL_MERCHANT_EMAIL": "BRMSTE-PAYPAL-EMAIL.txt",
    "PAYPAL_CLIENT_ID": "PAYPAL-CLIENT-ID.txt",
    "PAYPAL_CLIENT_SECRET": "PAYPAL-CLIENT-SECRET.txt",
    "PAYPAL_WEBHOOK_ID": "PAYPAL-WEBHOOK-ID.txt",
    "COMPANIES_HOUSE_AUTH_CODE": "COMPANIES-HOUSE-AUTH-CODE.txt",
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
missing = []
for env_var, fname in file_map.items():
    val = read_key(paypal_dir / fname)
    if val:
        new_vars[env_var] = val
    elif env_var in ("PAYPAL_WEBHOOK_ID", "COMPANIES_HOUSE_AUTH_CODE"):
        continue  # optional
    elif env_var not in existing:
        missing.append(fname)

merged = {**existing, **new_vars}

if verify_only:
    required = ["BRMSTE_PAYPAL_MERCHANT_EMAIL", "PAYPAL_CLIENT_ID", "PAYPAL_CLIENT_SECRET"]
    for r in required:
        if r not in merged or not merged[r]:
            raise SystemExit(f"verify fail: missing {r} in Fort Knox")
    print(f"verify_ok merchant={merged['BRMSTE_PAYPAL_MERCHANT_EMAIL'][:3]}***")
    print(f"revenue_rail={revenue['routing']['flow']}")
    sys.exit(0)

if missing and not new_vars:
    print(f"WARN: PayPal folder not found or empty: {paypal_dir}")
    print("Create folder with files:")
    for f in file_map.values():
        print(f"  - {f}")
    print("")
    print("Or set vars manually in .env.fort-knox:")
    for env_var in file_map:
        if env_var not in ("PAYPAL_WEBHOOK_ID", "COMPANIES_HOUSE_AUTH_CODE"):
            print(f"  {env_var}=...")
    if missing:
        print(f"missing={', '.join(missing)}")

# Merge write — preserve AI keys already in .env.fort-knox
header = [
    "# BRMSTE Fort Knox — DO NOT COMMIT",
    "# Harrods → PayPal rail + Companies House auth",
    f"# paypal_dir={paypal_dir}",
    "",
]
lines = header[:]
for k in sorted(set(list(merged.keys()) + list(new_vars.keys()))):
    if k in merged and merged[k]:
        lines.append(f"{k}={merged[k]}")

if not out_path.is_file() or new_vars:
    out_path.write_text("\n".join(lines) + "\n")
    print(f"fort_knox_updated vars={len(new_vars)} merged={len(merged)}")
else:
    print("fort_knox_unchanged (no new PayPal keys found)")

# Optional live token check
cid = merged.get("PAYPAL_CLIENT_ID", "")
secret = merged.get("PAYPAL_CLIENT_SECRET", "")
if cid and secret:
    try:
        auth = base64.b64encode(f"{cid}:{secret}".encode()).decode()
        req = urllib.request.Request(
            "https://api-m.paypal.com/v1/oauth2/token",
            data=b"grant_type=client_credentials",
            headers={
                "Authorization": f"Basic {auth}",
                "Content-Type": "application/x-www-form-urlencoded",
            },
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            tok = json.loads(resp.read().decode())
        if tok.get("access_token"):
            print("paypal_oauth=ok live_api_reachable")
    except Exception as e:
        print(f"paypal_oauth=skip ({type(e).__name__}) — check credentials in Fort Knox")

print(f"rail={rails['merchant']['label']} status={rails['status']}")
print(f"harrods_revenue_pct={revenue['routing']['harrods_revenue_pct_to_paypal']}%")
PY

chmod 600 "$OUT" 2>/dev/null || true

echo ""
echo "DONE — load on Mac:"
echo "  set -a && source .env.fort-knox && set +a"
echo "  bash scripts/connect-harrods-paypal-mac.sh --verify-only"
echo ""
echo "Never commit .env.fort-knox or paste PayPal secrets into OPEN ALL repos."
