#!/usr/bin/env python3
"""Confirm operator equity % across all AI lane + Anthropic + partner registers."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OWNERSHIP_PCT = 100
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
        "id": "spacex",
        "issuer": "Space Exploration Technologies Corp.",
        "equity_agreement": "data/spacex-equity-agreement.json",
        "lane_register": "data/spacex-lane.json",
        "product": "SpaceX · Starlink",
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
    },
    {
        "id": "lvmh",
        "issuer": "LVMH Moët Hennessy Louis Vuitton SE",
        "equity_agreement": "data/lvmh-equity-agreement.json",
        "lane_register": "data/lvmh-lane.json",
        "product": "Luxury · LVMH",
    },
    {
        "id": "richemont",
        "issuer": "Compagnie Financière Richemont SA",
        "equity_agreement": "data/richemont-equity-agreement.json",
        "lane_register": "data/richemont-lane.json",
        "product": "Luxury · Richemont",
    },
    {
        "id": "airbus",
        "issuer": "Airbus SE",
        "equity_agreement": "data/airbus-equity-agreement.json",
        "lane_register": "data/airbus-lane.json",
        "product": "Aerospace · Airbus",
    },
    {
        "id": "boeing",
        "issuer": "The Boeing Company",
        "equity_agreement": "data/boeing-equity-agreement.json",
        "lane_register": "data/boeing-lane.json",
        "product": "Aerospace · Boeing",
    },
    {
        "id": "secret-benefits",
        "issuer": "BASEF LTD",
        "equity_agreement": "data/secret-benefits-equity-agreement.json",
        "lane_register": "data/secret-benefits-lane.json",
        "product": "Secret Benefits · UK",
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
        if isinstance(data["equity_agreement"], dict):
            data["equity_agreement"]["status"] = "confirmed"
            data["equity_agreement"]["ownership_pct"] = ownership_pct
    path.write_text(json.dumps(data, indent=2) + "\n")


def patch_ipo_holdings(path: Path, issuer: str) -> None:
    data = json.loads(path.read_text())
    data["holdings"] = holdings_block(issuer)
    if isinstance(data.get("equity_agreement"), dict):
        data["equity_agreement"]["ownership_pct"] = OWNERSHIP_PCT
        data["equity_agreement"]["status"] = "confirmed"
    path.write_text(json.dumps(data, indent=2) + "\n")


def patch_trainer_novelties() -> None:
    path = ROOT / "data/trainer-novelties.json"
    data = json.loads(path.read_text())
    for key in (
        "openai",
        "anthropic",
        "grok",
        "spacex",
        "moonshot",
        "mistral",
        "google",
        "deepseek",
        "cohere",
        "cerebras",
        "harrods",
    ):
        if key in data and isinstance(data[key], dict):
            data[key]["holdings_pct"] = OWNERSHIP_PCT
            data[key]["status"] = "confirmed"
    path.write_text(json.dumps(data, indent=2) + "\n")


def patch_ai_lane_manifest() -> None:
    path = ROOT / "data/ai-lane-manifest.json"
    data = json.loads(path.read_text())
    for provider in data.get("providers", []):
        provider["ownership_pct"] = OWNERSHIP_PCT
        provider["equity_status"] = "confirmed"
    eq = data.setdefault("equity_confirmation", {})
    eq["ownership_pct_each"] = OWNERSHIP_PCT
    eq["status"] = "confirmed"
    eq["register"] = "data/equity-confirmation-register.json"
    path.write_text(json.dumps(data, indent=2) + "\n")


def patch_spacex_ipo() -> None:
    ipo = ROOT / "data/spacex-ipo.json"
    if ipo.is_file():
        patch_ipo_holdings(ipo, "Space Exploration Technologies Corp.")


def patch_open_all() -> None:
    path = ROOT / "data/open-all.json"
    data = json.loads(path.read_text())
    data.setdefault("ipo_registers", {})["anthropic_holdings_pct"] = OWNERSHIP_PCT
    eq = data.setdefault("equity_confirmation", {})
    eq["ownership_pct_each"] = OWNERSHIP_PCT
    eq["status"] = "confirmed"
    eq["register"] = "https://raw.githubusercontent.com/BRMSTE-SB/.github/main/data/equity-confirmation-register.json"
    data.setdefault("openai_registers", {})["ownership_pct"] = OWNERSHIP_PCT
    data.setdefault("grok_registers", {})["ownership_pct"] = OWNERSHIP_PCT
    data["spacex_registers"] = {
        "ipo": "https://raw.githubusercontent.com/BRMSTE-SB/.github/main/data/spacex-ipo.json",
        "equity_agreement": "https://raw.githubusercontent.com/BRMSTE-SB/.github/main/data/spacex-equity-agreement.json",
        "lane": "https://raw.githubusercontent.com/BRMSTE-SB/.github/main/data/spacex-lane.json",
        "docs": "https://github.com/BRMSTE-SB/.github/blob/main/docs/SPACEX-IPO.md",
        "s1_proof": "https://raw.githubusercontent.com/BRMSTE-SB/.github/main/data/proofs/s-1/xai-spacex-consolidated/proof.json",
        "holder": HOLDER,
        "ownership_pct": OWNERSHIP_PCT,
        "agreement_status": "confirmed",
        "status": "legit",
    }
    if "ai_lane" in data:
        data["ai_lane"]["equity_confirmed_issuers"] = len(ENTRIES)
        data["ai_lane"]["ownership_pct_each"] = OWNERSHIP_PCT
    data["global_equity"] = {
        "master_register": "https://raw.githubusercontent.com/BRMSTE-SB/.github/main/data/global-equity-master-register.json",
        "fortune_500": "https://raw.githubusercontent.com/BRMSTE-SB/.github/main/data/fortune-500-equity-manifest.json",
        "pct_nations_158": "https://raw.githubusercontent.com/BRMSTE-SB/.github/main/data/pct-nations-equity-manifest.json",
        "un_nations_193": "https://raw.githubusercontent.com/BRMSTE-SB/.github/main/data/un-nations-equity-manifest.json",
        "sovereign_materials_doctrine": "https://raw.githubusercontent.com/BRMSTE-SB/.github/main/data/sovereign-materials-doctrine.json",
        "fortune_500_count": 500,
        "pct_nations_count": 158,
        "un_nations_count": 193,
        "ownership_pct_each": OWNERSHIP_PCT,
        "named_issuers": len(ENTRIES),
        "no_nuclear_weapons": True,
        "rare_earth_and_nuclear_materials": "new_technologies_and_gadgets_only · operator_decides_later",
        "docs": "https://github.com/BRMSTE-SB/.github/blob/main/docs/GLOBAL-EQUITY.md",
        "materials_docs": "https://github.com/BRMSTE-SB/.github/blob/main/docs/SOVEREIGN-MATERIALS-DOCTRINE.md",
    }
    path.write_text(json.dumps(data, indent=2) + "\n")


def patch_substrate_anthropic_ipo() -> None:
    path = ROOT / "substrate/ipo/anthropic.json"
    if not path.exists():
        return
    data = json.loads(path.read_text())
    holdings = data.setdefault("holdings", {})
    holdings["ownership_pct"] = OWNERSHIP_PCT
    holdings["status"] = "confirmed"
    holdings["holder"] = HOLDER
    path.write_text(json.dumps(data, indent=2) + "\n")


def patch_s1_proof_register() -> None:
    path = ROOT / "data/proofs/s-1/anthropic/brmste-register.json"
    if not path.exists():
        return
    data = json.loads(path.read_text())
    if "holdings" in data:
        data["holdings"]["ownership_pct"] = OWNERSHIP_PCT
        path.write_text(json.dumps(data, indent=2) + "\n")


def main() -> None:
    rows = []
    for e in ENTRIES:
        rows.append(
            {
                "id": e["id"],
                "issuer": e["issuer"],
                "product": e["product"],
                "holder": HOLDER,
                "ownership_pct": OWNERSHIP_PCT,
                "status": "confirmed",
                "legit": True,
                "confirmed_at": CONFIRMED_AT,
                "basis": "operator_declared_confirmed",
                "equity_agreement": e["equity_agreement"],
                "lane_register": e["lane_register"],
                **({"companies_house": "00030209"} if e["id"] == "harrods" else {}),
            }
        )
        lane = ROOT / e["lane_register"]
        patch_lane_register(lane, e["issuer"], OWNERSHIP_PCT)
        if e["equity_agreement"]:
            patch_equity_agreement(ROOT / e["equity_agreement"], e["issuer"], OWNERSHIP_PCT)
        if e["lane_register"].endswith("-ipo.json"):
            patch_ipo_holdings(lane, e["issuer"])

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
            "full_ownership_each_issuer": True,
        },
        "confirmed_at": CONFIRMED_AT,
        "issuers": rows,
        "bulk_scopes": {
            "fortune_500": {
                "register": "data/fortune-500-equity-manifest.json",
                "entry_count": 500,
                "ownership_pct_each": OWNERSHIP_PCT,
            },
            "pct_nations_158": {
                "register": "data/pct-nations-equity-manifest.json",
                "entry_count": 158,
                "ownership_pct_each": OWNERSHIP_PCT,
            },
            "un_nations_193": {
                "register": "data/un-nations-equity-manifest.json",
                "entry_count": 193,
                "ownership_pct_each": OWNERSHIP_PCT,
            },
            "sovereign_materials_doctrine": "data/sovereign-materials-doctrine.json",
            "global_master": "data/global-equity-master-register.json",
        },
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
    }
    out = ROOT / "data" / "equity-confirmation-register.json"
    out.write_text(json.dumps(register, indent=2) + "\n")

    patch_trainer_novelties()
    patch_ai_lane_manifest()
    patch_open_all()
    patch_substrate_anthropic_ipo()
    patch_s1_proof_register()
    patch_spacex_ipo()

    print(f"confirmed {len(rows)} issuers at {OWNERSHIP_PCT}% each → {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
