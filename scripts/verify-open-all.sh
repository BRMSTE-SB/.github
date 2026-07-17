#!/usr/bin/env bash
# Verify every BRMSTE-SB org repository is public (OPEN ALL).
set -euo pipefail

ORG="BRMSTE-SB"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/data/open-all.json"

fail() { echo "OPEN-ALL FAIL: $*" >&2; exit 1; }
ok() { echo "OPEN-ALL OK: $*"; }

body="$(curl -fsSL "https://api.github.com/orgs/${ORG}/repos?per_page=100&type=all")"

count="$(python3 - <<'PY' "$body" "$MANIFEST"
import json, sys, pathlib

api_repos = json.loads(sys.argv[1])
manifest_path = pathlib.Path(sys.argv[2])

if isinstance(api_repos, dict) and "message" in api_repos:
    raise SystemExit(f"API error: {api_repos['message']}")

private = [r["name"] for r in api_repos if r.get("private")]
if private:
    raise SystemExit(f"private repos remain: {', '.join(sorted(private))}")

api_names = sorted(r["name"] for r in api_repos)
manifest = json.loads(manifest_path.read_text())
listed = sorted(r["name"] for r in manifest.get("repositories", []))

missing = sorted(set(api_names) - set(listed))
extra = sorted(set(listed) - set(api_names))
if missing or extra:
    raise SystemExit(f"manifest drift: missing={missing} extra={extra}")

for name in api_names:
    print(name)

print(len(api_names))
PY
)"

repo_lines="$(echo "$count" | sed '$d')"
total="$(echo "$count" | tail -n 1)"

echo "$repo_lines" | while read -r name; do
  [[ -n "$name" ]] && echo "  · $name"
done

ok "org=${ORG} — ${total} repositories public, 0 private, manifest aligned"
