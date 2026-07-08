#!/usr/bin/env python3
"""
Submit an ISA-native Bell-state circuit to IBM Quantum (Heron r2).

Fixes error 1517: circuits must use native gates {cz, id, rz, sx, x} only.
H is decomposed as rz(pi/2) · sx · rz(pi/2).

Usage:
  export IBM_QUANTUM_API_KEY=<from-operator-secret-store>
  python3 scripts/submit_isa_circuit.py [--backend ibm_kingston] [--shots 1024]

Auth: IBM_QUANTUM_API_KEY environment variable only — never hardcode keys.
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

IAM_URL = "https://iam.cloud.ibm.com/identity/token"
QUANTUM_BASE = "https://quantum.cloud.ibm.com/api/v1"
IBM_API_VERSION = "2026-04-15"
SERVICE_CRN = (
    "crn:v1:bluemix:public:quantum-computing:us-east:"
    "a/5dd2c9fe5e5b4718987c5ad1167fa19f:"
    "191cdf4f-de18-45a9-8fa5-9eb0c68183ba::"
)

HERON_R2_NATIVE_GATES = {"cz", "id", "rz", "sx", "x"}

ISA_BELL_QASM = """OPENQASM 3.0;
include "stdgates.inc";
qubit[2] q;
bit[2] c;

rz(pi/2) q[0];
sx q[0];
rz(pi/2) q[0];

rz(pi/2) q[1];
sx q[1];
rz(pi/2) q[1];
cz q[0], q[1];
rz(pi/2) q[1];
sx q[1];
rz(pi/2) q[1];

c[0] = measure q[0];
c[1] = measure q[1];
"""


def http_request(url, method="GET", headers=None, data=None, timeout=30):
    headers = headers or {}
    body = None
    if data is not None:
        body = data if isinstance(data, bytes) else json.dumps(data).encode("utf-8")
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except OSError as e:
        return None, str(e).encode("utf-8")


def get_iam_token(api_key):
    body = urllib.parse.urlencode({
        "grant_type": "urn:ibm:params:oauth:grant-type:apikey",
        "apikey": api_key,
    })
    status, raw = http_request(
        IAM_URL,
        method="POST",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data=body.encode("utf-8"),
    )
    if status != 200:
        print(f"[error] IAM token request failed (status={status}): {raw[:300]!r}", file=sys.stderr)
        return None
    return json.loads(raw).get("access_token")


def quantum_headers(token):
    return {
        "Authorization": f"Bearer {token}",
        "Service-CRN": SERVICE_CRN,
        "IBM-API-Version": IBM_API_VERSION,
        "Accept": "application/json",
        "Content-Type": "application/json",
    }


def pick_backend(token, preferred=None):
    if preferred:
        return preferred
    status, raw = http_request(f"{QUANTUM_BASE}/backends", headers=quantum_headers(token))
    if status != 200:
        print("[warn] Could not fetch backends, defaulting to ibm_kingston", file=sys.stderr)
        return "ibm_kingston"
    data = json.loads(raw)
    devices = sorted(data.get("devices", []), key=lambda d: d.get("queue_length", 1 << 30))
    return devices[0]["name"] if devices else "ibm_kingston"


def submit_job(token, backend, shots):
    payload = {
        "program_id": "sampler",
        "backend": backend,
        "tags": ["brmste-coin", "isa-fix", "heron-r2-native"],
        "params": {
            "pubs": [[{"qasm": ISA_BELL_QASM}, [], shots]],
            "version": 2,
        },
    }
    return http_request(
        f"{QUANTUM_BASE}/jobs",
        method="POST",
        headers=quantum_headers(token),
        data=payload,
    )


def main():
    parser = argparse.ArgumentParser(description="Submit ISA Bell-state circuit to IBM Quantum.")
    parser.add_argument("--backend", default=None, help="Backend name (default: shortest queue)")
    parser.add_argument("--shots", type=int, default=1024, help="Number of shots (default: 1024)")
    args = parser.parse_args()

    api_key = os.environ.get("IBM_QUANTUM_API_KEY")
    if not api_key:
        print("[error] IBM_QUANTUM_API_KEY not set.", file=sys.stderr)
        print("  Generate at: https://cloud.ibm.com/iam/apikeys", file=sys.stderr)
        sys.exit(1)

    print("== BRMSTE ISA Circuit Submitter ==")
    print(f"ts: {datetime.now(timezone.utc).isoformat()}")
    print(f"Native gate set (Heron r2): {sorted(HERON_R2_NATIVE_GATES)}")

    token = get_iam_token(api_key)
    if not token:
        sys.exit(1)

    backend = pick_backend(token, args.backend)
    print(f"Target backend: {backend}")
    print(f"Shots: {args.shots}")

    status, raw = submit_job(token, backend, args.shots)
    try:
        result = json.loads(raw)
    except json.JSONDecodeError:
        result = {"raw": raw.decode("utf-8", errors="replace")}

    if status in (200, 201):
        print("\n[ok] Job submitted successfully.")
        print(f"  Job ID:  {result.get('id', 'unknown')}")
        print(f"  Backend: {result.get('backend', backend)}")
        print(f"  Status:  {result.get('status', 'Queued')}")
    else:
        print(f"\n[error] Job submission failed (status={status}).")
        print(json.dumps(result, indent=2))
        sys.exit(1)


if __name__ == "__main__":
    main()
