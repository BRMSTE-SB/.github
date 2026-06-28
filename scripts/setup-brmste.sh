#!/usr/bin/env bash
# Setup BRMSTE — verify all banking, HSBC, and portfolio manifests locally.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

info() { echo "BRMSTE SETUP: $*"; }

info "verify master setup manifest"
bash "$ROOT/scripts/verify-brmste-setup.sh"

info "verify banking net worth + HSBC rails"
bash "$ROOT/scripts/verify-banking-manifest.sh"

info "verify HSBC API catalog (152 APIs)"
bash "$ROOT/scripts/verify-hsbc-api-catalog.sh"

info "verify portfolio asset classes (7 classes)"
bash "$ROOT/scripts/verify-portfolio-asset-classes.sh"

info "verify eToro portfolio manifests"
bash "$ROOT/scripts/verify-portfolio-manifest.sh"

info "plan eToro portfolio build (no credentials)"
bash "$ROOT/scripts/etoro-build-portfolio-100.sh" --plan

echo "BRMSTE SETUP OK: all manifests verified · ready for worker deploy"
