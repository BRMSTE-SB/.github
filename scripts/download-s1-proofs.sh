#!/usr/bin/env bash
# Download all 3 S-1 proof bundles into data/proofs/s-1/
# Anthropic + OpenAI: Rule 135 issuer announcements (confidential S-1 not on EDGAR)
# xAI: SpaceX consolidated public S-1/A (xAI/Grok segment)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/data/proofs/s-1"
UA="BRMSTE LTD (Companies House 15310393) contact@brmste.com"

mkdir -p "$OUT/anthropic" "$OUT/openai" "$OUT/xai-spacex-consolidated"

echo "==> Downloading S-1 proofs to $OUT"

echo "-> Anthropic Rule 135"
curl -fsSL -A "$UA" -H "Accept: text/html" \
  -o "$OUT/anthropic/rule-135-announcement.html" \
  "https://www.anthropic.com/news/confidential-draft-s1-sec"

echo "-> OpenAI Rule 135 (via openai.com; may require browser if blocked)"
if ! curl -fsSL -A "$UA" -H "Accept: text/html" \
  -o "$OUT/openai/rule-135-announcement.html" \
  "https://openai.com/index/openai-submits-confidential-s-1/"; then
  echo "   curl blocked — use committed rule-135-announcement.txt in repo"
fi

echo "-> SpaceX S-1/A EDGAR (xAI consolidated)"
sleep 2
curl -fsSL -A "$UA" \
  -o "$OUT/xai-spacex-consolidated/spacex-s1a-edgar.htm" \
  "https://www.sec.gov/Archives/edgar/data/1181412/000162828026040610/spacexfwp.htm"

echo "-> SpaceX S-1/A mirror PDF"
curl -fsSL -A "$UA" -L \
  -o "$OUT/xai-spacex-consolidated/spacex-s1a-mirror.pdf" \
  "https://novawealthmanagement.com/wp-content/uploads/2026/06/SpaceX-Initial-Public-Offering-1.pdf"

echo "-> Copy BRMSTE registers"
cp "$ROOT/data/anthropic-ipo.json" "$OUT/anthropic/brmste-register.json"
cp "$ROOT/data/openai-ipo.json" "$OUT/openai/brmste-register.json"
cp "$ROOT/data/xai-ipo.json" "$OUT/xai-spacex-consolidated/brmste-register.json"

echo "-> Rebuild manifest"
python3 "$ROOT/scripts/build-s1-proof-manifest.py"

echo "S-1 proof download complete: $OUT/manifest.json"
