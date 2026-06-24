#!/usr/bin/env bash
# Verify BRMSTE-SB FULL OPEN TUNE manifest and underlying open checks.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/data/brmste-github-full-tune.json"
OPEN_ALL="$ROOT/data/open-all.json"

fail() { echo "FULL-OPEN-TUNE FAIL: $*" >&2; exit 1; }
ok() { echo "FULL-OPEN-TUNE OK: $*"; }

[[ -f "$MANIFEST" ]] || fail "missing manifest: $MANIFEST"
[[ -f "$OPEN_ALL" ]] || fail "missing open-all manifest: $OPEN_ALL"

bash "$ROOT/scripts/verify-global-open.sh"
bash "$ROOT/scripts/verify-open-all.sh"

python3 - <<'PY' "$MANIFEST" "$OPEN_ALL"
import json, sys, pathlib

manifest_path = pathlib.Path(sys.argv[1])
open_all_path = pathlib.Path(sys.argv[2])

manifest = json.loads(manifest_path.read_text())
open_all = json.loads(open_all_path.read_text())

required = [
    ("status", "full_open_tune"),
    ("org", "BRMSTE-SB"),
]
for key, expected in required:
    actual = manifest.get(key)
    if actual != expected:
        raise SystemExit(f"manifest {key}={actual!r} expected {expected!r}")

entity = manifest.get("entity", {})
for field in ("name", "companies_house", "patent", "pct"):
    if not entity.get(field):
        raise SystemExit(f"manifest entity missing {field}")

open_lane = manifest.get("open_lane", {})
if open_lane.get("humans") != "free":
    raise SystemExit("open_lane.humans must be free")

ai_names = {item["name"] for item in open_lane.get("ai", []) if isinstance(item, dict)}
for provider in ("Cursor", "Claude", "OpenAI", "Grok"):
    if provider not in ai_names:
        raise SystemExit(f"open_lane.ai missing {provider}")

claude = next(item for item in open_lane["ai"] if item["name"] == "Claude")
if claude.get("credentials", {}).get("never_commit") is not True:
    raise SystemExit("Claude credentials must set never_commit: true")

if manifest.get("security", {}).get("no_secrets_in_git") is not True:
    raise SystemExit("security.no_secrets_in_git must be true")

ownership = manifest.get("ownership", {})
if ownership.get("declaration") != "full_declare":
    raise SystemExit("ownership.declaration must be full_declare")
owner = ownership.get("owner", {})
if owner.get("name") != "Shravan Bansal":
    raise SystemExit("ownership.owner.name must be Shravan Bansal")
if owner.get("equity_percent") != 53:
    raise SystemExit("ownership.owner.equity_percent must be 53")

declare_path = manifest_path.parent / "owner-equity-declaration.json"
if not declare_path.is_file():
    raise SystemExit("missing owner-equity-declaration.json")
declare = json.loads(declare_path.read_text())
if declare.get("owner", {}).get("equity_percent") != 53:
    raise SystemExit("owner-equity-declaration.json equity must be 53")

if open_all.get("status") != "open_all":
    raise SystemExit("open-all.json status must be open_all")

repo_count = len(open_all.get("repositories", []))
if manifest.get("repositories", {}).get("count") != repo_count:
    raise SystemExit(
        f"repositories.count={manifest.get('repositories', {}).get('count')} "
        f"!= open-all count {repo_count}"
    )

print(f"manifest={manifest_path.name} ai_providers={len(ai_names)} repos={repo_count}")
PY

ok "full open tune manifest aligned with OPEN ALL · carbon justice · brand gate"
