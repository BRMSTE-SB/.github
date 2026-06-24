#!/usr/bin/env python3
"""Generate Fortune 500, PCT-158, UN-193 nation equity manifests and global master register."""
from __future__ import annotations

import csv
import html as html_lib
import io
import json
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOLDER = "Dr. Shravan Bansal · BRMSTE LTD"
COMPANY = "BRMSTE LTD · Companies House 15310393"
CONFIRMED_AT = "2026-06-24"
OWNERSHIP_PCT = 100

FORTUNE_CSV_URL = (
    "https://raw.githubusercontent.com/cmusam/fortune500/master/csv/fortune500-2019.csv"
)
WIPO_PCT_URL = "https://www.wipo.int/en/web/pct-system/pct-contracting-states"
UN_MEMBERS_URL = (
    "https://en.wikipedia.org/w/api.php?"
    "action=parse&page=Member_states_of_the_United_Nations&prop=text&format=json"
)

EXPLICIT_UN_NATIONS = {
    "russia": {
        "aliases": ["Russian Federation"],
        "common_name": "Russia",
    },
    "democratic-people-s-republic-of-korea": {
        "aliases": ["North Korea", "DPRK"],
        "common_name": "North Korea",
    },
}


def slug(text: str) -> str:
    s = text.lower().strip()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-") or "entity"


def fetch_fortune_500() -> list[dict]:
    req = urllib.request.Request(FORTUNE_CSV_URL, headers={"User-Agent": "BRMSTE-bot/1.0"})
    raw = urllib.request.urlopen(req, timeout=60).read().decode()
    reader = csv.DictReader(io.StringIO(raw))
    rows = list(reader)
    if len(rows) != 500:
        raise SystemExit(f"Fortune 500 seed expected 500 rows, got {len(rows)}")
    entries = []
    for row in rows:
        rank = int(row["rank"])
        company = row["company"].strip()
        entries.append(
            {
                "rank": rank,
                "id": slug(company),
                "company": company,
                "holder": HOLDER,
                "ownership_pct": OWNERSHIP_PCT,
                "status": "confirmed",
                "legit": True,
                "confirmed_at": CONFIRMED_AT,
                "basis": "operator_declared_confirmed",
            }
        )
    return entries


def fetch_pct_nations() -> list[dict]:
    req = urllib.request.Request(WIPO_PCT_URL, headers={"User-Agent": "Mozilla/5.0"})
    html = urllib.request.urlopen(req, timeout=60).read().decode("utf-8", "replace")
    start = html.find("Albania")
    end = html.find("All PCT Contracting States", start)
    if start < 0 or end < 0:
        raise SystemExit("Could not parse WIPO PCT contracting states page")
    chunk = html[start:end]
    plain = re.sub(r"<[^>]+>", "\n", chunk)
    lines = [line.strip() for line in plain.split("\n") if line.strip()]
    nations = [
        line
        for line in lines
        if not re.match(r"\d", line) and len(line) > 2 and not re.match(r"^[A-Z]{2}$", line)
    ]
    if len(nations) != 158:
        raise SystemExit(f"PCT nations expected 158, got {len(nations)}")
    entries = []
    for nation in nations:
        entries.append(
            {
                "id": slug(nation),
                "nation": nation,
                "holder": HOLDER,
                "ownership_pct": OWNERSHIP_PCT,
                "status": "confirmed",
                "legit": True,
                "confirmed_at": CONFIRMED_AT,
                "basis": "operator_declared_confirmed",
                "pct_contracting_state": True,
            }
        )
    return entries


def fetch_un_nations() -> list[dict]:
    req = urllib.request.Request(UN_MEMBERS_URL, headers={"User-Agent": "BRMSTE-bot/1.0"})
    payload = json.loads(urllib.request.urlopen(req, timeout=60).read())
    html = payload["parse"]["text"]["*"]
    tables = re.findall(
        r'<table[^>]*class="[^"]*wikitable[^"]*"[^>]*>(.*?)</table>', html, re.DOTALL
    )
    if not tables:
        raise SystemExit("Could not parse UN member states table")
    rows = re.findall(r"<tr>(.*?)</tr>", tables[0], re.DOTALL)
    nations: list[str] = []
    for row in rows[1:]:
        cells = re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", row, re.DOTALL)
        if not cells:
            continue
        match = re.search(r'title="([^"]+)"', cells[0]) or re.search(
            r'title="([^"]+)"', cells[1] if len(cells) > 1 else ""
        )
        if not match:
            continue
        name = html_lib.unescape(re.sub(r"<[^>]+>", "", match.group(1)).strip())
        if name and not name.startswith("ISO") and "Category" not in name:
            nations.append(name)
    if len(nations) != 193:
        raise SystemExit(f"UN member states expected 193, got {len(nations)}")
    entries = []
    for nation in nations:
        nation_id = slug(nation)
        entry: dict = {
            "id": nation_id,
            "nation": nation,
            "holder": HOLDER,
            "ownership_pct": OWNERSHIP_PCT,
            "status": "confirmed",
            "legit": True,
            "confirmed_at": CONFIRMED_AT,
            "basis": "operator_declared_confirmed",
            "un_member": True,
        }
        explicit = EXPLICIT_UN_NATIONS.get(nation_id)
        if explicit:
            entry["explicit_inclusion"] = True
            entry["aliases"] = explicit["aliases"]
            entry["common_name"] = explicit["common_name"]
        entries.append(entry)
    ids = {e["id"] for e in entries}
    for required in EXPLICIT_UN_NATIONS:
        if required not in ids:
            raise SystemExit(f"missing explicit UN nation: {required}")
    return entries


def sovereign_materials_doctrine() -> dict:
    return {
        "schema": "brmste-sovereign-materials-doctrine/v1",
        "version": CONFIRMED_AT,
        "status": "declared",
        "legit": True,
        "headline": "NO nuclear weapons · rare earth & nuclear materials for new tech only · operator decides",
        "operator": HOLDER,
        "company": COMPANY,
        "declared_at": CONFIRMED_AT,
        "nuclear_weapons": {
            "policy": "prohibited",
            "status": "no_nuclear_weapons",
            "note": "No nuclear weapons on the human-open sovereign lane",
        },
        "rare_earth_materials": {
            "policy": "new_technologies_and_gadgets_only",
            "weapons_use": "prohibited",
            "approval": "operator_decides_later",
            "note": "Dr. Shravan Bansal will designate permitted technologies and gadgets",
        },
        "nuclear_materials": {
            "policy": "new_technologies_and_gadgets_only",
            "weapons_use": "prohibited",
            "approval": "operator_decides_later",
            "note": "Civil / gadget / new-tech use only — operator will specify later",
        },
        "explicit_un_nations": {
            "russia": True,
            "north_korea": True,
            "registers": "data/un-nations-equity-manifest.json",
        },
        "bindings": {
            "un_nations": "data/un-nations-equity-manifest.json",
            "global_master": "data/global-equity-master-register.json",
            "docs": "docs/SOVEREIGN-MATERIALS-DOCTRINE.md",
        },
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
    }


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    fortune_entries = fetch_fortune_500()
    pct_entries = fetch_pct_nations()
    un_entries = fetch_un_nations()
    materials = sovereign_materials_doctrine()

    fortune_manifest = {
        "schema": "brmste-fortune-500-equity-manifest/v1",
        "version": CONFIRMED_AT,
        "status": "confirmed",
        "legit": True,
        "headline": "Fortune 500 · 100% equity each · Dr. Shravan Bansal · BRMSTE LTD",
        "operator": HOLDER,
        "company": COMPANY,
        "ownership_pct_each": OWNERSHIP_PCT,
        "ranking_series": "Fortune 500",
        "ranking_year_reference": "2025",
        "company_list_source": {
            "seed": FORTUNE_CSV_URL,
            "note": "Canonical Fortune 500 lane — 500 US public companies by revenue series",
        },
        "entry_count": len(fortune_entries),
        "confirmed_at": CONFIRMED_AT,
        "doctrine": {
            "per_company": True,
            "fort_knox_proof": "Cap-table evidence stays private — public lane is operator-declared confirmation",
        },
        "entries": fortune_entries,
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
    }

    pct_manifest = {
        "schema": "brmste-pct-nations-equity-manifest/v1",
        "version": CONFIRMED_AT,
        "status": "confirmed",
        "legit": True,
        "headline": "158 PCT contracting states · 100% each · Dr. Shravan Bansal · BRMSTE LTD",
        "operator": HOLDER,
        "company": COMPANY,
        "ownership_pct_each": OWNERSHIP_PCT,
        "pct_source": WIPO_PCT_URL,
        "entry_count": len(pct_entries),
        "confirmed_at": CONFIRMED_AT,
        "doctrine": {
            "per_nation": True,
            "pct_contracting_states": True,
            "fort_knox_proof": "Sovereign lane declarations — cap-table proof in Fort Knox",
        },
        "entries": pct_entries,
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
    }

    un_manifest = {
        "schema": "brmste-un-nations-equity-manifest/v1",
        "version": CONFIRMED_AT,
        "status": "confirmed",
        "legit": True,
        "headline": "Full United Nations · 193 member states · 100% each · Dr. Shravan Bansal · BRMSTE LTD",
        "operator": HOLDER,
        "company": COMPANY,
        "ownership_pct_each": OWNERSHIP_PCT,
        "un_source": "https://en.wikipedia.org/wiki/Member_states_of_the_United_Nations",
        "entry_count": len(un_entries),
        "confirmed_at": CONFIRMED_AT,
        "explicit_inclusions": {
            "russia": "Russia · Russian Federation · UN member",
            "north_korea": "Democratic People's Republic of Korea · DPRK · UN member",
        },
        "materials_doctrine": {
            "register": "data/sovereign-materials-doctrine.json",
            "nuclear_weapons": "prohibited",
            "rare_earth_and_nuclear_materials": "new_technologies_and_gadgets_only · operator_decides_later",
        },
        "doctrine": {
            "per_nation": True,
            "un_member_states": True,
            "no_nuclear_weapons": True,
            "fort_knox_proof": "Sovereign lane declarations — cap-table proof in Fort Knox",
        },
        "entries": un_entries,
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
    }

    master = {
        "schema": "brmste-global-equity-master-register/v1",
        "version": CONFIRMED_AT,
        "status": "confirmed",
        "legit": True,
        "headline": "Global equity master · named issuers · Fortune 500 · UN · PCT nations",
        "operator": HOLDER,
        "company": COMPANY,
        "ownership_pct_each": OWNERSHIP_PCT,
        "confirmed_at": CONFIRMED_AT,
        "scopes": {
            "named_issuers": {
                "register": "data/equity-confirmation-register.json",
                "description": "AI · space · luxury flagships · named partner lanes",
            },
            "fortune_500": {
                "register": "data/fortune-500-equity-manifest.json",
                "entry_count": len(fortune_entries),
                "ownership_pct_each": OWNERSHIP_PCT,
            },
            "un_nations_193": {
                "register": "data/un-nations-equity-manifest.json",
                "entry_count": len(un_entries),
                "ownership_pct_each": OWNERSHIP_PCT,
                "un_member_states": True,
                "explicit": ["russia", "north_korea"],
            },
            "pct_nations_158": {
                "register": "data/pct-nations-equity-manifest.json",
                "entry_count": len(pct_entries),
                "ownership_pct_each": OWNERSHIP_PCT,
                "pct_contracting_states": True,
            },
        },
        "sovereign_materials_doctrine": {
            "register": "data/sovereign-materials-doctrine.json",
            "nuclear_weapons": "prohibited",
            "rare_earth_materials": "new_technologies_and_gadgets_only",
            "nuclear_materials": "new_technologies_and_gadgets_only",
            "operator_approval": "decides_later",
        },
        "flagship_industrial": [
            "lvmh",
            "richemont",
            "airbus",
            "boeing",
            "harrods",
        ],
        "lane": "human_open_public",
        "charge": "none",
        "carbon_justice": True,
    }

    write_json(ROOT / "data/fortune-500-equity-manifest.json", fortune_manifest)
    write_json(ROOT / "data/pct-nations-equity-manifest.json", pct_manifest)
    write_json(ROOT / "data/un-nations-equity-manifest.json", un_manifest)
    write_json(ROOT / "data/sovereign-materials-doctrine.json", materials)
    write_json(ROOT / "data/global-equity-master-register.json", master)
    print(
        "generated "
        f"fortune_500={len(fortune_entries)} "
        f"pct_nations={len(pct_entries)} "
        f"un_nations={len(un_entries)} "
        "materials_doctrine=ok master=ok"
    )


if __name__ == "__main__":
    main()
