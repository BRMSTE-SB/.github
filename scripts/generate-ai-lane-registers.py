#!/usr/bin/env python3
"""Generate AI lane equity, lane, declaration, and substrate files from ai-lane-manifest.json."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "data" / "ai-lane-manifest.json"

SKIP_IDS = {"openai", "grok"}  # already have full registers


def equity_agreement(p: dict) -> dict:
    return {
        "schema": f"brmste-{p['id']}-equity-agreement/v1",
        "version": "2026-06-24",
        "status": "agreed",
        "legit": True,
        "headline": f"{p['name']} equity agreement · Dr. Shravan Bansal · BRMSTE LTD",
        "operator": "Dr. Shravan Bansal · BRMSTE LTD",
        "company": "BRMSTE LTD · Companies House 15310393",
        "counterparty": {
            "name": p["name"],
            "product": p["product"],
            "apex": p["apex"],
        },
        "equity": {
            "holder": "Dr. Shravan Bansal · BRMSTE LTD",
            "status": "agreed",
            "check_lane": "operator_agreement_filed",
            "fort_knox_detail": "API credentials stay in Fort Knox — never on OPEN ALL",
        },
        "agreement": {
            "kind": "equity_and_api_lane",
            "status": "agreed",
            "filed_at": "2026-06-24",
            "declarer": "Dr. Shravan Bansal · BRMSTE LTD",
            "terms": [
                f"{p['name']} IPO lane preparation on human-open lane",
                f"{p['product']} go live on human-open lane",
                "No BRMSTE charges · carbon justice only",
                "API credentials never committed to public repos",
            ],
            "credentials_policy": {
                "storage": "fort_knox_only",
                "env_var": p["env_var"],
                "mac_key_file": p["mac_key_file"],
                "never_commit": True,
                "open_lane": "no_secrets",
            },
        },
        "bindings": {
            "lane_register": p["lane_register"],
            "declaration": p["declaration"],
        },
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
    }


def lane_register(p: dict) -> dict:
    return {
        "schema": "brmste-ai-lane-register/v1",
        "version": "2026-06-24",
        "status": "ipo_lane_preparation",
        "legit": True,
        "operator": "Dr. Shravan Bansal · BRMSTE LTD",
        "company": "BRMSTE LTD · Companies House 15310393",
        "provider": {
            "id": p["id"],
            "name": p["name"],
            "product": p["product"],
            "apex": p["apex"],
        },
        "filing": {
            "event": "ipo_lane_preparation",
            "form": None,
            "filed_at": None,
            "filed_at_precision": "not_publicly_reported",
            "jurisdiction": "US_SEC",
            "brmste_lane": "human_open_public_mirror",
            "brmste_charge": "none",
            "carbon_justice": True,
        },
        "go_live": {
            "status": p["status"],
            "model_id": p["model_id"],
            "declaration": p["declaration"],
        },
        "equity_agreement": {
            "status": "agreed",
            "register": p["equity_agreement"],
        },
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
    }


def declaration(p: dict) -> dict:
    headline = f"DECLARE BRMSTE {p['name'].upper()} AND GO LIVE"
    if p["id"] == "moonshot":
        headline = "DECLARE BRMSTE MOONSHOT KIMI 2.6 AND GO LIVE"
    return {
        "schema": f"brmste-{p['id']}-declaration/v1",
        "version": "2026-06-24",
        "status": p["status"],
        "legit": True,
        "headline": headline,
        "operator": "Dr. Shravan Bansal · BRMSTE LTD",
        "operator_title": "Dr.",
        "company": "BRMSTE LTD · Companies House 15310393",
        "declaration": {
            "declared_at": "2026-06-24",
            "live_at": "2026-06-24",
            "declarer": "Dr. Shravan Bansal · BRMSTE LTD",
            "subjects": [
                {
                    "kind": "entity",
                    "name": "BRMSTE",
                    "legal_name": "BRMSTE LTD",
                    "companies_house": "15310393",
                },
                {
                    "kind": "partner",
                    "name": p["name"],
                    "product": p["product"],
                    "url": p["apex"],
                },
                {
                    "kind": "model",
                    "provider": p["name"],
                    "model_id": p["model_id"],
                    "status": p["status"],
                },
                {
                    "kind": "agreement",
                    "status": "agreed",
                    "register": p["equity_agreement"],
                },
            ],
            "statement": f"Dr. Shravan Bansal · BRMSTE LTD declares {p['name']} · {p['product']} go live — legit · carbon justice · no BRMSTE charges.",
            "lane": "human_open_public",
            "charge": "none",
            "carbon_justice": True,
        },
        "bindings": {
            "lane_register": p["lane_register"],
            "equity_agreement": p["equity_agreement"],
            "ai_lane_manifest": "data/ai-lane-manifest.json",
        },
        "mirrors": {"substrate": p["substrate"]},
        "sign_lines": "CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS",
    }


def substrate(p: dict) -> dict:
    return {
        "schema": "brmste-substrate-ai-lane/v1",
        "version": "2026-06-24",
        "bind": p["substrate"],
        "status": p["status"],
        "legit": True,
        "provider": p["name"],
        "product": p["product"],
        "model_id": p["model_id"],
        "operator": "Dr. Shravan Bansal · BRMSTE LTD · Companies House 15310393",
        "declaration_ref": p["declaration"],
    }


def main() -> None:
    manifest = json.loads(MANIFEST.read_text())
    (ROOT / "substrate" / "ai").mkdir(parents=True, exist_ok=True)
    for p in manifest["providers"]:
        if p["id"] in SKIP_IDS:
            continue
        for path, obj in [
            (ROOT / p["equity_agreement"], equity_agreement(p)),
            (ROOT / p["lane_register"], lane_register(p)),
            (ROOT / p["declaration"], declaration(p)),
            (ROOT / p["substrate"], substrate(p)),
        ]:
            path.write_text(json.dumps(obj, indent=2) + "\n")
            print("wrote", path.relative_to(ROOT))


if __name__ == "__main__":
    main()
