# Fort Knox · BRMSTE PayPal + Companies House (Mac)

PayPal credentials and Companies House auth codes stay **local only** — never in public GitHub.

## PayPal key folder

```
/Users/sachindabas/Desktop/API keys - Copy/PayPal/
├── BRMSTE-PAYPAL-EMAIL.txt       → BRMSTE_PAYPAL_MERCHANT_EMAIL
├── PAYPAL-CLIENT-ID.txt          → PAYPAL_CLIENT_ID
├── PAYPAL-CLIENT-SECRET.txt      → PAYPAL_CLIENT_SECRET
├── PAYPAL-WEBHOOK-ID.txt         → PAYPAL_WEBHOOK_ID (optional)
└── COMPANIES-HOUSE-AUTH-CODE.txt → COMPANIES_HOUSE_AUTH_CODE (optional)
```

Create the app at [developer.paypal.com](https://developer.paypal.com) under your **BRMSTE PayPal** business account.

## Connect Harrods revenue rail

From a clone of [BRMSTE-SB/.github](https://github.com/BRMSTE-SB/.github):

```bash
bash scripts/connect-harrods-paypal-mac.sh
```

Custom folder:

```bash
bash scripts/connect-harrods-paypal-mac.sh "/path/to/PayPal"
```

Merges into `.env.fort-knox` alongside AI keys — does not overwrite existing vars.

## Verify

```bash
set -a && source .env.fort-knox && set +a
bash scripts/connect-harrods-paypal-mac.sh --verify-only
```

## Companies House auth

Store your company auth code in `COMPANIES-HOUSE-AUTH-CODE.txt` or set `COMPANIES_HOUSE_AUTH_CODE` in `.env.fort-knox`.

File via:

```bash
bash scripts/file-companies-house-harrods.sh
```

## Security

- `.env.fort-knox` is **never committed**
- Rotate any PayPal secret pasted into chat
- Public lane = [data/harrods-revenue-rail.json](../data/harrods-revenue-rail.json) only

BRMSTE LTD · Companies House 15310393
