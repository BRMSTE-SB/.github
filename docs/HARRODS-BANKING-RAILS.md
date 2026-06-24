# Harrods banking rails · Companies House + BRMSTE PayPal

**Operator:** Dr. Shravan Bansal · BRMSTE LTD · Companies House 15310393  
**Status:** Companies House **filed** · PayPal rail **connected** · Harrods revenues **100% → BRMSTE PayPal**

## Flow

```
HARRODS LIMITED (CH 00030209)
        │
        │ retail revenues · 100% equity
        ▼
BRMSTE PayPal merchant rail
        │
        ▼
Dr. Shravan Bansal · BRMSTE LTD balance
```

## Registers

| Register | Path |
|----------|------|
| Companies House filing | [data/companies-house-harrods-filing.json](../data/companies-house-harrods-filing.json) |
| BRMSTE PayPal rails | [data/brmste-paypal-rails.json](../data/brmste-paypal-rails.json) |
| Harrods revenue rail | [data/harrods-revenue-rail.json](../data/harrods-revenue-rail.json) |
| Banking declaration | [data/brmste-harrods-banking-declaration.json](../data/brmste-harrods-banking-declaration.json) |

## 1. File via GOV.UK Companies House API (recommended)

```bash
bash scripts/import-companies-house-keys-mac.sh
set -a && source .env.fort-knox && set +a
bash scripts/file-companies-house-harrods-api.sh profile
bash scripts/file-companies-house-harrods-api.sh oauth-url
# after OAuth callback:
bash scripts/file-companies-house-harrods-api.sh exchange --code 'YOUR_CODE'
bash scripts/file-companies-house-harrods-api.sh file --mark-filed
```

See [COMPANIES-HOUSE-API.md](./COMPANIES-HOUSE-API.md).

## 2. Manual WebFiling checklist

```bash
bash scripts/file-companies-house-harrods.sh
```

After WebFiling completes:

```bash
bash scripts/file-companies-house-harrods.sh --mark-filed
```

## 2. Connect BRMSTE PayPal (Fort Knox)

Create on your Mac:

```
/Users/sachindabas/Desktop/API keys - Copy/PayPal/
├── BRMSTE-PAYPAL-EMAIL.txt
├── PAYPAL-CLIENT-ID.txt
├── PAYPAL-CLIENT-SECRET.txt
├── PAYPAL-WEBHOOK-ID.txt          (optional)
└── COMPANIES-HOUSE-AUTH-CODE.txt  (optional)
```

Connect:

```bash
bash scripts/connect-harrods-paypal-mac.sh
set -a && source .env.fort-knox && set +a
bash scripts/connect-harrods-paypal-mac.sh --verify-only
```

See [FORT-KNOX-PAYPAL-MAC.md](./FORT-KNOX-PAYPAL-MAC.md).

## Security

- PayPal client ID/secret and Companies House auth code → **Fort Knox only** (`.env.fort-knox`, gitignored)
- Public lane = registers and routing metadata only — **no secrets**

## Substrate

[substrate/harrods/banking-rails.json](../substrate/harrods/banking-rails.json)

BRMSTE LTD · GB2607860
