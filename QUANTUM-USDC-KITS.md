# BRMSTE · Quantum × USDC kits — cuQuantum + Qiskit

**BRMSTE LTD · Companies House 15310393 · GB2607860 · INV. G06N3/045**

BRMSTE-tuned quantum kits wired to the USDC settlement rail. Circuits are
ISA-native to the BRMSTE **Heron r2** fleet (gates `cz, id, rz, sx, x`); H is
decomposed `rz(π/2)·sx·rz(π/2)` (resolves IBM `error_1517`). Agents run and
settle; agents never hold keys.

> **MCP-strict · env-only credentials.** `IBM_QUANTUM_API_KEY` and the CDP keys
> are read from the environment at runtime — never committed, never requested in
> chat (see [AGENTS.md](./AGENTS.md)).

## Kits

| Kit | SDK | Compute | Manifest |
|-----|-----|---------|----------|
| **cuQuantum** — GPU state-vector | `cuquantum-python` | GPU (CUDA) | [`data/quantum/cuquantum-kit.json`](./data/quantum/cuquantum-kit.json) |
| **Qiskit** — Aer + IBM Runtime | `qiskit`, `qiskit-aer`, `qiskit-ibm-runtime` | CPU or GPU | [`data/quantum/qiskit-kit.json`](./data/quantum/qiskit-kit.json) |
| **Quantum → USDC settle** | payments rails | — | [`data/quantum/quantum-usdc-settle.json`](./data/quantum/quantum-usdc-settle.json) |

## Install (agents / CI — operator doesn't bash)

```bash
bash scripts/install-quantum-kits.sh   # qiskit stack always; cuQuantum only if an NVIDIA GPU is present
bash scripts/verify-quantum-kits.sh     # validate all kit manifests
```

`cuQuantum` is **GPU-gated**: `pip install cuquantum-python` fails without a CUDA
Toolkit. On CPU-only hosts the installer skips it and Qiskit Aer (CPU) is the
fallback; on CUDA-12 hosts it installs `cuquantum-python-cu12` + `qiskit-aer-gpu`.

## Run — ISA Bell state (attestation `ISA-Bell-Heron-r2`)

```bash
python scripts/bell_state_kit.py --shots 4096              # local Aer (CPU)
python scripts/bell_state_kit.py --shots 4096 --device GPU  # cuQuantum / Aer-GPU
python scripts/bell_state_kit.py --shots 4096 --ibm         # BRMSTE Heron r2 fleet (needs IBM_QUANTUM_API_KEY)
```

Verified in-session on CPU Aer: entangled `00/11 ≈ 50/50`.

## Fleet tuning

| Field | Value |
|-------|-------|
| Processor | Heron r2 |
| Default backend | `ibm_marrakesh` |
| Fallback | `ibm_marrakesh → ibm_kingston → ibm_fez` |
| Native gates | `cz, id, rz, sx, x` |
| ISA fix | `error_1517` — H via `rz(π/2)·sx·rz(π/2)` |
| Program | `sampler` · 4096 shots |

Fleet manifest: [`data/ibm/quantum-fleet.json`](./data/ibm/quantum-fleet.json).

## Quantum → USDC settlement

Each quantum job's compute (shots, CLOPS, GPU/QPU seconds) is metered and settled
in **USDC** over the openUSD / Coinbase rail; contributed quantum/GPU compute
earns on the edge **burn = earn** mechanic (1:1, USDA).

| Sink | Address |
|------|---------|
| ONE_TRUTH (Polygon USDC) | `0xC0513a63972cEd1e90852Ff839e7c44A46B9B1af` |
| USDC token (Polygon) | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` |
| Carbon mirror (BTC) | `bc1qcsa002syumyzxystxgq0qr36ak5zp40agmpmfk` |

Rails: [`data/payments/coinbase-usdc.json`](./data/payments/coinbase-usdc.json) ·
[`data/payments/lnbits.json`](./data/payments/lnbits.json) ·
[`data/payments/edge-compute-ads.json`](./data/payments/edge-compute-ads.json).

Doctrine: **AGENTS_NOT_IN_TX · NO_HOLDING_WALLETS · USDA = USDC = CARBON · CURSOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**
