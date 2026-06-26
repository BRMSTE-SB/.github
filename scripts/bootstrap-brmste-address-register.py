#!/usr/bin/env python3
"""Bootstrap BRMSTE LTD Companies House address register bindings."""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTER = ROOT / "data" / "brmste-ltd-companies-house-register.json"
CONFIG = ROOT / "data" / "companies-house-api-config.json"
OPERATOR = ROOT / "data" / "operator-profile.json"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--psc-filed", action="store_true", help="Mark PSC04 correspondence as filed")
    args = parser.parse_args()

    reg = json.loads(REGISTER.read_text())
    cfg = json.loads(CONFIG.read_text())
    prof = json.loads(OPERATOR.read_text())

    if "brmste" not in cfg.get("targets", {}):
        raise SystemExit("companies-house-api-config missing targets.brmste")

    prof["companies_house_address"] = {
        "status": reg.get("status"),
        "register": "data/brmste-ltd-companies-house-register.json",
        "canonical_display": reg["canonical_address"]["display"],
        "docs": "docs/BRMSTE-COMPANIES-HOUSE-ADDRESS.md",
        "api_script": "scripts/file-companies-house-brmste-api.sh",
    }
    OPERATOR.write_text(json.dumps(prof, indent=2) + "\n")

    if args.psc_filed:
        now = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        reg["status"] = "address_sync_complete"
        reg["psc"]["correspondence_address"]["status"] = "filed"
        reg["filing"]["psc_correspondence"]["status"] = "filed"
        reg["filing"]["psc_correspondence"]["filed_at"] = now
        REGISTER.write_text(json.dumps(reg, indent=2) + "\n")
        print(f"psc_correspondence=filed at={now}")
    else:
        print(f"operator_profile=patched status={reg.get('status')}")


if __name__ == "__main__":
    main()
