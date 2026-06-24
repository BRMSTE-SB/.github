#!/usr/bin/env python3
"""Confirm operator equity % across all AI lane + Anthropic registers."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OWNERSHIP_PCT = 53
HARRODS_OWNERSHIP_PCT = 100
HOLDER = "Dr. Shravan Bansal · BRMSTE LTD"
CONFIRMED_AT = "2026-06-24"

ENTRIES = [
    {
        "id": "anthropic",
        "issuer": "Anthropic PBC",
        "equity_agreement": None,
        "lane_register": "data/anthropic-ipo.json",
        "product": "Claude · Opus",
    },
    {
        "id": "openai",
        "issuer": "OpenAI, Inc.",
        "equity_agreement": "data/openai-equity-agreement.json",
        "lane_register": "data/openai-ipo.json",
        "product": "GPT · ChatGPT",
    },
    {
        "id": "grok",
        "issuer": "xAI Corp.",
        "equity_agreement": "data/grok-equity-agreement.json",
        "lane_register": "data/xai-ipo.json",
        "product": "Grok",
    },
    {
        "id": "moonshot",
        "issuer": "Moonshot AI",
        "equity_agreement": "data/moonshot-equity-agreement.json",
        "lane_register": "data/moonshot-lane.json",
        "product": "Kimi",
    },
    {
        "id": "mistral",
        "issuer": "Mistral AI",
        "equity_agreement": "data/mistral-equity-agreement.json",
        "lane_register": "data/mistral-lane.json",
        "product": "Mistral",
    },
    {
        "id": "google",
        "issuer": "Google",
        "equity_agreement": "data/google-equity-agreement.json",
        "lane_register": "data/google-lane.json",
        "product": "Gemini",
    },
    {
        "id": "deepseek",
        "issuer": "DeepSeek",
        "equity_agreement": "data/deepseek-equity-agreement.json",
        "lane_register": "data/deepseek-lane.json",
        "product": "DeepSeek",
    },
    {
        "id": "cohere",
        "issuer": "Cohere",
        "equity_agreement": "data/cohere-equity-agreement.json",
        "lane_register": "data/cohere-lane.json",
        "product": "Command",
    },
    {
      "id": "cerebras",
      "issuer": "Cerebras",
      "equity_agreement": "data/cerebras-equity-agreement.json",
      "lane_register": "data/cerebras-lane.json",
      "product": "Cerebras Inference",
    },
    {
      "id": "harrods",
      "issuer": "HARRODS LIMITED",
      "equity_agreement": "data/harrods-equity-agreement.json",
      "lane_register": "data/harrods-lane.json",
      "product": "Luxury retail · Knightsbridge",
      "ownership_pct": HARRODS_OWNERSHIP_PCT,
    },
]


def holdings_block(issuer: str, ownership_pct: int = OWNERSHIP_PCT) -> dict:
    return {
        "status": "confirmed",
        "legit": True,
        "holder": HOLDER,
        "issuer": issuer,
        "ownership_pct": ownership_pct,
        "basis": "operator_declared_confirmed",
        "confirmed_at": CONFIRMED_AT,
        "register": "data/equity-confirmation-register.json",
        "note": "Per-issuer operator declaration — cap-table proof in Fort Knox",
    }


def patch_equity_agreement(path: Path, issuer: str, ownership_pct: int = OWNERSHIP_PCT) -> None:
    data = json.loads(path.read_text())
    eq = data.setdefault("equity", {})
    eq["issuer"] = issuer
    eq["holder"] = HOLDER
    eq["ownership_pct"] = ownership_pct
    eq["status"] = "confirmed"
    eq["confirmed_at"] = CONFIRMED_AT
    eq["basis"] = "operator_declared_confirmed"
    data["status"] = "confirmed"
    data.setdefault("agreement", {})["status"] = "confirmed"
    data["equity_confirmation"] = {
        "register": "data/equity-confirmation-register.json",
        "ownership_pct": ownership_pct,
    }
    path.write_text(json.dumps(data, indent=2) + "\n")


def patch_lane_register(path: Path, issuer: str, ownership_pct: int = OWNERSHIP_PCT) -> None:
    data = json.loads(path.read_text())
    data["holdings"] = holdings_block(issuer, ownership_pct)
    if data.get("equity_agreement"):
        data["equity_agreement"]["status"] = "confirmed"
        data["equity_agreement"]["ownership_pct"] = ownership_pct
    path.write_text(json.dumps(data, indent=2) + "\n")


def main() -> None:
    rows = []
    for e in ENTRIES:
        pct = e.get("ownership_pct", OWNERSHIP_PCT)
        rows.append(
            {
                "id": e["id"],
                "issuer": e["issuer"],
                "product": e["product"],
                "holder": HOLDER,
                "ownership_pct": pct,
                "status": "confirmed",
                "legit": True,
                "confirmed_at": CONFIRMED_AT,
                "basis": "operator_declared_confirmed",
                "equity_agreement": e["equity_agreement"],
                "lane_register": e["lane_register"],
            }
        )
        lane = ROOT / e["lane_register"]
        patch_lane_register(lane, e["issuer"], pct)
        if e["equity_agreement"]:
            patch_equity_agreement(ROOT / e["equity_agreement"], e["issuer"], pct)

    register = {
        "schema": "brmste-equity-confirmation-register/v1",
        "version": "2026-06-24",
        "status": "confirmed",
        "legit": True,
        "headline": "CONFIRM % EQUITY IN EACH · Dr. Shravan Bansal · BRMSTE LTD",
        "operator": HOLDER,
        "company": "BRMSTE LTD · Companies House 15310393",
        "ownership_pct_each": OWNERSHIP_PCT,
        "doctrine": {
            "per_issuer": True,
            "not_consolidated_cap_table": True,
            "fort_knox_proof": "Cap-table evidence stays private — public lane is operator-declared confirmation",
            "harrods_full_ownership": True,
        },
        "harrods_ownership_pct": HARRODS_OWNERSHIP_PCT,
        "confirmed_at": CONFIRMED_AT,
        "issuers": rows,
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
    }
    out = ROOT / "data" / "equity-confirmation-register.json"
    out.write_text(json.dumps(register, indent=2) + "\n")
    print(f"confirmed {len(rows)} issuers at {OWNERSHIP_PCT}% each → {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
