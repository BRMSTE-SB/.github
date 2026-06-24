#!/usr/bin/env bash
# Org admin: align GitHub repo description, homepage, and topics for Full Global branding.
set -euo pipefail

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "Set GH_TOKEN to an org-admin PAT with repo scope." >&2
  exit 1
fi

curl -fsSL -X PATCH \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/BRMSTE-SB/.github \
  -d '{
    "description": "BRMSTE-SB Full Global governance — public org profile, brand gate, GB2607860. Made in Global Blocks.",
    "homepage": "https://brmste.com",
    "has_issues": true,
    "has_discussions": false
  }' | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("html_url"), d.get("visibility"), d.get("description"))'

# Topics require separate endpoint
curl -fsSL -X PUT \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/BRMSTE-SB/.github/topics \
  -d '{"names":["brmste","global-blocks","governance","open-source","patent-notice"]}'

echo "GLOBAL-METADATA OK"
