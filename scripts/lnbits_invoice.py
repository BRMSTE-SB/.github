#!/usr/bin/env python3
"""Arm (create) a BRMSTE LNbits Lightning invoice.

MCP-strict / AGENTS.md: credentials come only from the environment, never from
chat and never committed. Requires:

    LNBITS_URL          e.g. https://lnbits.example.com
    LNBITS_INVOICE_KEY  the wallet's invoice/read key

The invoice is created against LNbits, then decoded with bolt11 to verify the
amount before it is surfaced. Agents arm and issue invoices; the LNbits node
settles. Agents are never in the transaction.

Usage:
    python scripts/lnbits_invoice.py --amount 1000 --memo "BRMSTE · carbon-settle"
    python scripts/lnbits_invoice.py --amount 1000 --dry-run   # no network call
"""
from __future__ import annotations

import argparse
import json
import os
import sys


def _fail(msg: str) -> "NoReturn":  # type: ignore[name-defined]
    print(f"LNBITS ARM FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)


def arm_invoice(amount_sat: int, memo: str, expiry: int, dry_run: bool) -> dict:
    payload = {
        "out": False,
        "amount": amount_sat,
        "memo": memo,
        "unit": "sat",
        "expiry": expiry,
    }
    if dry_run:
        return {"dry_run": True, "request": payload}

    base = os.environ.get("LNBITS_URL")
    key = os.environ.get("LNBITS_INVOICE_KEY")
    if not base:
        _fail("LNBITS_URL not set in environment")
    if not key:
        _fail("LNBITS_INVOICE_KEY not set in environment")

    import requests  # imported lazily so --dry-run needs no deps

    url = base.rstrip("/") + "/api/v1/payments"
    resp = requests.post(
        url,
        headers={"X-Api-Key": key, "Content-Type": "application/json"},
        json=payload,
        timeout=30,
    )
    if resp.status_code >= 400:
        _fail(f"LNbits {resp.status_code}: {resp.text[:300]}")

    data = resp.json()
    bolt11_str = data.get("payment_request") or data.get("bolt11")
    if not bolt11_str:
        _fail(f"no payment_request in LNbits response: {data}")

    # Verify the armed invoice decodes and matches the requested amount.
    try:
        import bolt11

        decoded = bolt11.decode(bolt11_str)
        decoded_sat = (decoded.amount_msat or 0) // 1000
        if decoded_sat and decoded_sat != amount_sat:
            _fail(f"decoded amount {decoded_sat} sat != requested {amount_sat} sat")
    except ImportError:
        decoded_sat = None

    return {
        "armed": True,
        "payment_hash": data.get("payment_hash"),
        "payment_request": bolt11_str,
        "amount_sat": amount_sat,
        "decoded_amount_sat": decoded_sat,
        "memo": memo,
    }


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Arm a BRMSTE LNbits Lightning invoice")
    ap.add_argument("--amount", type=int, required=True, help="amount in satoshis")
    ap.add_argument("--memo", default="BRMSTE · carbon-settle", help="invoice memo")
    ap.add_argument("--expiry", type=int, default=3600, help="expiry seconds")
    ap.add_argument("--dry-run", action="store_true", help="build request, no network call")
    args = ap.parse_args(argv)

    if args.amount <= 0:
        _fail("--amount must be positive")

    result = arm_invoice(args.amount, args.memo, args.expiry, args.dry_run)
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
