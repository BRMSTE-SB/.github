# BRMSTE Email Inbox — `sb@brmste.ai`

**BRMSTE LTD · Companies House 15310393 · GB2607860 · Human-open lane**

A Cloudflare **Email Worker** that captures inbound mail addressed to
`sb@brmste.ai` (and any address in `INBOX_ADDRESSES`), parses it, and stores it
in a **D1** database (`brmste-email-inbox`). A token-protected JSON endpoint
(`GET /inbox`) reads it back — and because the store is D1, the inbox is also
checkable over the Cloudflare MCP with `d1_database_query`.

This keeps `sb@brmste.ai` mail on BRMSTE's own Cloudflare infrastructure — no
third-party mailbox, no API keys pasted in chat (carbon-justice / MCP-strict).

## Why this exists

`CHECK SB@BRMSTE.AI EMAILS` previously had no working path: the Mailgun MCP has
no API key and the Zapier (Gmail/Outlook) MCP is unauthenticated. This worker
makes the mailbox readable through infrastructure agents already control.

## How it works

```
inbound mail ──▶ Cloudflare Email Routing (brmste.ai)
                      │  rule: sb@brmste.ai → Worker "brmste-email-inbox"
                      ▼
              email(message, env)  ── postal-mime parse ──▶  D1: emails table
                      ▲
   GET /inbox  ◀──────┘  (Bearer INBOX_TOKEN)              MCP: d1_database_query
```

| Item    | Value                                    |
| ------- | ---------------------------------------- |
| Worker  | `brmste-email-inbox`                     |
| Account | `7ea6547b1d6eb1cbd6d0ac5cf960ce2a`       |
| D1 name | `brmste-email-inbox`                     |
| D1 id   | `5f18fadc-f347-430c-8f11-eccb116e9351`   |
| Health  | `"page":"brmste-email-inbox-v1"`         |

## Endpoints

- `GET /health` — open; returns `{ ok, service, page, addresses, inbox_reader, outbound }`.
- `GET /inbox` — **requires** `Authorization: Bearer <INBOX_TOKEN>` (or
  `?token=`). Returns the latest messages.
  - `?address=sb@brmste.ai` — filter by recipient.
  - `?limit=N` — cap results (default 50, max 200).
  - `?id=<message-id>` — fetch one full message (incl. text/html body).
  - Returns `503` until `INBOX_TOKEN` is configured (locked by default).
- `POST /send` — **requires** `Authorization: Bearer <INBOX_TOKEN>`. Sends an
  email through **CloudMailin** (see below). Body JSON: `{ to, subject,
  plain|html, cc?, from?, test_mode? }`. `to`/`cc` may be a string or array.
  Returns `202` on accept; `503` if CloudMailin isn't configured.

## Outbound (CloudMailin)

BRMSTE's email provider is **CloudMailin** (there is no CloudMailin MCP, so the
Mailgun/Sinch MCP cannot be used). Sending uses CloudMailin's outbound API
(`POST https://api.cloudmailin.com/api/v0.1/{username}/messages`, HTTP Basic
auth). Configure these **secrets** (never in the repo / never in chat):

```bash
cd email-inbox
wrangler secret put CLOUDMAILIN_USERNAME   # SMTP username from the outbound account
wrangler secret put CLOUDMAILIN_API_KEY    # SMTP API key (password)
wrangler secret put INBOX_TOKEN            # Bearer token for /inbox and /send
```

Validate the channel without delivering anything using `test_mode` (CloudMailin
validates but does not send):

```bash
curl -X POST -H "Authorization: Bearer $INBOX_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to":"you@example.com","subject":"BRMSTE test","plain":"hi","test_mode":true}' \
  https://brmste.ai/send
```

For a cloud agent to send/verify directly, the same two `CLOUDMAILIN_*` values
can instead be added as **Cloud Agent secrets** (Cursor Dashboard → Cloud Agents
→ Secrets); they are injected as env vars into the agent VM.

## Local development & tests

```bash
cd email-inbox
npm install
npm test          # vitest: parse -> store -> read, fully in Node
npm run dev       # wrangler dev (fetch reader; email() needs deploy + routing)
```

## Deploy

Via GitHub Actions: push to `main` touching `email-inbox/**` runs
`.github/workflows/deploy-email-inbox.yml` (gate → tests → schema → deploy),
using operator-managed `CF_API_TOKEN` / `CF_ACCOUNT_ID`.

Or manually (operator, with a Cloudflare token in the environment — never in chat):

```bash
cd email-inbox
npm run schema                      # apply D1 schema (remote)
npm run deploy                      # deploy the worker
wrangler secret put INBOX_TOKEN     # set the reader token
```

## One manual step that MCP cannot do: enable Email Routing

The Cloudflare MCP exposes Workers/D1/KV/R2 but **no DNS / Email-Routing**
tools, so the routing rule must be created once by the operator (Cloudflare
dashboard → **brmste.ai → Email → Email Routing**):

1. Enable Email Routing for `brmste.ai` (adds the required MX + TXT records).
2. Add a **custom address** rule: `sb@brmste.ai` → **Send to a Worker** →
   `brmste-email-inbox`.

After that, mail to `sb@brmste.ai` lands in D1 automatically.

## Checking the inbox

Over HTTP (once deployed + token set):

```bash
curl -H "Authorization: Bearer $INBOX_TOKEN" \
  "https://brmste.ai/inbox?address=sb@brmste.ai&limit=20"
```

Over Cloudflare MCP (no HTTP needed):

```
Cloudflare-bindings → d1_database_query
  database_id: 5f18fadc-f347-430c-8f11-eccb116e9351
  sql: SELECT id, ts, mail_from, rcpt_to, subject
       FROM emails WHERE rcpt_to = 'sb@brmste.ai' ORDER BY ts DESC LIMIT 20;
```
