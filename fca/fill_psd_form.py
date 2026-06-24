#!/usr/bin/env python3
"""Fill FCA PSD Individual Form docx by injecting values into legacy FORMTEXT fields."""

from __future__ import annotations

import re
import shutil
import zipfile
from pathlib import Path

BLANK = Path(__file__).resolve().parent / "psd-individual-form-blank.docx"
FILLED = Path(__file__).resolve().parent / "psd-individual-form-filled.docx"

# Registered office (Companies House 15310393, verified 24 Jun 2026)
REG_OFFICE = "Unit 5 Sherrington Way, Lister Road, Basingstoke, England"
REG_POSTCODE = "RG22 4DQ"
FCA_APPLICATION_ID = "a0wSk00000BgPYLIA3"


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
    extend("", "", "")  # 1.1a-c IRN
    extend("Mr", "Bansal", "Shravan", "Shravan Bansal", "Not applicable")  # 1.2-1.6
    extend("", "", "", "", "", "", "", "")  # 1.7 name change date boxes
    extend("DD", "D", "D", "M", "M", "Y", "Y", "Y")  # 1.9 DOB placeholders
    extend("REQUIRED — place of birth")  # 1.10
    extend("REQUIRED — NI number if available")  # 1.11
    extend("REQUIRED — passport if available")  # 1.12
    extend("British (confirm; disclose all nationalities in Section 6 if more than one)")  # 1.13
    extend(
        "REQUIRED — private residential address",
        "REQUIRED — postcode",
        "MM", "YYYY", "", "", "", "", "",
    )
    extend("", "", "", "", "", "", "", "", "", "")  # 1.15 prev addr 1
    extend("", "", "", "", "", "", "", "", "", "")  # 1.15 prev addr 2

    # --- 2 Firm ID (7) ---
    extend(
        "BRMSTE LTD",
        "Not yet allocated",
        "Shravan Bansal",
        "Director / Chairman — PSD Individual",
        "REQUIRED — telephone",
        "",
        "sb@brmste.ai",
    )

    # --- 3 Arrangements ---
    extend("Executive Director / Partner — Chairman (tick checkbox in Word)")
    extend("27", "11", "2023", "", "", "", "", "")  # 3.3 start date
    extend("", "", "", "", "", "", "", "")  # 3.4 end date — ongoing role
    extend(
        "Chairman and Director of BRMSTE LTD with executive responsibility for the firm's "
        "payment services activity: HSBC Open Banking (PSD2) integration, payment initiation and "
        "account information services programme, AML/KYC governance, safeguarding arrangements, "
        "operational oversight of BizStrat rails, and FCA authorisation liaison. "
        "Binding signatory for BRMSTE LTD (Companies House 15310393)."
    )

    # --- 4.1 Employment (1) current ---
    extend(
        "11", "23",
        "", "",
        "Self-employed / Director",
        "BRMSTE LTD",
        REG_OFFICE,
        "SHRAVAN BANSAL LTD (renamed BRMSTE LTD 16 Mar 2026)",
        "Software development; IT consultancy; holding company (SIC 62012, 62020, 64209)",
        "No",
        "Director / Chairman",
        "Executive management of BRMSTE LTD including payment services programme, governance, and regulatory applications.",
    )

    # --- 4.1 Employment (2) previous ---
    extend(
        "", "", "", "",
        "",
        "REQUIRED — previous employer (10-year history)",
        "REQUIRED — employer address",
        "",
        "REQUIRED — nature of business",
        "",
        "REQUIRED — position",
        "REQUIRED — responsibilities",
        "REQUIRED — reason (specify in checkbox)",
    )

    # --- 4.1 Employment (3) previous ---
    extend(
        "", "", "", "",
        "",
        "REQUIRED — continue 10-year employment history",
        "", "", "", "", "", "", "", "", "",
    )

    # --- 4.2 Qualifications (3 x 5 = 15) ---
    for _ in range(3):
        extend("", "", "", "", "")

    # --- 5.15 details field if yes ---
    extend("")

    # --- Section 6 (3 fields) ---
    extend(
        f"6.1 — FCA Connect ApplicationId {FCA_APPLICATION_ID}. "
        f"Applicant firm BRMSTE LTD (CH 15310393). Registered office: "
        f"{REG_OFFICE}, {REG_POSTCODE}. "
        "Payment services scope: account information and payment initiation via HSBC Open Banking; "
        "BizStrat operator rails. Patent GB2607860 · PCT/GB2026/050406. "
        "Complete all REQUIRED fields marked above before submission.",
        "",
        "0",
    )

    # --- Section 7 declarations ---
    extend(
        "Shravan Bansal",
        "DD", "D", "D", "M", "M", "Y", "Y", "Y",
        "BRMSTE LTD",
        "Shravan Bansal",
        "Director / Chairman",
        "DD", "D", "D", "M", "M", "Y", "Y", "Y",
    )

    while len(v) < 160:
        v.append("")
    return v[:160]


def main() -> None:
    values = build_complete_values()
    if len(values) != 160:
        raise SystemExit(f"Expected 160 field values, got {len(values)}")

    shutil.copy(BLANK, FILLED)
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
