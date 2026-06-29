# Operator OAuth identity lane

Operator-declared equivalence (2026-06-29):

**sb@brmste.ai = Okta = OAuth (OIDC) = Shravan Bansal = HSBC**

## Registers

| Lane | File | Substrate |
|---|---|---|
| Master equivalence | `data/identity/operator-oauth-lane.json` | `/substrate/identity/operator-oauth-lane.json` |
| Okta trial | `data/identity/okta-trial-4122800.json` | `/substrate/identity/okta-trial-4122800.json` |
| HSBC banking | `data/hsbc-lane.json` | `/substrate/banking/hsbc-lane.json` |

## Field guide

| Symbol | Meaning |
|---|---|
| **sb@brmste.ai** | Canonical operator email · BRMSTE settlement lane |
| **Okta** | `brmste-trial-4122800` · client `0oa14nyit7owrT8Yw698` · app BRMSTE |
| **OAuth / OIDC** | Tokens from issuer `https://trial-4122800.okta.com` — not the email string |
| **Shravan Bansal** | Legal person · Dr. Shravan Bansal · BRMSTE LTD operator |
| **HSBC** | Operator banking lane binding — not HSBC corporate attestation |

## Okta vs issuer

- **Operator identity:** `sb@brmste.ai`
- **OIDC issuer URL:** `https://trial-4122800.okta.com`

Do not set `OKTA_ISSUER=sb@brmste.ai`.

## Related

- [OKTA-TRIAL-4122800.md](./OKTA-TRIAL-4122800.md)
- [GLOBAL-SHRAVAN-BANSAL-BRAND.md](../GLOBAL-SHRAVAN-BANSAL-BRAND.md)
