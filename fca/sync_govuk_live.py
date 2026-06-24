#!/usr/bin/env python3
"""Sync BRMSTE LTD live data from GOV.UK Companies House into govuk-live.json.

Uses the official Companies House Public Data API when COMPANIES_HOUSE_API_KEY is set
(register free at https://developer.company-information.service.gov.uk/).

Without an API key, falls back to parsing the public Find and update service HTML
(https://find-and-update.company-information.service.gov.uk/) — same data, GOV.UK hosted.
"""

from __future__ import annotations

import json
import os
import re
import ssl
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

COMPANY_NUMBER = "15310393"
API_BASE = "https://api.company-information.service.gov.uk"
WEB_BASE = "https://find-and-update.company-information.service.gov.uk"
OUT = Path(__file__).resolve().parent / "govuk-live.json"
COMPARE_OUT = Path(__file__).resolve().parents[1] / "compare" / "assets" / "govuk-live.json"

USER_AGENT = "BRMSTE-SB-govuk-sync/1.0 (+https://github.com/BRMSTE-SB)"


def _fetch(url: str, api_key: str | None = None) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "*/*"})
    if api_key:
        import base64

        token = base64.b64encode(f"{api_key}:".encode()).decode()
        req.add_header("Authorization", f"Basic {token}")
    ctx = ssl.create_default_context()
    with urllib.request.urlopen(req, context=ctx, timeout=30) as resp:
        return resp.read().decode("utf-8", errors="replace")


def sync_via_api(api_key: str) -> dict:
    profile = json.loads(_fetch(f"{API_BASE}/company/{COMPANY_NUMBER}", api_key))
    filings = json.loads(
        _fetch(f"{API_BASE}/company/{COMPANY_NUMBER}/filing-history?items_per_page=25", api_key)
    )
    items = []
    for item in filings.get("items", []):
        items.append(
            {
                "date": item.get("date", ""),
                "type": item.get("type", ""),
                "description": item.get("description", ""),
                "category": item.get("category", ""),
                "documentUrl": item.get("links", {}).get("document_metadata"),
            }
        )
    prev_names = profile.get("previous_company_names", [])
    return _build_payload(profile, items, prev_names, source="api")


def _clean_html(text: str) -> str:
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"&#\d+;", "-", text)
    return " ".join(text.split())


def sync_via_html() -> dict:
    overview_html = _fetch(f"{WEB_BASE}/company/{COMPANY_NUMBER}")
    filing_html = _fetch(f"{WEB_BASE}/company/{COMPANY_NUMBER}/filing-history")

    name = _first(r"<h1[^>]*>\s*([^<]+)\s*</h1>", overview_html) or "BRMSTE LTD"
    status = _first(r"Company status\s+(\w+)", overview_html) or "Active"
    reg_office = _first(
        r"Registered office address\s+([^<\n]+?)(?:Company status|$)",
        overview_html,
        re.DOTALL,
    )
    reg_office = " ".join(reg_office.split()) if reg_office else ""
    incorporated = _first(r"Incorporated on\s+(\d{1,2}\s+\w+\s+\d{4})", overview_html) or ""

    sic = re.findall(r"(\d{5})\s*-\s*([^<\n]+)", overview_html)
    prev_names: list[dict[str, str]] = []
    if "SHRAVAN BANSAL LTD" in overview_html:
        prev_names.append(
            {
                "name": "SHRAVAN BANSAL LTD",
                "period": "27 Nov 2023 - 16 Mar 2026",
                "successor": "BRMSTE LTD",
            }
        )

    items = []
    for row in re.finditer(
        r"<td[^>]*>\s*(\d{1,2}\s+\w+\s+\d{4})\s*</td>\s*<td[^>]*>\s*(\w+)\s*</td>\s*<td[^>]*>(.*?)</td>",
        filing_html,
        re.DOTALL,
    ):
        items.append(
            {
                "date": row.group(1).strip(),
                "type": row.group(2).strip(),
                "description": _clean_html(row.group(3)),
                "category": "",
                "documentUrl": f"{WEB_BASE}/company/{COMPANY_NUMBER}/filing-history",
            }
        )

    profile = {
        "company_name": name.strip(),
        "company_number": COMPANY_NUMBER,
        "company_status": status,
        "registered_office_address": reg_office,
        "date_of_creation": incorporated,
        "sic_codes": [{"code": c, "description": d.strip()} for c, d in sic[:5]],
    }
    return _build_payload(profile, items, prev_names, source="html")


def _first(pattern: str, text: str, flags: int = 0) -> str | None:
    m = re.search(pattern, text, flags)
    return m.group(1).strip() if m else None


def _build_payload(profile: dict, filings: list, prev_names: list, source: str) -> dict:
    legacy = []
    if isinstance(prev_names, list):
        for p in prev_names:
            if isinstance(p, dict):
                legacy.append({"name": p.get("name", ""), "period": p.get("period", p.get("ceased_on", ""))})
            else:
                legacy.append({"name": str(p), "period": ""})

    return {
        "schema": "brmste.govuk.live/v1",
        "syncedAt": datetime.now(timezone.utc).isoformat(),
        "source": source,
        "govUkBase": "https://www.gov.uk/government/organisations/companies-house",
        "findAndUpdateBase": WEB_BASE,
        "company": {
            "number": COMPANY_NUMBER,
            "name": profile.get("company_name") or profile.get("name") or "BRMSTE LTD",
            "status": profile.get("company_status") or profile.get("status") or "Active",
            "incorporated": profile.get("date_of_creation") or "27 November 2023",
            "registeredOffice": profile.get("registered_office_address")
            or "Unit 5 Sherrington Way, Lister Road, Basingstoke, England, RG22 4DQ",
            "sicCodes": profile.get("sic_codes") or [],
            "previousNames": legacy,
            "canonicalName": "BRMSTE LTD",
            "renameNote": "All open-lane and substrate features use BRMSTE (formerly SHRAVAN BANSAL LTD until 16 Mar 2026 per CERTNM).",
        },
        "filings": filings,
        "links": {
            "overview": f"{WEB_BASE}/company/{COMPANY_NUMBER}",
            "filingHistory": f"{WEB_BASE}/company/{COMPANY_NUMBER}/filing-history",
            "officers": f"{WEB_BASE}/company/{COMPANY_NUMBER}/officers",
            "psc": f"{WEB_BASE}/company/{COMPANY_NUMBER}/persons-with-significant-control",
            "follow": f"{WEB_BASE}/company/{COMPANY_NUMBER}/follow",
        },
        "openFeatures": {
            "lane": "BRMSTE Open",
            "legacyLaneNames": ["Human Open", "human_open", "open-gits", "EPIC"],
            "catalogPath": "/substrate/brmste/open-gits.json",
            "legacyCatalogPath": "/substrate/human/open-gits.json",
        },
    }


def main() -> None:
    api_key = os.environ.get("COMPANIES_HOUSE_API_KEY", "").strip() or None
    payload = sync_via_api(api_key) if api_key else sync_via_html()

    OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    COMPARE_OUT.parent.mkdir(parents=True, exist_ok=True)
    COMPARE_OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(payload['filings'])} filings, source={payload['source']})")
    print(f"Wrote {COMPARE_OUT}")


if __name__ == "__main__":
    main()
