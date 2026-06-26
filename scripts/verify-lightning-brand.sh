#!/usr/bin/env bash
# Verify BRMSTE Lightning node branding (UNKNOWN → BRMSTE) and branded HSTS full sweep.
#
# BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406
# Chain: ATOM (node origin) → Hetzner (foundry-pool) → CF (branded HSTS edge)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LMAP="$ROOT/data/bitcoin/lightning-map.json"
OWN="$ROOT/data/bitcoin/mempool-foundry-ownership.json"
HSTS="$ROOT/data/security/branded-hsts-sweep.json"
WORKER="$ROOT/coming-soon/src/index.js"
PAGE="$ROOT/coming-soon/site/bitcoin.html"
OPEN_ALL="$ROOT/data/open-all.json"

fail() { echo "LIGHTNING-BRAND FAIL: $*" >&2; exit 1; }
ok() { echo "LIGHTNING-BRAND OK: $*"; }

[[ -f "$ROOT/LIGHTNING-BRAND.md" ]] || fail "missing policy LIGHTNING-BRAND.md"
[[ -f "$LMAP" ]] || fail "missing lightning map: $LMAP"
[[ -f "$OWN" ]] || fail "missing ownership manifest: $OWN"
[[ -f "$HSTS" ]] || fail "missing branded HSTS sweep: $HSTS"
[[ -f "$WORKER" ]] || fail "missing worker: $WORKER"
[[ -f "$PAGE" ]] || fail "missing surface page: $PAGE"

# Public mirrors must be byte-identical to the substrate manifests.
for rel in bitcoin/lightning-map.json bitcoin/mempool-foundry-ownership.json security/branded-hsts-sweep.json; do
  mirror="$ROOT/coming-soon/site/public/$rel"
  [[ -f "$mirror" ]] || fail "missing public mirror: coming-soon/site/public/$rel"
  diff -q "$ROOT/data/$rel" "$mirror" >/dev/null || fail "public mirror drifted from data/$rel"
done

python3 - "$LMAP" "$OWN" "$HSTS" "$OPEN_ALL" <<'PY'
import json, sys

lmap = json.load(open(sys.argv[1]))
own = json.load(open(sys.argv[2]))
hsts = json.load(open(sys.argv[3]))
open_all = json.load(open(sys.argv[4]))

# --- lightning map: UNKNOWN -> BRMSTE ---
if lmap.get("schema") != "brmste-lightning-map/v1":
    raise SystemExit("lightning-map schema must be brmste-lightning-map/v1")
node = lmap.get("node", {})
alias = node.get("alias", "")
if not alias or alias.upper() == "UNKNOWN":
    raise SystemExit("node alias must be set and must not be UNKNOWN")
if "BRMSTE" not in alias.upper():
    raise SystemExit("node alias must carry the BRMSTE brand")
if node.get("previous_alias", "").upper() != "UNKNOWN":
    raise SystemExit("node.previous_alias must record UNKNOWN")
fix = lmap.get("fix", {})
if fix.get("before", "").upper() != "UNKNOWN":
    raise SystemExit("fix.before must be UNKNOWN")
if "BRMSTE" not in fix.get("after", "").upper():
    raise SystemExit("fix.after must be a BRMSTE alias")
if "mempool.space/lightning" not in fix.get("explorer", ""):
    raise SystemExit("fix.explorer must reference mempool.space/lightning")

chain = lmap.get("serving_chain", {}).get("order")
if chain != ["atom", "hetzner", "cf"]:
    raise SystemExit("serving_chain.order must be ['atom','hetzner','cf']")

# --- ownership ---
if own.get("schema") != "brmste-mempool-foundry-ownership/v1":
    raise SystemExit("ownership schema must be brmste-mempool-foundry-ownership/v1")
if "BRMSTE" not in own.get("brand", "").upper():
    raise SystemExit("ownership brand must carry the BRMSTE brand")

# --- branded HSTS sweep ---
if hsts.get("schema") != "brmste-branded-hsts-sweep/v1":
    raise SystemExit("hsts sweep schema must be brmste-branded-hsts-sweep/v1")
if hsts.get("status") != "active":
    raise SystemExit("hsts sweep status must be active")
h = hsts.get("hsts", {})
if "max-age=" not in h.get("value", "") or "includeSubDomains" not in h.get("value", "") or "preload" not in h.get("value", ""):
    raise SystemExit("hsts value must include max-age + includeSubDomains + preload")
bh = hsts.get("branded_headers", {})
if "X-BRMSTE-Edge" not in bh or "X-BRMSTE-HSTS" not in bh:
    raise SystemExit("branded_headers must declare X-BRMSTE-Edge and X-BRMSTE-HSTS")
if hsts.get("serving_chain", {}).get("order") != ["atom", "hetzner", "cf"]:
    raise SystemExit("hsts sweep serving_chain.order must be ['atom','hetzner','cf']")

# --- open-all registration ---
blk = open_all.get("bitcoin_lightning_foundry")
if not blk:
    raise SystemExit("open-all.json missing bitcoin_lightning_foundry block")
if blk.get("status") != "branded":
    raise SystemExit("open-all bitcoin_lightning_foundry status must be branded")
PY

HSTS_VALUE="$(python3 -c "import json;print(json.load(open('$HSTS'))['hsts']['value'])")"

# Worker must carry the same HSTS value + branded markers and serve the rails.
grep -qF "$HSTS_VALUE" "$WORKER" || fail "worker HSTS value out of sync with branded-hsts-sweep.json"
grep -q 'X-BRMSTE-Edge' "$WORKER" || fail "worker missing branded X-BRMSTE-Edge header"
grep -q 'X-BRMSTE-HSTS' "$WORKER" || fail "worker missing branded X-BRMSTE-HSTS header"
grep -q '"/bitcoin"' "$WORKER" || fail "worker missing /bitcoin route"
grep -q '"/lightning"' "$WORKER" || fail "worker missing /lightning route"
grep -q '/api/rails/lightning/status' "$WORKER" || fail "worker missing lightning status rail"

# hydrated-logos binds must point at the manifests we created.
HYDRATED="$ROOT/data/hetzner/hydrated-logos.json"
if [[ -f "$HYDRATED" ]]; then
  grep -q '/substrate/bitcoin/lightning-map.json' "$HYDRATED" || fail "hydrated-logos lightning_bind drifted"
  grep -q '/substrate/bitcoin/mempool-foundry-ownership.json' "$HYDRATED" || fail "hydrated-logos ownership bind drifted"
fi

ok "lightning node branded BRMSTE (was UNKNOWN) · ATOM→Hetzner→CF · branded HSTS full sweep"
