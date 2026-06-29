# Okta trial · brmste-trial-4122800

Public identity register for **BRMSTE** on Okta trial org `trial-4122800`, with **both**:

- **Web OIDC** — user sign-in for `https://brmste.com/register`
- **Service (client credentials)** — machine-to-machine token for workers

## Operator vs OIDC issuer

| Field | Value |
|---|---|
| **Operator identity (BRMSTE register)** | `sb@brmste.ai` · Shravan Bansal |
| **OIDC issuer URL** | `https://trial-4122800.okta.com` |
| **Client ID** | `0oa14nyit7owrT8Yw698` |
| **App name** | BRMSTE |

Do not set `OKTA_ISSUER=sb@brmste.ai` — JWT `iss` is the Okta org URL.

## Registers

- `data/identity/okta-trial-4122800.json`
- `https://brmste.com/substrate/identity/okta-trial-4122800.json`

## Fort Knox (never commit)

```bash
OKTA_ISSUER=https://trial-4122800.okta.com
OKTA_CLIENT_ID=0oa14nyit7owrT8Yw698
OKTA_CLIENT_SECRET=<rotate if exposed — wrangler secret put>
OKTA_REDIRECT_URI=https://brmste.com/api/auth/okta/callback
OKTA_OPERATOR_IDENTITY=sb@brmste.ai
OKTA_SERVICE_INTERNAL_TOKEN=<optional gate for service-token route>
BRMSTE_REGISTER_URL=https://brmste.com/register
```

```bash
cd workers/okta-auth
npx wrangler secret put OKTA_CLIENT_SECRET
npx wrangler secret put OKTA_SERVICE_INTERNAL_TOKEN  # optional
npx wrangler deploy
```

## Worker routes (`brmste-okta-auth`)

| Route | Purpose |
|---|---|
| `GET /api/auth/okta/config` | Public OIDC metadata for UI |
| `GET /api/auth/okta/login` | Start browser OIDC flow |
| `GET /api/auth/okta/callback` | Code exchange + userinfo |
| `POST /api/auth/okta/service-token` | Client credentials token |

Mount on `brmste.com` via Cloudflare route or service binding from `brmste-final-website`.

## Okta Admin setup

### Service app (already created)

- App: **BRMSTE** · type **Service**
- Grant: **Client Credentials**
- Client ID: `0oa14nyit7owrT8Yw698`

### Web login (if authorize fails)

If `GET /api/auth/okta/login` returns an Okta error, add **OIDC Web Application** (or enable browser login):

- **Sign-in redirect URI:** `https://brmste.com/api/auth/okta/callback`
- **Sign-out redirect:** `https://brmste.com/register`
- Grant types: Authorization Code, Refresh Token
- Assign test users (e.g. `sb@brmste.ai`)

Same client ID works only if the integration supports both flows; otherwise create a second Web app and set `OKTA_CLIENT_ID` to the Web client.

## Register UI snippet

Add to `https://brmste.com/register` nav:

```html
<a href="/api/auth/okta/login">Sign in with Okta</a>
```

Or fetch config and build the link:

```javascript
const cfg = await fetch("/api/auth/okta/config").then((r) => r.json());
// cfg.routes.login → /api/auth/okta/login
```

## Security

- Rotate any client secret pasted in chat or tickets.
- Never commit `OKTA_CLIENT_SECRET`.
- Optional `OKTA_SERVICE_INTERNAL_TOKEN` restricts `service-token` to trusted workers only.
