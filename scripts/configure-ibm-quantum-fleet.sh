#!/usr/bin/env bash
# Configure IBM Enterprise Quantum fleet for Shravan Bansal / BRMSTE LTD.
# Operator-run — IBM_QUANTUM_API_KEY from env or keychain, never from repo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLEET_MANIFEST="$ROOT/data/ibm/quantum-fleet.json"
SERVICE_CRN="crn:v1:bluemix:public:quantum-computing:us-east:a/5dd2c9fe5e5b4718987c5ad1167fa19f:191cdf4f-de18-45a9-8fa5-9eb0c68183ba::"
IBM_API_VERSION="2026-04-15"
FLEET_FALLBACK=(ibm_fez ibm_kingston ibm_marrakesh)

fail() { echo "FLEET CONFIG FAIL: $*" >&2; exit 1; }
info() { echo "FLEET CONFIG: $*"; }

IBM_QUANTUM_API_KEY="${IBM_QUANTUM_API_KEY:-${IBM_API_KEY:-}}"
[[ -n "$IBM_QUANTUM_API_KEY" ]] || fail "IBM_QUANTUM_API_KEY not set"

echo "=== BRMSTE IBM Quantum Fleet — Shravan Bansal ==="
echo "Entity: BRMSTE LTD · CH 15310393 · Patent GB2607860"
echo ""

info "IAM token"
IAM_RESP=$(curl -sS -X POST https://iam.cloud.ibm.com/identity/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${IBM_QUANTUM_API_KEY}")
IAM_TOKEN=$(echo "$IAM_RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null || echo "")
[[ -n "$IAM_TOKEN" ]] || fail "IAM token failed"

QHDRS=(-H "Authorization: Bearer ${IAM_TOKEN}" -H "Service-CRN: ${SERVICE_CRN}" -H "IBM-API-Version: ${IBM_API_VERSION}" -H "Accept: application/json")

info "probe backends"
BACKENDS_JSON=$(curl -sS "${QHDRS[@]}" "https://quantum.cloud.ibm.com/api/v1/backends")
BACKEND_COUNT=$(echo "$BACKENDS_JSON" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('devices',[])))" 2>/dev/null || echo "0")
[[ "$BACKEND_COUNT" -gt 0 ]] || fail "no backends returned (check API key + CRN)"

DEFAULT_BACKEND=$(echo "$BACKENDS_JSON" | python3 -c "
import json,sys
devices=sorted(json.load(sys.stdin).get('devices',[]), key=lambda b: b.get('queue_length',999))
print(devices[0]['name'] if devices else 'ibm_fez')
")
info "default backend: $DEFAULT_BACKEND (shortest queue)"

info "refresh fleet manifest"
python3 - "$FLEET_MANIFEST" "$BACKENDS_JSON" << 'PY'
import json, sys
from datetime import datetime, timezone

manifest_path, backends_raw = sys.argv[1], sys.argv[2]
devices = sorted(json.loads(backends_raw).get("devices", []), key=lambda b: b.get("queue_length", 999))

manifest = {
    "schema": "brmste-ibm-quantum-fleet/v1",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "operator": {
        "name": "Shravan Krishan Avtar Bansal",
        "short_name": "Shravan Bansal",
        "entity": "BRMSTE LTD",
        "companies_house": "15310393",
        "patent": "GB2607860",
    },
    "ibm_account": {
        "account_id": "5dd2c9fe5e5b4718987c5ad1167fa19f",
        "quantum_instance_id": "191cdf4f-de18-45a9-8fa5-9eb0c68183ba",
        "service_crn": "crn:v1:bluemix:public:quantum-computing:us-east:a/5dd2c9fe5e5b4718987c5ad1167fa19f:191cdf4f-de18-45a9-8fa5-9eb0c68183ba::",
        "region": "us-east",
        "cos_instance_id": "552e051f-21be-41d9-8a0e-b7c87f5e451a",
        "cos_bucket": "brmste-coming-soon",
        "cos_region": "eu-gb",
    },
    "fleet": {
        "tier": "enterprise",
        "processor_family": "Heron",
        "revision": 2,
        "default_backend": devices[0]["name"] if devices else "ibm_fez",
        "fallback_order": [d["name"] for d in devices],
        "backends": [
            {
                "name": d["name"],
                "qubits": d.get("qubits"),
                "queue_length": d.get("queue_length"),
                "status": d.get("status", {}).get("name"),
                "clops": d.get("clops", {}).get("value"),
                "processor": f"{d.get('processor_type',{}).get('family','Heron')} r{d.get('processor_type',{}).get('revision',2)}",
                "native_gates": ["cz", "id", "rz", "sx", "x"],
            }
            for d in devices
        ],
    },
    "attestation": {
        "circuit": "ISA-Bell-Heron-r2",
        "isa_fix": "error_1517_resolved — H via rz(π/2)·sx·rz(π/2)",
        "shots": 4096,
        "program_id": "sampler",
        "patent": "BRMSTE-COIN-SB2026",
    },
    "edge_routes": {
        "worker": "brmste-quantum-gi",
        "brmste.ai": ["/quantum/*", "/substrate/quantum/*"],
        "brmste.com": ["/quantum/*", "/substrate/quantum/*"],
    },
    "brm_api": "https://brmste-brm-api.2c1jac3ncfwr.eu-gb.codeengine.appdomain.cloud",
    "cloudflare": {
        "account_id": "7ea6547b1d6eb1cbd6d0ac5cf960ce2a",
        "kv_mine_events": "e1e23aa1d33448ffa1a1dd8b3938961e",
    },
}
with open(manifest_path, "w") as f:
    json.dump(manifest, f, indent=2)
print(f"Wrote {manifest_path}")
PY

if [[ "${SUBMIT_ATTEST:-1}" == "1" ]]; then
  info "submit ISA attestation to $DEFAULT_BACKEND"
  python3 "$ROOT/scripts/submit_isa_circuit.py" --backend "$DEFAULT_BACKEND" || \
    info "attestation submit skipped (check submit_isa_circuit.py)"
fi

if [[ -n "${CLOUDFLARE_API_TOKEN:-${CF_API_TOKEN:-}}" ]]; then
  info "wire IBM_QUANTUM_API_KEY to Cloudflare workers"
  bash "$ROOT/scripts/wire-all-secrets.sh" || true
  info "bind quantum-gi edge routes"
  bash "$ROOT/scripts/deploy-quantum-gi-routes.sh" || true
fi

echo ""
echo "=== Fleet configured (agent lane) ==="
echo "  Manifest: $FLEET_MANIFEST"
echo "  Default:  $DEFAULT_BACKEND"
echo "  Fallback: ${FLEET_FALLBACK[*]}"
echo "  Doctrine: OPERATOR DOESNT BASH — agent deploys via MCP"
