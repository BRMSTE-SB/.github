# Okta OIDC · BRMSTE edge auth

**BRMSTE LTD · Companies House 15310393 · GB2607860**

Banking surfaces on `brmste-com-coming-soon` require Okta sign-in when OIDC is configured.

## Okta application

| Field | Value |
|-------|-------|
| Org | `trial-4122800` |
| Issuer | `https://trial-4122800.okta.com/oauth2/default` |
| Client ID | `0oa14nyit7owrT8Yw698` |
| Client secret | Worker secret `OKTA_CLIENT_SECRET` — **never in git** |

## Okta admin (General tab)

Set these on the OIDC client:

| Setting | Value |
|---------|-------|
| Sign-in redirect URIs | `https://brmste.com/login/callback` · `https://www.brmste.com/login/callback` |
| Sign-out redirect URIs | `https://brmste.com/banking` · `https://www.brmste.com/banking` |
| Grant type | Authorization Code |
| PKCE | Required (worker uses S256) |

Add `http://localhost:8787/login/callback` for local Wrangler dev.

## Protected routes

| Route | Behavior without session |
|-------|--------------------------|
| `/banking` | Redirect to `/login` |
| `/api/banking/networth` | `401` JSON with `login` URL |

Public pages (`/`, `/brand`, `/open`, etc.) stay open.

## Worker configuration

Non-secrets in `coming-soon/wrangler.toml`:

- `OKTA_ISSUER`
- `OKTA_CLIENT_ID`

Secret (operator-managed):

```bash
export OKTA_CLIENT_SECRET='…'
export CLOUDFLARE_API_TOKEN='…'
export CLOUDFLARE_ACCOUNT_ID='7ea6547b1d6eb1cbd6d0ac5cf960ce2a'
bash scripts/set-okta-worker-secrets.sh
```

Then deploy: `cd coming-soon && npm run deploy`

## Verify

```bash
curl -s https://brmste.com/health | jq '.auth'
# expect configured: true

curl -sI https://brmste.com/banking | grep -i location
# expect redirect to /login when not authenticated
```

## Security

- Rotate `OKTA_CLIENT_SECRET` if it was ever pasted in chat or committed.
- Do not store Okta secrets in this public repository.
