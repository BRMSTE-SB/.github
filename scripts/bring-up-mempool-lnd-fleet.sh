#!/usr/bin/env bash
# Bring up mempool.space + LND on every BRMSTE Hetzner node.
# BRMSTE LTD · Companies House 15310393 · GB2607860
#
# RUN FROM THE KOHINOOR MAC ONLY — uses the read-only-provisioned SSH aliases.
# Operator connects; agents/CI run scripts (OPERATOR DOESNT BASH doctrine — this
# is an agent/Mac lane script, never pasted secrets).
#
# Prereqs on each node: Docker + Docker Compose plugin, and a node.env placed at
#   /opt/brmste/mempool-lnd/node.env  (from node.env.example, secrets set locally).
#
# Usage:
#   bash scripts/bring-up-mempool-lnd-fleet.sh            # deploy to all nodes
#   bash scripts/bring-up-mempool-lnd-fleet.sh lucifer    # single node
#   HEALTH_ONLY=1 bash scripts/bring-up-mempool-lnd-fleet.sh   # just probe health
set -euo pipefail

REMOTE_DIR=/opt/brmste/mempool-lnd
COMPOSE_SRC="$(cd "$(dirname "$0")/.." && pwd)/deploy/mempool-lnd/docker-compose.yml"

# node-id : ssh-alias  (aliases from docs/HETZNER-MAC-COLLECT.md)
FLEET=(
  "lucifer:brmste-lucifer-ro"
  "brmste-db:brmste-db-ro"
  "sdbm-os:brmste-commercial-ai-ro"
  "commercial-com:brmste-commercial-com-ro"
  "commercial-ai-sb:brmste-commercial-ai-sb-ro"
  "patent-box:brmste-patent-box-ro"
  "patent-carbon:brmste-patent-carbon-ro"
  "carbon-usa:brmste-carbon-usa-ro"
  "carbon-usa2:brmste-carbon-usa2-ro"
  "retyre:brmste-retyre-ro"
  "foundry-pool:brmste-foundry-pool-ro"
  "siemens:brmste-siemens-ro"
  "bizstrat:brmste-bizstrat-ro"
  "leading:brmste-leading-ro"
  "shravan-hetzner:brmste-shravan-hetzner-ro"
)

ONLY="${1:-}"

health() {
  local id="$1" alias="$2"
  local h
  h=$(ssh -o ConnectTimeout=8 "$alias" \
      "curl -s --max-time 8 localhost:8999/api/v1/blocks/tip/height 2>/dev/null || echo NA")
  echo "  $id: mempool tip=$h"
}

deploy() {
  local id="$1" alias="$2"
  echo "== $id ($alias) =="
  ssh -o ConnectTimeout=10 "$alias" "mkdir -p $REMOTE_DIR"
  scp -q "$COMPOSE_SRC" "$alias:$REMOTE_DIR/docker-compose.yml"
  ssh "$alias" bash -s <<EOF
set -e
cd $REMOTE_DIR
[ -f node.env ] || { echo "  MISSING node.env on $id — skipping (set secrets on node first)"; exit 3; }
docker compose --env-file node.env pull
docker compose --env-file node.env up -d
EOF
  health "$id" "$alias"
}

for entry in "${FLEET[@]}"; do
  id="${entry%%:*}"; alias="${entry##*:}"
  [ -n "$ONLY" ] && [ "$ONLY" != "$id" ] && continue
  if [ "${HEALTH_ONLY:-0}" = "1" ]; then
    health "$id" "$alias"
  else
    deploy "$id" "$alias" || echo "  !! $id failed (exit $?) — continuing"
  fi
done

echo "Done. bitcoind IBD takes hours per node; mempool populates as blocks sync."
