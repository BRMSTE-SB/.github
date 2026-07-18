#!/usr/bin/env bash
# Roll the BRMSTE stack (quantum + usdc + bitcoin-core + lnbits) out to a repo by
# writing a consumer kit that POINTS at the canonical .github manifests — no
# copied files, no duplicated secrets. Run once per target repo checkout.
#
#   TARGET_REPO=<name> TARGET_DIR=/path/to/checkout bash scripts/rollout-stack-all-repos.sh
#
# It only writes BRMSTE-STACK.md + data/brmste-stack.json into TARGET_DIR. It does
# NOT commit or push — the caller (agent/CI, per repo) reviews and commits.
# Credentials are never written; the stack reads env vars at runtime (AGENTS.md).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROLLOUT="$ROOT/data/payments/fleet-rollout.json"
TARGET_REPO="${TARGET_REPO:?set TARGET_REPO to the repo name}"
TARGET_DIR="${TARGET_DIR:?set TARGET_DIR to the repo checkout path}"

fail() { echo "ROLLOUT FAIL: $*" >&2; exit 1; }
[[ -f "$ROLLOUT" ]] || fail "missing fleet-rollout manifest: $ROLLOUT"
[[ -d "$TARGET_DIR" ]] || fail "target checkout not found: $TARGET_DIR"

# Confirm the target is a declared rollout target.
python3 - "$ROLLOUT" "$TARGET_REPO" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
repos = [t["repo"] for t in m["targets"]]
if sys.argv[2] not in repos:
    raise SystemExit(f"{sys.argv[2]} is not a declared rollout target ({', '.join(repos)})")
PY

mkdir -p "$TARGET_DIR/data"

cat > "$TARGET_DIR/data/brmste-stack.json" <<JSON
{
  "schema": "brmste-stack-consumer/v1",
  "repo": "$TARGET_REPO",
  "installs": ["quantum", "usdc", "bitcoin-core", "lnbits"],
  "canonical": "https://github.com/BRMSTE-SB/.github/blob/main/data/payments/fleet-rollout.json",
  "manifests": {
    "quantum": "https://github.com/BRMSTE-SB/.github/blob/main/data/quantum/kits.json",
    "usdc": "https://github.com/BRMSTE-SB/.github/blob/main/data/payments/coinbase-usdc.json",
    "bitcoin_core": "https://github.com/BRMSTE-SB/.github/blob/main/data/payments/bitcoin-core.json",
    "lnbits": "https://github.com/BRMSTE-SB/.github/blob/main/data/payments/lnbits.json"
  },
  "credentials": "env-only · never committed · see .github/AGENTS.md",
  "status": "installed",
  "updated_at": "2026-07-18"
}
JSON

cat > "$TARGET_DIR/BRMSTE-STACK.md" <<MD
# BRMSTE stack · $TARGET_REPO

**BRMSTE LTD · Companies House 15310393 · GB2607860**

This repo installs the BRMSTE compute + settlement stack as a **consumer** —
canonical manifests and scripts live in
[BRMSTE-SB/.github](https://github.com/BRMSTE-SB/.github).

| Component | Canonical manifest |
|-----------|--------------------|
| Quantum (cuQuantum + Qiskit) | \`.github/data/quantum/kits.json\` |
| openUSD / Coinbase | \`.github/data/payments/coinbase-usdc.json\` |
| Bitcoin Core (full-node RPC) | \`.github/data/payments/bitcoin-core.json\` |
| LNbits (Lightning invoices) | \`.github/data/payments/lnbits.json\` |

Install: \`bash .github/scripts/install-payments-rails.sh\` +
\`bash .github/scripts/install-quantum-kits.sh\`.

Credentials are **env-only** — never committed, never asked in chat (see
[.github/AGENTS.md](https://github.com/BRMSTE-SB/.github/blob/main/AGENTS.md)).

Machine manifest: \`data/brmste-stack.json\`.
MD

echo "ROLLOUT OK: wrote consumer kit to $TARGET_DIR (BRMSTE-STACK.md + data/brmste-stack.json) — review and commit in $TARGET_REPO"
