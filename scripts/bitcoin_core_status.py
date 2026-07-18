#!/usr/bin/env python3
"""BRMSTE Bitcoin Core status — read-only node query.

Queries a Bitcoin Core node via JSON-RPC (getblockchaininfo + getmempoolinfo).
Credentials from env only (AGENTS.md — never chat, never committed):

    BITCOIN_RPC_URL       e.g. http://127.0.0.1:8332
    BITCOIN_RPC_USER
    BITCOIN_RPC_PASSWORD

Read-only: this never creates or signs a transaction — signing is edge/judgment
only. With --dry-run it builds the RPC request without any network call.

Usage:
    python scripts/bitcoin_core_status.py
    python scripts/bitcoin_core_status.py --dry-run
"""
from __future__ import annotations

import argparse
import json
import os
import sys


def _fail(msg: str) -> "NoReturn":  # type: ignore[name-defined]
    print(f"BITCOIN-CORE FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def rpc(url: str, user: str, pw: str, method: str, params=None):
    import requests

    resp = requests.post(
        url,
        auth=(user, pw),
        json={"jsonrpc": "1.0", "id": "brmste", "method": method, "params": params or []},
        timeout=30,
    )
    if resp.status_code >= 400:
        _fail(f"RPC {method} {resp.status_code}: {resp.text[:200]}")
    body = resp.json()
    if body.get("error"):
        _fail(f"RPC {method} error: {body['error']}")
    return body["result"]


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="BRMSTE Bitcoin Core read-only status")
    ap.add_argument("--dry-run", action="store_true", help="build request, no network call")
    args = ap.parse_args(argv)

    calls = ["getblockchaininfo", "getmempoolinfo"]
    if args.dry_run:
        print(json.dumps({"dry_run": True, "rpc_calls": calls}, indent=2))
        return 0

    url = os.environ.get("BITCOIN_RPC_URL")
    user = os.environ.get("BITCOIN_RPC_USER")
    pw = os.environ.get("BITCOIN_RPC_PASSWORD")
    if not url:
        _fail("BITCOIN_RPC_URL not set in environment")
    if not user or not pw:
        _fail("BITCOIN_RPC_USER / BITCOIN_RPC_PASSWORD not set in environment")

    chain = rpc(url, user, pw, "getblockchaininfo")
    mem = rpc(url, user, pw, "getmempoolinfo")
    out = {
        "chain": chain.get("chain"),
        "blocks": chain.get("blocks"),
        "headers": chain.get("headers"),
        "verificationprogress": chain.get("verificationprogress"),
        "mempool_txs": mem.get("size"),
        "mempool_bytes": mem.get("bytes"),
        "settle_to": "bc1qcsa002syumyzxystxgq0qr36ak5zp40agmpmfk",
    }
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
