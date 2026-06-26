#!/usr/bin/env bash
# Resolve Hetzner fleet SSH alias from data/hetzner/servers.json
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVERS_JSON="${BRMSTE_HETZNER_SERVERS_JSON:-$ROOT/data/hetzner/servers.json}"

hetzner_servers_json() {
  if [[ ! -f "$SERVERS_JSON" ]]; then
    echo "missing $SERVERS_JSON — sync from main: data/hetzner/servers.json" >&2
    return 1
  fi
  cat "$SERVERS_JSON"
}

hetzner_ssh_alias() {
  local id="${1:-}"
  python3 - <<'PY' "$SERVERS_JSON" "$id"
import json, sys
path, want = sys.argv[1], sys.argv[2]
data = json.load(open(path))
for s in data.get("servers", []):
    if s.get("id") == want:
        print(s.get("ssh_write") or s.get("ssh_ro") or "")
        break
PY
}

hetzner_default_cf_host() {
  # LUCIFER control plane · override with BRMSTE_HETZNER_CF_HOST
  echo "${BRMSTE_HETZNER_CF_HOST:-brmste-lucifer}"
}

hetzner_ssh_cmd() {
  local host="$1"
  shift
  local ssh_opts=(
    -o BatchMode=yes
    -o ConnectTimeout="${BRMSTE_HETZNER_SSH_TIMEOUT:-20}"
    -o StrictHostKeyChecking=accept-new
  )
  if [[ -n "${BRMSTE_HETZNER_SSH_KEY:-}" ]]; then
    ssh_opts+=(-i "$BRMSTE_HETZNER_SSH_KEY")
  fi
  ssh "${ssh_opts[@]}" "$host" "$@"
}
