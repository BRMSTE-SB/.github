#!/usr/bin/env bash
# Verify the BRMSTE quantum × USDC kit manifests.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${QUANTUM_DIR:-$ROOT/data/quantum}"

fail() { echo "QUANTUM KITS VERIFY FAIL: $*" >&2; exit 1; }
ok() { echo "QUANTUM KITS VERIFY OK: $*"; }

for f in kits.json cuquantum-kit.json qiskit-kit.json quantum-usdc-settle.json; do
  [[ -f "$DIR/$f" ]] || fail "manifest missing: $DIR/$f"
done
[[ -f "$ROOT/data/ibm/quantum-fleet.json" ]] || fail "missing fleet manifest data/ibm/quantum-fleet.json"

python3 - "$DIR" "$ROOT" <<'PY'
import json, os, sys

d, root = sys.argv[1], sys.argv[2]
def load(p):
    return json.loads(open(p).read())

NATIVE = ["cz", "id", "rz", "sx", "x"]

kits = load(os.path.join(d, "kits.json"))
if kits.get("schema") != "brmste-quantum-usdc-kits/v1":
    raise SystemExit("kits.json: bad schema")
if kits.get("companies_house") != "15310393":
    raise SystemExit("kits.json: companies_house must be 15310393")
ids = [k["id"] for k in kits["kits"]]
for want in ("cuquantum", "qiskit"):
    if want not in ids:
        raise SystemExit(f"kits.json: missing kit {want}")
if kits["counts"]["kits"] != len(kits["kits"]):
    raise SystemExit("kits.json: counts.kits mismatch")
if kits["fleet"]["native_gates"] != NATIVE:
    raise SystemExit("kits.json: native_gates must be cz,id,rz,sx,x")
print(f"kits ok: {', '.join(ids)}")

cq = load(os.path.join(d, "cuquantum-kit.json"))
if cq.get("compute") != "gpu" or not cq.get("requires", {}).get("nvidia_gpu"):
    raise SystemExit("cuquantum-kit.json: must be gpu-gated (requires nvidia_gpu)")
print("cuquantum ok: gpu-gated")

qk = load(os.path.join(d, "qiskit-kit.json"))
ft = qk.get("fleet_tuning", {})
if ft.get("native_gates") != NATIVE:
    raise SystemExit("qiskit-kit.json: native_gates must be cz,id,rz,sx,x")
if "error_1517" not in ft.get("isa_fix", ""):
    raise SystemExit("qiskit-kit.json: isa_fix must reference error_1517")
if ft.get("default_backend") != "ibm_marrakesh":
    raise SystemExit("qiskit-kit.json: default_backend must be ibm_marrakesh")
print("qiskit ok: Heron r2 tuned, ISA fix present")

st = load(os.path.join(d, "quantum-usdc-settle.json"))
if st.get("asset") != "USDC":
    raise SystemExit("quantum-usdc-settle.json: asset must be USDC")
polygon = next((r for r in st["settle_rails"] if r["id"] == "openusd"), None)
if not polygon or polygon.get("usdc_token_polygon") != "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359":
    raise SystemExit("quantum-usdc-settle.json: polygon USDC token mismatch")
if st["burn_earn"]["principle"] != "token_burn_equals_token_earned":
    raise SystemExit("quantum-usdc-settle.json: burn_earn principle mismatch")

# settle manifests must exist (wired to the payments rails)
for r in st["settle_rails"]:
    mp = os.path.join(root, r["manifest"])
    if not os.path.isfile(mp):
        raise SystemExit(f"quantum-usdc-settle.json: settle rail manifest missing: {r['manifest']}")
print("usdc-settle ok: rails wired, burn=earn 1:1")

# fleet native-gate consistency
fleet = load(os.path.join(root, "data/ibm/quantum-fleet.json"))
for b in fleet["fleet"]["backends"]:
    if b["native_gates"] != NATIVE:
        raise SystemExit(f"fleet backend {b['name']}: native_gates drift")
print(f"fleet ok: {len(fleet['fleet']['backends'])} Heron r2 backend(s)")
PY

ok "quantum kits ${DIR}"
