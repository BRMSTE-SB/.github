#!/usr/bin/env bash
# Download all 3 S-1 proofs to this Mac (~/Downloads/brmste-s1-proofs by default).
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/BRMSTE-SB/.github/BRMSTE-CURSORanthropic-ipo-full-sweep-6a86/scripts/download-s1-proofs-on-mac.sh | bash
# Or from a cloned repo:
#   bash scripts/download-s1-proofs-on-mac.sh
#   bash scripts/download-s1-proofs-on-mac.sh ~/Desktop/brmste-s1-proofs
set -euo pipefail

BRANCH="${BRMSTE_BRANCH:-BRMSTE-CURSORanthropic-ipo-full-sweep-6a86}"
BASE="https://raw.githubusercontent.com/BRMSTE-SB/.github/${BRANCH}"
OUT="${1:-${HOME}/Downloads/brmste-s1-proofs}"
UA="BRMSTE-SB-Mac-downloader/1.0"

mkdir -p "$OUT"
cd "$OUT"

echo "==> BRMSTE S-1 proofs → $OUT"
echo "    Branch: $BRANCH"

echo "-> Bundle tarball (all 3 proofs)"
curl -fsSL -A "$UA" -L \
  -o s-1-proofs-bundle.tar.gz \
  "${BASE}/data/proofs/s-1-proofs-bundle.tar.gz"

echo "-> Extract"
tar -xzf s-1-proofs-bundle.tar.gz

echo "-> Manifest"
curl -fsSL -A "$UA" \
  -o s-1/manifest.json \
  "${BASE}/data/proofs/s-1/manifest.json"

echo "-> Fresh issuer / SEC sources (optional refresh)"
UA_SEC="BRMSTE LTD (Companies House 15310393) contact@brmste.com"
mkdir -p s-1/anthropic s-1/openai s-1/xai-spacex-consolidated

curl -fsSL -A "$UA" \
  -o s-1/anthropic/rule-135-announcement.html \
  "https://www.anthropic.com/news/confidential-draft-s1-sec" \
  || echo "   (anthropic.com blocked — use extracted bundle)"

curl -fsSL -A "$UA" \
  -o s-1/openai/rule-135-announcement.html \
  "https://openai.com/index/openai-submits-confidential-s-1/" \
  || echo "   (openai.com blocked — use extracted bundle)"

sleep 2
curl -fsSL -A "$UA_SEC" \
  -o s-1/xai-spacex-consolidated/spacex-s1a-edgar.htm \
  "https://www.sec.gov/Archives/edgar/data/1181412/000162828026040610/spacexfwp.htm" \
  || echo "   (SEC blocked — use extracted bundle)"

echo ""
echo "DONE — S-1 proofs on this Mac:"
echo "  $OUT/s-1/"
echo "  $OUT/s-1/manifest.json"
echo ""
echo "Open in Finder:"
echo "  open \"$OUT/s-1\""
ls -lah "$OUT/s-1"/*/* 2>/dev/null | head -20 || ls -lahR "$OUT/s-1" | head -40
