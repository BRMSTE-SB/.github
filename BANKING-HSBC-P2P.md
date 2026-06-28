# Banking · HSBC BRMSTE P2P

**BRMSTE LTD · Companies House 15310393 · GB2607860**

## Definition

**HSBC BRMSTE P2P** is the **peer-to-peer domestic payment rail** for BRMSTE — GBP person-to-person transfers initiated via HSBC UK Open Banking **Payment Initiation Service (PIS)** on the corporate HSBCnet channel.

```
HSBC BRMSTE P2P = OBIE v4.0 · PISP · domestic person-to-person · Faster Payments · BRMSTE LTD
```

| Field | Value |
|-------|-------|
| **Rail ID** | `hsbc-brmste-p2p` |
| **Parent fiat rail** | HSBC UK (`hsbc-uk`) |
| **Entity** | BRMSTE LTD · CH 15310393 |
| **Standard** | UK Open Banking OBIE v4.0 |
| **Service role** | PISP (Payment Initiation) |
| **Payment type** | Domestic person-to-person |
| **Currency** | GBP |
| **Environment** | Real only |

## Open Banking flow

Person-to-person initiation via PISP (OBIE usage example):

1. **Create consent** — `POST /domestic-payment-consents`
2. **Customer authorisation** — redirect to HSBC for PSU consent
3. **Initiate payment** — `POST /domestic-payments`
4. **Poll status** — `GET /domestic-payments/{DomesticPaymentId}`

Debtor and creditor accounts use UK sort code + account number. The PSU pre-specifies the debtor account; the creditor receives the domestic Faster Payment.

## HSBC Developer Portal

| Resource | URL |
|----------|-----|
| Developer portal | [develop.hsbc.com](https://develop.hsbc.com/) |
| DevHub | [develop.hsbc.com/hsbc-devhub](https://develop.hsbc.com/hsbc-devhub) |
| Payment Initiation (HSBCnet UK) | [ob-api-documentation/payment-initiation-uk-hsbcnet](https://develop.hsbc.com/ob-api-documentation/payment-initiation-uk-hsbcnet) |
| OBIE P2P usage examples | [domestic-payments-usage-examples](https://openbankinguk.github.io/read-write-api-site3/v4.0/references/usage-examples/domestic-payments-usage-examples.html) |

Register on the portal, create a DevHub project, and obtain sandbox credentials before live PIS onboarding.

## Surfaces

| Surface | URL |
|---------|-----|
| Banking | [brmste.com/banking](https://brmste.com/banking) |
| P2P manifest | [brmste.com/public/banking/rails/hsbc-brmste-p2p.json](https://brmste.com/public/banking/rails/hsbc-brmste-p2p.json) |
| Parent HSBC rail | [brmste.com/public/banking/rails/hsbc.json](https://brmste.com/public/banking/rails/hsbc.json) |

Machine manifest: `data/banking/rails/hsbc-brmste-p2p.json`

## Verify

```bash
bash scripts/verify-banking-manifest.sh
```

## Related

- [BANKING-HSBC.md](./BANKING-HSBC.md) — HSBC UK fiat custody rail
- [BRMSTE-META.md](./BRMSTE-META.md) — USDC · Coinbase settlement (not Meta Platforms)
