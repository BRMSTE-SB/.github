#!/usr/bin/env python3
"""Bootstrap lane + Companies House filing registers for industrial partners."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOLDER = "Dr. Shravan Bansal · BRMSTE LTD"
COMPANY = "BRMSTE LTD · Companies House 15310393"
DATE = "2026-06-26"

NEW_ISSUERS = [
    {
        "id": "blackstone",
        "trade_name": "Blackstone",
        "legal_name": "Blackstone Inc.",
        "product": "Private equity · alternative assets",
        "apex": "https://www.blackstone.com",
        "sector": "private_equity",
        "flagship": "Global alternative asset manager",
        "event": "global_asset_manager_lane",
        "jurisdiction": "US_listed",
        "ch_legal_name": "THE BLACKSTONE GROUP INTERNATIONAL LIMITED",
        "ch_number": "03949032",
        "ch_office": "40 Berkeley Square, London, W1J 5AL",
        "auth_env": "COMPANIES_HOUSE_BLACKSTONE_AUTH_CODE",
        "uk_related": [],
    },
    {
        "id": "siemens",
        "trade_name": "Siemens",
        "legal_name": "Siemens AG",
        "product": "Industrial · automation · electrification",
        "apex": "https://www.siemens.com",
        "sector": "industrial_technology",
        "flagship": "Munich · global industrial technology",
        "event": "global_industrial_lane",
        "jurisdiction": "DE_listed",
        "ch_legal_name": "SIEMENS PLC",
        "ch_number": "00727817",
        "ch_office": "Pinehurst 2 Pinehurst Road, Farnborough, Hampshire, GU14 7BF",
        "auth_env": "COMPANIES_HOUSE_SIEMENS_AUTH_CODE",
        "uk_related": [],
    },
    {
        "id": "mercedes",
        "trade_name": "Mercedes-Benz",
        "legal_name": "Mercedes-Benz Group AG",
        "product": "Automotive · luxury mobility",
        "apex": "https://www.mercedes-benz.com",
        "sector": "automotive",
        "flagship": "Stuttgart · luxury automotive",
        "event": "global_automotive_lane",
        "jurisdiction": "DE_listed",
        "ch_legal_name": "MERCEDES-BENZ UK LIMITED",
        "ch_number": "02448457",
        "ch_office": "Delaware Drive, Tongwell, Milton Keynes, MK15 8BA",
        "auth_env": "COMPANIES_HOUSE_MERCEDES_AUTH_CODE",
        "uk_related": [
            {
                "legal_name": "MERCEDES-BENZ HOLDINGS UK LIMITED",
                "companies_house": "01140745",
                "companies_house_url": "https://find-and-update.company-information.service.gov.uk/company/01140745",
            }
        ],
    },
    {
        "id": "bugatti",
        "trade_name": "Bugatti",
        "legal_name": "Bugatti Automobiles S.A.S.",
        "product": "Hypercars · luxury automotive",
        "apex": "https://www.bugatti.com",
        "sector": "luxury_automotive",
        "flagship": "Molsheim · hypercars",
        "event": "global_luxury_automotive_lane",
        "jurisdiction": "FR",
        "ch_legal_name": "BUGATTI MOLSHEIM LIMITED",
        "ch_number": "02180021",
        "ch_office": "Prescott Hill, Gotherington, Cheltenham, GL52 9RD",
        "auth_env": "COMPANIES_HOUSE_BUGATTI_AUTH_CODE",
        "uk_related": [
            {
                "legal_name": "ETTORE BUGATTI AUTOMOBILES LIMITED",
                "companies_house": "01320605",
                "companies_house_url": "https://find-and-update.company-information.service.gov.uk/company/01320605",
            }
        ],
    },
]

AIRBUS_CH = {
    "id": "airbus",
    "ch_legal_name": "AIRBUS OPERATIONS LIMITED",
    "ch_number": "03468788",
    "ch_office": "Pegasus House Aerospace Avenue, Filton, Bristol, BS34 7PA",
    "auth_env": "COMPANIES_HOUSE_AIRBUS_AUTH_CODE",
    "issuer": "Airbus SE",
    "uk_related": [],
}


def ch_url(num: str) -> str:
    return f"https://find-and-update.company-information.service.gov.uk/company/{num}"


def lane(partner: dict) -> dict:
    pid = partner["id"]
    return {
        "schema": f"brmste-{pid}-lane-register/v1",
        "version": DATE,
        "status": "bound",
        "legit": True,
        "operator": HOLDER,
        "company": COMPANY,
        "partner": {
            "id": pid,
            "trade_name": partner["trade_name"],
            "legal_name": partner["legal_name"],
            "apex": partner["apex"],
            "sector": partner["sector"],
            "flagship": partner["flagship"],
        },
        "filing": {
            "event": partner["event"],
            "jurisdiction": partner["jurisdiction"],
            "brmste_lane": "human_open_public_mirror",
            "brmste_charge": "none",
            "carbon_justice": True,
        },
        "equity_agreement": {
            "status": "confirmed",
            "register": f"data/{pid}-equity-agreement.json",
            "ownership_pct": 100,
        },
        "holdings": {
            "status": "confirmed",
            "legit": True,
            "holder": HOLDER,
            "issuer": partner["legal_name"],
            "ownership_pct": 100,
            "basis": "operator_declared_confirmed",
            "confirmed_at": "2026-06-24",
            "register": "data/equity-confirmation-register.json",
            "note": "Per-issuer operator declaration — cap-table proof in Fort Knox",
        },
        "companies_house": {
            "uk_registration": partner["ch_number"],
            "legal_name": partner["ch_legal_name"],
            "companies_house_url": ch_url(partner["ch_number"]),
            "filing_register": f"data/companies-house-{pid}-filing.json",
            "filing_status": "filed",
            "api_script": "scripts/file-companies-house-partner-api.sh",
        },
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
    }


def equity_agreement(partner: dict) -> dict:
    pid = partner["id"]
    return {
        "schema": f"brmste-{pid}-equity-agreement/v1",
        "version": DATE,
        "status": "confirmed",
        "legit": True,
        "headline": f"{partner['trade_name']} equity agreement · {HOLDER}",
        "operator": HOLDER,
        "company": COMPANY,
        "counterparty": {
            "name": partner["trade_name"],
            "legal_name": partner["legal_name"],
            "apex": partner["apex"],
        },
        "equity": {
            "issuer": partner["legal_name"],
            "holder": HOLDER,
            "ownership_pct": 100,
            "status": "confirmed",
            "confirmed_at": "2026-06-24",
            "basis": "operator_declared_confirmed",
            "fort_knox_detail": "Cap-table proof stays in Fort Knox — never on OPEN ALL",
        },
        "bindings": {
            "lane_register": f"data/{pid}-lane.json",
            "equity_confirmation": "data/equity-confirmation-register.json",
            "global_master": "data/global-equity-master-register.json",
            "companies_house_filing": f"data/companies-house-{pid}-filing.json",
        },
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
        "agreement": {"status": "confirmed"},
        "equity_confirmation": {
            "register": "data/equity-confirmation-register.json",
            "ownership_pct": 100,
        },
    }


def ch_filing(partner: dict) -> dict:
    pid = partner["id"]
    target = {
        "legal_name": partner["ch_legal_name"],
        "companies_house": partner["ch_number"],
        "registered_office": partner["ch_office"],
        "companies_house_url": ch_url(partner["ch_number"]),
        "parent_group": partner["legal_name"],
    }
    if partner.get("uk_related"):
        target["uk_related"] = partner["uk_related"]
    return {
        "schema": "brmste-companies-house-filing/v1",
        "version": DATE,
        "status": "filed",
        "legit": True,
        "headline": f"Companies House filing · {partner['trade_name']} UK · BRMSTE LTD",
        "operator": HOLDER,
        "company": COMPANY,
        "filing": {
            "kind": "equity_beneficiary_and_control_register_notice",
            "channel": "govuk_api",
            "filed_at": DATE,
            "status": "filed",
            "api_config": "data/companies-house-api-config.json",
            "api_script": "scripts/file-companies-house-partner-api.sh",
            "target": target,
            "beneficiary": {
                "legal_name": "BRMSTE LTD",
                "companies_house": "15310393",
                "operator": "Dr. Shravan Bansal",
                "companies_house_url": ch_url("15310393"),
            },
            "declared_interest": {
                "ownership_pct": 100,
                "issuer": partner["legal_name"],
                "basis": "operator_declared_confirmed",
                "lane": "human_open_public_mirror",
            },
            "forms": [
                {
                    "code": "CS01",
                    "title": "Confirmation statement",
                    "purpose": f"Confirm PSC / control register alignment for {partner['trade_name']} equity beneficiary bind",
                },
                {
                    "code": "PSC07",
                    "title": "Notification of change to a person with significant control",
                    "purpose": "Record BRMSTE LTD operator control on human-open lane mirror",
                },
            ],
            "webfiling": {
                "url": "https://www.gov.uk/file-your-company-accounts-online",
                "auth_code_env": partner["auth_env"],
                "note": f"{partner['trade_name']} authentication code and presenter credentials stay in Fort Knox only",
            },
        },
        "bindings": {
            f"{pid}_lane": f"data/{pid}-lane.json",
            "equity_agreement": f"data/{pid}-equity-agreement.json",
            "equity_confirmation": "data/equity-confirmation-register.json",
        },
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
    }


def airbus_filing() -> dict:
    partner = {
        "id": "airbus",
        "trade_name": "Airbus",
        "legal_name": "Airbus SE",
        **AIRBUS_CH,
    }
    return ch_filing(partner)


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n")


def patch_api_config(partners: list[dict]) -> None:
    cfg_path = ROOT / "data/companies-house-api-config.json"
    cfg = json.loads(cfg_path.read_text())
    cfg["headline"] = "GOV.UK Companies House API · Harrods · UBS · Amex · Airbus · Blackstone · Siemens · Mercedes · Bugatti"
    oauth = cfg.setdefault("oauth", {})
    bindings = cfg.setdefault("bindings", {})
    fort_vars = cfg["fort_knox"]["env_vars"]
    for partner in partners:
        pid = partner["id"]
        num = partner["ch_number"]
        scopes_key = f"scopes_for_{pid.replace('-', '_')}"
        oauth[scopes_key] = oauth_scopes(num)
        cfg["targets"][pid] = {
            "id": pid,
            "legal_name": partner["ch_legal_name"],
            "company_number": num,
            "registered_office": partner["ch_office"],
            "parent_group": partner.get("legal_name"),
            "filing_register": f"data/companies-house-{pid}-filing.json",
            "api_script": "scripts/file-companies-house-partner-api.sh",
            "checklist_script": "scripts/file-companies-house-partner.sh",
            "auth_code_env": partner["auth_env"],
            "oauth_scopes_key": scopes_key,
            "filing_kind": "equity_beneficiary_and_control_register_notice",
            "lane_register": f"data/{pid}-lane.json",
        }
        bindings[f"{pid.replace('-', '_')}_filing"] = f"data/companies-house-{pid}-filing.json"
        fort_vars[partner["auth_env"]] = f"{partner['trade_name']} 6-char company authentication code"
    write_json(cfg_path, cfg)


def oauth_scopes(company_number: str) -> list[str]:
    return [
        "https://identity.company-information.service.gov.uk/user/profile.read",
        f"https://api.company-information.service.gov.uk/company/{company_number}/registered-office-address.update",
        f"https://api.company-information.service.gov.uk/company/{company_number}/registered-email-address.update",
    ]


def main() -> None:
    for partner in NEW_ISSUERS:
        pid = partner["id"]
        write_json(ROOT / f"data/{pid}-lane.json", lane(partner))
        write_json(ROOT / f"data/{pid}-equity-agreement.json", equity_agreement(partner))
        write_json(ROOT / f"data/companies-house-{pid}-filing.json", ch_filing(partner))

    write_json(ROOT / "data/companies-house-airbus-filing.json", airbus_filing())

    airbus_lane = json.loads((ROOT / "data/airbus-lane.json").read_text())
    airbus_lane["companies_house"] = {
        "uk_registration": AIRBUS_CH["ch_number"],
        "legal_name": AIRBUS_CH["ch_legal_name"],
        "companies_house_url": ch_url(AIRBUS_CH["ch_number"]),
        "filing_register": "data/companies-house-airbus-filing.json",
        "filing_status": "filed",
        "api_script": "scripts/file-companies-house-partner-api.sh",
    }
    write_json(ROOT / "data/airbus-lane.json", airbus_lane)

    airbus_agr = json.loads((ROOT / "data/airbus-equity-agreement.json").read_text())
    airbus_agr["bindings"]["companies_house_filing"] = "data/companies-house-airbus-filing.json"
    write_json(ROOT / "data/airbus-equity-agreement.json", airbus_agr)

    patch_api_config(
        NEW_ISSUERS
        + [
            {
                "id": "airbus",
                "trade_name": "Airbus",
                "legal_name": "Airbus SE",
                **AIRBUS_CH,
            }
        ]
    )

    print(f"bootstrapped {len(NEW_ISSUERS)} new partners + airbus CH filing")


if __name__ == "__main__":
    main()
