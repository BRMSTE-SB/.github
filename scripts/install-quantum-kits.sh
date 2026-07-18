#!/usr/bin/env bash
# Install BRMSTE quantum × USDC kits: IBM Qiskit (Aer + IBM Runtime) always,
# NVIDIA cuQuantum when a CUDA GPU is present. SDKs only — no credentials.
# Credentials (IBM_QUANTUM_API_KEY, CDP_*) are read from env at runtime (AGENTS.md).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PYTHON:-python3}"
VENV="${QUANTUM_VENV:-$ROOT/.venv-quantum}"

echo "BRMSTE quantum-kits install → $VENV"
"$PY" -m venv "$VENV"
# shellcheck disable=SC1091
source "$VENV/bin/activate"
pip install --upgrade pip >/dev/null

# Qiskit kit — always (CPU-runnable, GPU-optional via qiskit-aer-gpu)
pip install "qiskit" "qiskit-aer" "qiskit-ibm-runtime"

# cuQuantum kit — GPU-gated. Only attempt when an NVIDIA GPU + CUDA is detectable.
if command -v nvidia-smi >/dev/null 2>&1; then
  echo "NVIDIA GPU detected — installing cuQuantum (CUDA 12 build) + Aer GPU"
  pip install "cuquantum-python-cu12" "qiskit-aer-gpu" || \
    echo "::warning:: cuQuantum/Aer-GPU install failed — CPU Aer remains available"
else
  echo "::warning:: no NVIDIA GPU (nvidia-smi absent) — skipping cuQuantum; Qiskit Aer (CPU) is the fallback"
fi

echo "--- installed versions ---"
python - <<'PY'
import importlib.metadata as m
for pkg in ("qiskit", "qiskit-aer", "qiskit-ibm-runtime", "cuquantum-python-cu12"):
    try:
        print(f"{pkg} == {m.version(pkg)}")
    except Exception:
        print(f"{pkg} == (not installed)")
PY

echo "BRMSTE quantum-kits install OK"
echo "Verify: bash scripts/verify-quantum-kits.sh"
echo "Run   : python scripts/bell_state_kit.py --shots 4096   (add --ibm for the Heron r2 fleet)"
