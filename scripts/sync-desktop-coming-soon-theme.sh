#!/usr/bin/env bash
# Sync local Desktop brmste-coming-soon theme into repo coming-soon/site/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="${BRMSTE_DESKTOP_THEME:-/Users/sachindabas/Desktop/brmste-coming-soon}"
TARGET="${BRMSTE_SITE_DIR:-$ROOT/coming-soon/site}"
DRY_RUN=false

usage() {
  cat <<EOF
Usage: sync-desktop-coming-soon-theme.sh [--dry-run]

  SOURCE: $SOURCE
  TARGET: $TARGET

  Override paths:
    BRMSTE_DESKTOP_THEME=/path/to/brmste-coming-soon
    BRMSTE_SITE_DIR=/path/to/coming-soon/site
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

[[ -d "$SOURCE" ]] || {
  echo "SOURCE missing: $SOURCE" >&2
  echo "Set BRMSTE_DESKTOP_THEME or copy Desktop folder into workspace." >&2
  exit 1
}

mkdir -p "$TARGET"

RSYNC=(rsync -av --delete)
[[ "$DRY_RUN" == true ]] && RSYNC+=(--dry-run)

"${RSYNC[@]}" \
  --exclude ".DS_Store" \
  --exclude "node_modules" \
  "$SOURCE/" "$TARGET/"

echo "THEME SYNC OK: $SOURCE -> $TARGET"
