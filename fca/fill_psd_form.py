#!/usr/bin/env python3
"""Fill FCA PSD Individual Form docx by injecting values into legacy FORMTEXT fields."""

from __future__ import annotations

import re
import shutil
import zipfile
from pathlib import Path

BLANK = Path(__file__).resolve().parent / "psd-individual-form-blank.docx"
FILLED = Path(__file__).resolve().parent / "psd-individual-form-filled.docx"

REG_OFFICE = "Unit 5 Sherrington Way, Lister Road, Basingstoke, England"
REG_POSTCODE = "RG22 4DQ"
FCA_APPLICATION_ID = "a0wSk00000BgPYLIA3"

# Verified / applicant-supplied KYC (see KYC-FORENSIC-SHRAVAN-BANSAL.md for sources)
PRIVATE_ADDRESS = "Apartment 38, Alberts Court, London, United Kingdom"
PRIVATE_POSTCODE = "NW1 6EL"
PREV_ADDRESS = "Apartment 3, Anne's Court, 3 Palgrave Gardens, London, England"
PREV_POSTCODE = "NW1 6EN"


def inject_form_text_values(xml: str, values: list[str]) -> str:
    """Insert w:t runs after each FORMTEXT field's separate marker."""
    field_pattern = re.compile(
        r'(<w:instrText[^>]*>\s*FORMTEXT\s*</w:instrText>\s*</w:r>'
        r'(?:\s*<w:r[^>]*>\s*<w:rPr>.*?</w:rPr>\s*</w:r>\s*)?'
        r'<w:r[^>]*>\s*<w:rPr>.*?</w:rPr>\s*<w:fldChar w:fldCharType="separate"/></w:r>)',
        re.DOTALL,
    )

    idx = 0

    def replacer(match: re.Match[str]) -> str:
        nonlocal idx
        chunk = match.group(1)
        if idx >= len(values):
            idx += 1
            return chunk
        val = values[idx]
        idx += 1
        if not val:
            return chunk
        safe = (
            val.replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
        )
        return (
            f'{chunk}<w:r><w:rPr><w:rFonts w:ascii="Verdana" w:hAnsi="Verdana"/></w:rPr>'
            f'<w:t xml:space="preserve">{safe}</w:t></w:r>'
        )

    new_xml, count = field_pattern.subn(replacer, xml)
    if count != len(values):
        raise ValueError(f"Injected {count} fields but supplied {len(values)} values")
    return new_xml


def build_complete_values() -> list[str]:
    """Build exactly 160 FORMTEXT values in template order (Release 8 · June 2025)."""
    v: list[str] = []

    def extend(*items: str) -> None:
        v.extend(items)

    # --- Cover (3) ---
    extend(
        "Shravan Bansal",
        "BRMSTE LTD",
        f"Not yet allocated — application in progress (ApplicationId {FCA_APPLICATION_ID})",
    )

    # --- 1 Personal ID ---
    extend("", "", "")  # 1.1a-c IRN — not previously FCA-approved
    extend("Mr", "Bansal", "Shravan", "Shravan Bansal", "Not applicable")
    extend("", "", "", "", "", "", "", "")  # 1.7 name change — N/A
    extend("2", "1", "0", "2", "1", "9", "9", "8")  # 1.9 DOB 21/02/1998
    extend("Hoshiarpur, Punjab, India")  # 1.10 place of birth (applicant supplied)
    extend("REQUIRED — NI number (not in public records)")  # 1.11
    extend("REQUIRED — passport number (not in public records)")  # 1.12
    extend("Indian")  # 1.13 — Companies House nationality
    extend(
        PRIVATE_ADDRESS,
        PRIVATE_POSTCODE,
        "11", "2023", "", "", "", "", "",  # 1.14 from Nov 2023 (CH correspondence)
    )
    # 1.15 previous address 1: Palgrave Gardens Dec 2021 – Oct 2023
    extend(
        PREV_ADDRESS,
        PREV_POSTCODE,
        "12", "21", "10", "23", "", "", "", "",
    )
    extend("", "", "", "", "", "", "", "", "", "")  # 1.15 prev addr 2 — N/A within 3yr UK

    # --- 2 Firm ID (7) ---
    extend(
        "BRMSTE LTD",
        "Not yet allocated",
        "Shravan Bansal",
        "Director / Chairman — PSD Individual",
        "REQUIRED — UK telephone",
        "",
        "sb@brmste.ai",
    )

    # --- 3 Arrangements ---
    extend("Executive Director / Partner — Chairman (tick checkbox in Word)")
    extend("27", "11", "2023", "", "", "", "", "")
    extend("", "", "", "", "", "", "", "")  # 3.4 end date — ongoing
    extend(
        "Chairman and Director of BRMSTE LTD with executive responsibility for payment services: "
        "HSBC Open Banking (PSD2 AISP/PIS pathway), BizStrat payment rails, AML/KYC governance, "
        "safeguarding and wind-down oversight. 75%+ shareholder and PSC (Companies House). "
        "Binding signatory — CH 15310393."
    )

    # --- 4.1 Employment (1) current — BRMSTE LTD ---
    extend(
        "11", "23",
        "", "",
        "Self-employed / Director",
        "BRMSTE LTD",
        f"{REG_OFFICE}, {REG_POSTCODE}",
        "SHRAVAN BANSAL LTD (renamed BRMSTE LTD 16 Mar 2026)",
        "Software development; IT consultancy; holding company (SIC 62012, 62020, 64209)",
        "No",
        "Director / Chairman",
        "Executive management of BRMSTE LTD payment services programme, FCA authorisation, governance.",
        "N/A — current role",
    )

    # --- 4.1 Employment (2) — AD LEADING LIMITED (concurrent, verified CH) ---
    extend(
        "12", "21",
        "", "",
        "Self-employed / Director",
        "AD LEADING LIMITED",
        f"{REG_OFFICE}, {REG_POSTCODE}",
        "",
        "Non-ferrous metal production; hazardous waste (SIC 24450, 24540, 38120, 38220)",
        "No",
        "Director (Secretary 12/2021–11/2023, resigned)",
        "Management of AD Leading Limited; 75%+ shareholder and PSC.",
        "N/A — ongoing directorship",
    )

    # --- 4.1 Employment (3) — pre-2021 (operator must confirm) ---
    extend(
        "", "", "", "",
        "",
        "REQUIRED — employer before Dec 2021 (10-year history)",
        "REQUIRED — employer address",
        "",
        "REQUIRED — nature of business",
        "",
        "REQUIRED — position held",
        "REQUIRED — responsibilities",
        "REQUIRED — reason for leaving",
    )

    # --- 4.2 Qualifications (3 x 5 = 15) ---
    extend(
        "REQUIRED — highest qualification (if any)",
        "REQUIRED — institution",
        "REQUIRED — year",
        "REQUIRED — grade",
        "REQUIRED — subject",
    )
    extend("", "", "", "", "")
    extend("", "", "", "", "")

    # --- 5.15 details field if yes ---
    extend("")

    # --- Section 6 (3 fields) ---
    extend(
        f"6.1 Forensic KYC summary — Applicant: Shravan Bansal. DOB 21/02/1998 (CH: Feb 1998). "
        f"Birth time 18:37 IST — Hoshiarpur, Punjab (applicant supplied). Nationality: Indian. "
        f"Residence: United Kingdom. CH officer ID _AyGZAARKcXony3sLC7B0TqMh8o — identity verified. "
        f"PSC BRMSTE LTD: 75%+ shares/votes; appoint/remove directors. "
        f"Active directorships (CH): BRMSTE LTD, AD LEADING LTD, AD ENGITECH LTD, "
        f"AD REAL ASSET LTD, RE-TYRE FINANCE LTD. Connect ApplicationId {FCA_APPLICATION_ID}. "
        f"Patents GB2607860 · PCT/GB2026/050406. Pre-2021 employment: confirm in Section 4 — "
        f"press articles (CEO Weekly, CelebMix) cite fund-management work from age 18 (unverified). "
        f"Complete NI, passport, telephone, Section 5 checkboxes, signatures before submission.",
        "",
        "0",
    )

    # --- Section 7 declarations ---
    extend(
        "Shravan Bansal",
        "24", "06", "2026", "", "", "", "",
        "BRMSTE LTD",
        "Shravan Bansal",
        "Director / Chairman",
        "24", "06", "2026", "", "", "", "",
    )

    while len(v) < 160:
        v.append("")
    return v[:160]


def main() -> None:
    values = build_complete_values()
    if len(values) != 160:
        raise SystemExit(f"Expected 160 field values, got {len(values)}")

    with zipfile.ZipFile(BLANK, "r") as zin:
        xml = zin.read("word/document.xml").decode("utf-8")
        new_xml = inject_form_text_values(xml, values)

    tmp = FILLED.with_suffix(".tmp.docx")
    with zipfile.ZipFile(BLANK, "r") as zin, zipfile.ZipFile(tmp, "w") as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == "word/document.xml":
                data = new_xml.encode("utf-8")
            zout.writestr(item, data)
    tmp.replace(FILLED)
    print(f"Wrote {FILLED} ({len(values)} fields)")


if __name__ == "__main__":
    main()
