#!/usr/bin/env bash
# Verify BRMSTE-SB/.github is public and globally reachable.
set -euo pipefail

REPO_API="https://api.github.com/repos/BRMSTE-SB/.github"
HTML_URL="https://github.com/BRMSTE-SB/.github"

fail() { echo "GLOBAL-VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "GLOBAL-VERIFY OK: $*"; }

body="$(curl -fsSL "$REPO_API")"
private="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["private"])' <<<"$body")"
visibility="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["visibility"])' <<<"$body")"
name="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["name"])' <<<"$body")"
description="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("description") or "")' <<<"$body")"

[[ "$private" == "False" || "$private" == "false" ]] || fail "repo is still private"
[[ "$visibility" == "public" ]] || fail "visibility=$visibility (expected public)"
[[ "$name" == ".github" ]] || fail "name=$name (org profile repo must stay .github)"

status="$(curl -s -o /dev/null -w '%{http_code}' "$HTML_URL")"
[[ "$status" == "200" ]] || fail "HTML page returned HTTP $status"

ok "public visibility=$visibility name=$name url=$HTML_URL"
if [[ -n "$description" ]]; then
  echo "  description: $description"
fi
