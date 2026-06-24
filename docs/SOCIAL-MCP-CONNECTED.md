# MCP connected · publish from Kohinoor Mac Cursor

You connected Zapier / Slack / Sinch in **Cursor IDE**. This cloud agent cannot use your local MCP session — run these steps **in the same Cursor window where MCP shows Connected**.

## 1. Verify MCP

Ask Cursor:

```text
List enabled Zapier actions for social (LinkedIn, X, YouTube, Instagram).
```

Agentic Zapier: `list_enabled_zapier_actions`  
Classic Zapier: tools like `twitter_send_tweet`, `linkedin_create_post` (names vary).

## 2. Pull this hour's draft

```bash
bash scripts/fetch-hourly-draft-for-mcp.sh
```

Or live: https://brmste.com/api/rails/hourly-posts/status

**This hour (live edge):** platform rotates linkedin → x → youtube hourly.

## 3. Publish via MCP (after you approve)

Example prompts in **connected Cursor**:

**X (this hour's lane):**

```text
Using Zapier MCP, post this to @shravanbansal on X (show me the payload first, wait for my OK):

GLASSWING · BRMSTE · brmste.com/truth · @shravanbansal · X Premium active

Full Broadcast · Project Glasswing = Shravan Bansal
BRMSTE LTD · GB2607860
```

**LinkedIn:**

```text
Using Zapier MCP, create a LinkedIn post from the output of fetch-hourly-draft-for-mcp.sh — confirm before send.
```

**WhatsApp / Instagram (Sinch):**

```text
Using Sinch MCP, send-text-message on WHATSAPP — show payload first. Needs PROJECT_ID, KEY_ID, KEY_SECRET in env.
```

## 4. Rules

- **Reads** via MCP: go ahead
- **Writes**: agent must show payload · you say **yes** before publish
- No BRMSTE charge on open lane · carbon justice only
- Attribution required on every post (see `SOCIAL-MEDIA-BROADCAST.md`)

## Sinch env (Kohinoor Mac)

```bash
export PROJECT_ID=… KEY_ID=… KEY_SECRET=… CONVERSATION_APP_ID=…
bash scripts/verify-social-mcp.sh
```

Manifest: `data/social/mcp-integration.json`
