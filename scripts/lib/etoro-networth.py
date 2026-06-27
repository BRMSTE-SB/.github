#!/usr/bin/env python3
"""BRMSTE banking net worth valuation from eToro clientPortfolio (PnL snapshot).

Formulas follow eToro Public API guides:
  Equity = Available Cash + Total Invested + Unrealized PnL
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from typing import Any


def _num(value: Any) -> float:
    if value is None:
        return 0.0
    return float(value)


def _position_pnl(position: dict[str, Any]) -> float:
    unrealized = position.get("unrealizedPnL")
    if isinstance(unrealized, dict):
        return _num(unrealized.get("pnL"))
    return _num(unrealized)


def _reserved_open_orders(portfolio: dict[str, Any]) -> float:
    reserved = 0.0
    for order in portfolio.get("ordersForOpen") or []:
        if _num(order.get("mirrorID")) == 0:
            reserved += _num(order.get("amount"))
    for order in portfolio.get("orders") or []:
        reserved += _num(order.get("amount"))
    return reserved


def _total_invested(portfolio: dict[str, Any]) -> float:
    invested = 0.0

    for position in portfolio.get("positions") or []:
        invested += _num(position.get("amount"))

    for mirror in portfolio.get("mirrors") or []:
        invested += _num(mirror.get("availableAmount")) - _num(
            mirror.get("closedPositionsNetProfit")
        )
        for position in mirror.get("positions") or []:
            invested += _num(position.get("amount"))

    for order in portfolio.get("ordersForOpen") or []:
        if _num(order.get("mirrorID")) == 0:
            invested += _num(order.get("amount"))
            invested += _num(order.get("totalExternalCosts"))

    for order in portfolio.get("orders") or []:
        invested += _num(order.get("amount"))

    return invested


def _unrealized_pnl(portfolio: dict[str, Any]) -> float:
    pnl = 0.0

    for position in portfolio.get("positions") or []:
        pnl += _position_pnl(position)

    for mirror in portfolio.get("mirrors") or []:
        pnl += _num(mirror.get("closedPositionsNetProfit"))
        for position in mirror.get("positions") or []:
            pnl += _position_pnl(position)

    return pnl


def compute_valuation(
    portfolio: dict[str, Any],
    *,
    currency: str = "USD",
    source: str = "etoro_pnl",
    environment: str | None = None,
) -> dict[str, Any]:
    """Compute banking net worth metrics from a clientPortfolio object."""
    credit = _num(portfolio.get("credit"))
    bonus_credit = _num(portfolio.get("bonusCredit"))
    reserved_orders = _reserved_open_orders(portfolio)
    available_cash = credit - reserved_orders
    total_invested = _total_invested(portfolio)
    unrealized_pnl = _unrealized_pnl(portfolio)
    equity = available_cash + total_invested + unrealized_pnl

    positions = portfolio.get("positions") or []
    mirrors = portfolio.get("mirrors") or []

    return {
        "schema": "brmste-banking-networth-valuation/v1",
        "source": source,
        "currency": currency,
        "environment": environment,
        "asOf": datetime.now(timezone.utc).isoformat(),
        "cash": {
            "credit": round(credit, 2),
            "bonusCredit": round(bonus_credit, 2),
            "reservedOrders": round(reserved_orders, 2),
            "availableCash": round(available_cash, 2),
        },
        "invested": {
            "totalInvested": round(total_invested, 2),
            "openPositions": len(positions),
            "activeMirrors": len(mirrors),
        },
        "pnl": {
            "unrealized": round(unrealized_pnl, 2),
        },
        "netWorth": {
            "equity": round(equity, 2),
            "label": "Real-time cash net worth (banking valuation)",
        },
        "formula": {
            "equity": "availableCash + totalInvested + unrealizedPnL",
            "docs": "https://api-portal.etoro.com/guides/calculate-equity",
        },
    }


def valuation_from_pnl_response(
    payload: dict[str, Any],
    *,
    environment: str | None = None,
) -> dict[str, Any]:
    portfolio = payload.get("clientPortfolio")
    if not isinstance(portfolio, dict):
        raise ValueError("payload missing clientPortfolio object")
    return compute_valuation(portfolio, environment=environment)


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: etoro-networth.py <pnl-json-file|-]", file=sys.stderr)
        return 2

    source = sys.stdin if sys.argv[1] == "-" else open(sys.argv[1], encoding="utf-8")
    with source:
        payload = json.load(source)

    env = None
    if len(sys.argv) > 2:
        env = sys.argv[2]

    result = valuation_from_pnl_response(payload, environment=env)
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
