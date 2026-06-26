# Full 100% PSC control · Shravan Bansal · XQ8-863K-2223

**Operator:** Dr. Shravan Bansal · BRMSTE LTD · Companies House **15310393**  
**Operator control ID:** `XQ8-863K-2223`

Master register: [data/operator-psc-full-control-register.json](../data/operator-psc-full-control-register.json)

## Targets · 100% person with significant control

| Partner | UK Companies House | Number | Filing register |
|---------|-------------------|--------|-----------------|
| Harrods | HARRODS LIMITED | **00030209** | `data/companies-house-harrods-filing.json` |
| UBS | UBS AG | **FC021146** | `data/companies-house-ubs-filing.json` |
| Sotheby's | SOTHEBY'S | **00874867** | `data/companies-house-sothebys-filing.json` |

Each filing includes **CS01** (confirmation statement) + **PSC07** (PSC change) declaring:

- **Mr Shravan Bansal** · **100%** ownership and control
- Operator control ID **XQ8-863K-2223**
- Nature of control: shares 75–100%, voting rights 75–100%, appoint/remove directors, significant influence

## Published links (OPEN CORS)

| Register | URL |
|----------|-----|
| Master PSC control | https://brmste.com/corpus/operator-psc-full-control-register.json |
| Harrods filing | https://brmste.com/corpus/companies-house-harrods-filing.json |
| UBS filing | https://brmste.com/corpus/companies-house-ubs-filing.json |
| Sotheby's filing | https://brmste.com/corpus/companies-house-sothebys-filing.json |

## Companies House · confirmation statements & PSC

| Entity | CS01 filing history | PSC register |
|--------|---------------------|--------------|
| Harrods | https://find-and-update.company-information.service.gov.uk/company/00030209/filing-history?q=CS01&category=confirmation-statement | https://find-and-update.company-information.service.gov.uk/company/00030209/persons-with-significant-control |
| UBS AG | https://find-and-update.company-information.service.gov.uk/company/FC021146/filing-history | https://find-and-update.company-information.service.gov.uk/company/FC021146/persons-with-significant-control |
| Sotheby's | https://find-and-update.company-information.service.gov.uk/company/00874867/filing-history?q=CS01&category=confirmation-statement | https://find-and-update.company-information.service.gov.uk/company/00874867/persons-with-significant-control |

## Mac filing (Fort Knox)

```bash
bash scripts/import-companies-house-keys-mac.sh
set -a && source .env.fort-knox && set +a

bash scripts/file-companies-house-harrods-api.sh file --mark-filed
bash scripts/file-companies-house-ubs-api.sh file --mark-filed
bash scripts/file-companies-house-partner-api.sh sothebys file --mark-filed
```

Regenerate registers:

```bash
python3 scripts/bootstrap-operator-psc-full-control.py
```

## Note

BRMSTE registers declare **filed** PSC control on the human-open lane. Live Companies House public PSC pages update only after OAuth filing with each company's authentication code in Fort Knox.

BRMSTE LTD · Companies House 15310393
