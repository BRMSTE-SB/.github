# PCT/GB2026/050406 · ePCT Document Register

**Operator:** Dr. Shravan Bansal · BRMSTE LTD · Companies House **15310393**  
**UK patent:** **GB2607860** (granted 2023-10-11)  
**PCT lane:** **PCT/GB2026/050406** · compact **PCTGB2026050406**  
**ePCT receipt date:** **2026-06-29**

## Operator documents (Fort Knox — local Mac)

These files are **not committed** to the open lane. The manifest records filenames, WIPO doc types, and sha256 after you run the verify script.

| File | WIPO / kind | Meaning |
|------|-------------|---------|
| `BRMSTE-DIAMOND-CONSOLIDATED.docx` | operator bundle | BRMSTE consolidated patent bundle (Diamond lane) |
| `PCTGB2026050406-eucl-000046-en-20260629.pdf` | **EUCL** | Cover letter from ePCT |
| `PCTGB2026050406-amcl-000047-en-20260629.pdf` | **AMCL** | Amended claims under **PCT Article 19** |

Default folder on Mac:

```text
~/Downloads/dbrmstre^PCTGB2026050406-documents/
```

## Verify on Mac (sha256 ledger)

```bash
bash scripts/verify-pct-documents-mac.sh \
  "$HOME/Downloads/dbrmstre^PCTGB2026050406-documents"
```

Or with explicit paths:

```bash
bash scripts/verify-pct-documents-mac.sh \
  "/Users/shravanbansal/Downloads/dbrmstre^PCTGB2026050406-documents"
```

Writes sha256 into `data/patents/pct-gb2026-050406/manifest.json` (Fort Knox copy — do not push secrets if manifest is local-only; open lane keeps filenames only).

## Machine-readable register

| Path | Purpose |
|------|---------|
| [data/patents/pct-gb2026-050406/manifest.json](../data/patents/pct-gb2026-050406/manifest.json) | Canonical document manifest |
| [substrate/patents/pct-gb2026-050406.json](../substrate/patents/pct-gb2026-050406.json) | Substrate bind |
| [PATENT-NOTICE.md](../PATENT-NOTICE.md) | Org patent notice |

Online (after edge deploy): https://brmste.com/substrate/patents/pct-gb2026-050406.json

## WIPO document codes

Per [WIPO PCT EDI minimal specification](https://www.wipo.int/documents/d/patentscope/docs-en-pct-edi-documents-minimal_specification_v4_4.pdf):

- **EUCL** — end-user cover letter from ePCT
- **AMCL** — amended claims under Article 19

Filename pattern: `{PCTID}-{code}-{seq}-{lang}-{YYYYMMDD}.pdf`

## Important — do not conflate

**WO/2026/050406** on [WIPO PATENTSCOPE](https://patentscope.wipo.int/) is an **unrelated** international application (PCT/US2025/043779 · eductor filter assembly). It is **not** BRMSTE's **PCT/GB2026/050406** lane tied to GB2607860.

## Related

- [GLOBAL-SHRAVAN-BANSAL-BRAND.md](../GLOBAL-SHRAVAN-BANSAL-BRAND.md)
- [CARBON-JUSTICE.md](../CARBON-JUSTICE.md) · CARBON JUSTICE UK LIMITED CH 17304635

BRMSTE LTD · GB2607860 · PCT/GB2026/050406
