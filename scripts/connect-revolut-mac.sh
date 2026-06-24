#!/usr/bin/env bash
# Connect BRMSTE Revolut banking rail · @shravanbansal full corpus · Fort Knox only — NEVER commit.
#
# Default Revolut key folder (Mac):
#   /Users/sachindabas/Desktop/API keys - Copy/Revolut
#
# Usage on Mac:
#   bash scripts/connect-revolut-mac.sh
#   BRMSTE_REVOLUT_DIR="/path/to/Revolut" bash scripts/connect-revolut-mac.sh
#   bash scripts/connect-revolut-mac.sh --verify-only
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RAILS="$ROOT/data/brmste-revolut-rails.json"
CORPUS="$ROOT/data/revolut-hydration-corpus.json"
OUT="${BRMSTE_FORT_KNOX_ENV:-$ROOT/.env.fort-knox}"

REVOLUT_DIR="${1:-${BRMSTE_REVOLUT_DIR:-/Users/sachindabas/Desktop/API keys - Copy/Revolut}}"
VERIFY_ONLY=false
if [[ "${1:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
  REVOLUT_DIR="${BRMSTE_REVOLUT_DIR:-/Users/sachindabas/Desktop/API keys - Copy/Revolut}"
elif [[ "${2:-}" == "--verify-only" ]]; then
  VERIFY_ONLY=true
fi

if [[ ! -f "$RAILS" || ! -f "$CORPUS" ]]; then
  echo "ERROR: missing Revolut rail registers — clone BRMSTE-SB/.github first." >&2
  exit 1
fi

echo "==> BRMSTE Revolut banking rail connect · @shravanbansal full corpus"
echo "    Revolut keys: $REVOLUT_DIR"
echo "    Fort Knox:    $OUT (never committed)"

python3 - <<'PY' "$RAILS" "$CORPUS" "$REVOLUT_DIR" "$OUT" "$VERIFY_ONLY"
import json, pathlib, re, sys, urllib.request

rails_path, corpus_path, revolut_dir, out_path, verify_only = (
    pathlib.Path(sys.argv[1]),
    pathlib.Path(sys.argv[2]),
    pathlib.Path(sys.argv[3]),
    pathlib.Path(sys.argv[4]),
    sys.argv[5].lower() == "true",
)

rails = json.loads(rails_path.read_text())
corpus = json.loads(corpus_path.read_text())

file_map = {
    "REVOLUT_API_KEY": "REVOLUT-API-KEY.txt",
    "REVOLUT_MERCHANT_ID": "REVOLUT-MERCHANT-ID.txt",
    "REVOLUT_WEBHOOK_SECRET": "REVOLUT-WEBHOOK-SECRET.txt",
    "BRMSTE_REVOLUT_MERCHANT_EMAIL": "BRMSTE-REVOLUT-EMAIL.txt",
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
    val = read_key(revolut_dir / fname)
    if val:
        new_vars[env_var] = val
    elif env_var == "REVOLUT_WEBHOOK_SECRET":
        continue
    elif env_var not in existing:
        missing.append(fname)

merged = {**existing, **new_vars}
merged["BRMSTE_REVOLUT_OPERATOR_HANDLE"] = corpus["operator"]["handle"]
merged["BRMSTE_REVOLUT_CORPUS_STATUS"] = "hydrated"

if verify_only:
    required = ["REVOLUT_API_KEY", "REVOLUT_MERCHANT_ID"]
    for r in required:
        if r not in merged or not merged[r]:
            raise SystemExit(f"verify fail: missing {r} in Fort Knox")
    if merged.get("BRMSTE_REVOLUT_HYDRATED") != "true":
        raise SystemExit("verify fail: run hydrate-utxo-rails-mac.sh first (BRMSTE_REVOLUT_HYDRATED)")
    print(f"verify_ok operator={corpus['operator']['handle']} merchant_id={merged['REVOLUT_MERCHANT_ID'][:4]}***")
    print(f"corpus={corpus['headline']}")
    sys.exit(0)

if missing and not new_vars:
    print(f"WARN: Revolut folder not found or empty: {revolut_dir}")
    print("Create folder with files:")
    for f in file_map.values():
        print(f"  - {f}")
    print("")
    print("Or set vars manually in .env.fort-knox:")
    for env_var in file_map:
        if env_var != "REVOLUT_WEBHOOK_SECRET":
            print(f"  {env_var}=...")
    if missing:
        print(f"missing={', '.join(missing)}")

keep = []
skip_prefixes = (
    "REVOLUT_API_KEY=",
    "REVOLUT_MERCHANT_ID=",
    "REVOLUT_WEBHOOK_SECRET=",
    "BRMSTE_REVOLUT_MERCHANT_EMAIL=",
    "BRMSTE_REVOLUT_OPERATOR_HANDLE=",
    "BRMSTE_REVOLUT_CORPUS_STATUS=",
    "BRMSTE_REVOLUT_CONNECTED=",
    "BRMSTE_REVOLUT_CONNECTED_AT=",
)
if out_path.is_file():
    for line in out_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if any(line.startswith(p) for p in skip_prefixes):
            continue
        keep.append(line)

from datetime import datetime, timezone
ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
revolut_lines = [
    "",
    f"# Revolut connect · @shravanbansal full corpus · {ts}",
    f"# revolut_dir={revolut_dir}",
]
for k in sorted(set(list(merged.keys()) + list(new_vars.keys()))):
    if k in merged and merged[k] and k not in (
        "BRMSTE_REVOLUT_CONNECTED",
        "BRMSTE_REVOLUT_CONNECTED_AT",
    ):
        revolut_lines.append(f"{k}={merged[k]}")
revolut_lines.append("BRMSTE_REVOLUT_CONNECTED=true")
revolut_lines.append(f"BRMSTE_REVOLUT_CONNECTED_AT={ts}")

out_path.write_text("\n".join(keep + revolut_lines).strip() + "\n", encoding="utf-8")
print(f"fort_knox_updated vars={len(new_vars)} merged={len(merged)}")

api_key = merged.get("REVOLUT_API_KEY", "")
if api_key:
    for base in ("https://b2b.revolut.com/api/1.0", "https://sandbox-b2b.revolut.com/api/1.0"):
        try:
            req = urllib.request.Request(
                f"{base}/accounts",
                headers={"Authorization": f"Bearer {api_key}"},
                method="GET",
            )
            with urllib.request.urlopen(req, timeout=15) as resp:
                body = json.loads(resp.read().decode())
            if isinstance(body, list) and len(body) >= 0:
                env_label = "live" if "sandbox" not in base else "sandbox"
                print(f"revolut_api=ok {env_label}_api_reachable accounts={len(body)}")
                break
        except Exception as e:
            if "sandbox" in base:
                print(f"revolut_api=skip ({type(e).__name__}) — check credentials in Fort Knox")

print(f"rail={rails['merchant']['label']} status={rails['status']}")
print(f"operator={corpus['operator']['handle']} corpus=full")
PY

chmod 600 "$OUT" 2>/dev/null || true

echo ""
echo "DONE — load on Mac:"
echo "  bash scripts/hydrate-utxo-rails-mac.sh"
echo "  bash scripts/connect-revolut-mac.sh"
echo "  bash scripts/connect-revolut-mac.sh --verify-only"
echo ""
echo "Never commit .env.fort-knox or paste Revolut secrets into OPEN ALL repos."
