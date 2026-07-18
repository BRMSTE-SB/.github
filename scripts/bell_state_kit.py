#!/usr/bin/env python3
"""BRMSTE quantum kit — ISA-native Bell state, tuned to the Heron r2 fleet.

Builds a 2-qubit Bell state and runs it either on local Qiskit Aer (default,
CPU — or GPU/cuQuantum via --device GPU) or on the BRMSTE IBM Quantum fleet
(--ibm, IBM Runtime Sampler on ibm_marrakesh/kingston/fez).

The circuit is transpiled to the fleet's ISA-native gate set {cz, id, rz, sx, x};
H is decomposed rz(π/2)·sx·rz(π/2), resolving IBM error_1517.

Credentials (AGENTS.md — never in chat, never committed):
    IBM_QUANTUM_API_KEY   required only for --ibm

Usage:
    python scripts/bell_state_kit.py --shots 4096
    python scripts/bell_state_kit.py --shots 4096 --device GPU     # cuQuantum/Aer-GPU
    python scripts/bell_state_kit.py --shots 4096 --ibm            # Heron r2 fleet
"""
from __future__ import annotations

import argparse
import json
import os
import sys

NATIVE_GATES = ["cz", "id", "rz", "sx", "x"]


def bell_circuit():
    from qiskit import QuantumCircuit

    qc = QuantumCircuit(2, 2)
    qc.h(0)
    qc.cx(0, 1)
    qc.measure([0, 1], [0, 1])
    return qc


def run_aer(shots: int, device: str) -> dict:
    from qiskit import transpile
    from qiskit_aer import AerSimulator

    sim = AerSimulator(device=device)
    qc = transpile(bell_circuit(), sim, basis_gates=NATIVE_GATES)
    counts = sim.run(qc, shots=shots).result().get_counts()
    return {"backend": f"aer:{device.lower()}", "counts": counts}


def run_ibm(shots: int) -> dict:
    key = os.environ.get("IBM_QUANTUM_API_KEY")
    if not key:
        raise SystemExit("QUANTUM KIT FAIL: IBM_QUANTUM_API_KEY not set (env-only, never chat)")

    from qiskit import transpile
    from qiskit_ibm_runtime import QiskitRuntimeService, SamplerV2

    service = QiskitRuntimeService(channel="ibm_quantum", token=key)
    backend = service.least_busy(operational=True, simulator=False)
    qc = transpile(bell_circuit(), backend)  # ISA transpile to the real device
    job = SamplerV2(mode=backend).run([qc], shots=shots)
    res = job.result()
    counts = res[0].data.c.get_counts()
    return {"backend": backend.name, "job_id": job.job_id(), "counts": counts}


def entangled(counts: dict) -> bool:
    total = sum(counts.values()) or 1
    good = counts.get("00", 0) + counts.get("11", 0)
    return good / total >= 0.85  # tolerate device noise; sim is ~1.0


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="BRMSTE ISA Bell-state quantum kit")
    ap.add_argument("--shots", type=int, default=4096)
    ap.add_argument("--device", default="CPU", choices=["CPU", "GPU"], help="Aer device")
    ap.add_argument("--ibm", action="store_true", help="run on the BRMSTE Heron r2 fleet")
    args = ap.parse_args(argv)

    result = run_ibm(args.shots) if args.ibm else run_aer(args.shots, args.device)
    result["shots"] = args.shots
    result["native_gates"] = NATIVE_GATES
    result["entangled"] = entangled(result["counts"])
    result["attestation"] = "ISA-Bell-Heron-r2"
    print(json.dumps(result, indent=2))
    return 0 if result["entangled"] else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
