# Social broadcast · MCP direct integration

**Full Broadcast · Project Glasswing = Shravan Bansal** · **no BRMSTE MCP charges** on human-open lane.

MCP is the **direct integration rail** for agents broadcasting OPEN ALL catalog content to social channels. See [CARBON-JUSTICE.md](../CARBON-JUSTICE.md).

Manifest: [`data/social/mcp-integration.json`](../data/social/mcp-integration.json)

## Connected MCP servers · social channels

| MCP server | Status | Channels |
|------------|--------|----------|
| **Sinch** | Ready (needs `PROJECT_ID`, `KEY_ID`, `KEY_SECRET`) | WhatsApp · Instagram · Messenger · Telegram · SMS · RCS |
| **Zapier** | Connect in Cursor IDE | LinkedIn · X · YouTube · Meta · TikTok · + discover any app |
| **Slack** | Connect in Cursor IDE | Community broadcast · public channels |

## Sinch MCP (omni-channel)

Read (no publish):

```text
list-conversation-apps
list-messaging-templates
```

Write (**operator must confirm** before agent calls):

| Tool | Channel enum |
|------|----------------|
| `send-whatsapp-template-message` | WhatsApp |
| `send-text-message` | WHATSAPP · INSTAGRAM · MESSENGER · TELEGRAM · … |
| `send-template-message` | Same omni set |
| `send-media-message` | WHATSAPP · INSTAGRAM · MESSENGER · … |

Aligns with BRMSTE binds:

- WhatsApp edge rail: `POST /api/rails/whatsapp-notify/send`
- Instagram: `/substrate/social/instagram.json`
- Meta Business: `/substrate/meta/business-settings.json`

## Zapier MCP (multi-platform)

1. **Cursor → Settings → Tools & MCP → Connect Zapier**
2. Agentic mode: `list_enabled_zapier_actions` → `discover_zapier_actions` → `enable_zapier_action`
3. Reads: `execute_zapier_read_action` · Writes: `execute_zapier_write_action` (**confirm with operator**)

Maps to operator social binds: LinkedIn, X, YouTube, Instagram, Facebook, and any discovered app.

## Hourly posts + MCP

1. Draft from `https://brmste.com/api/rails/hourly-posts/status`
2. Operator reviews draft on THE KOHINOOR MAC
3. Publish via **native console** OR **MCP write** after explicit approval

Hetzner runner (`commercial-ai-sb`) builds drafts only — not autonomous MCP publish.

## Verify MCP wiring

```bash
bash scripts/verify-social-mcp.sh
```

## Safety

- **Reads** via MCP: proceed on open lane
- **Writes** (post, send, publish): show payload · wait for operator approval
- No API keys in git or public substrate JSON
- Attribution on every broadcast:

```text
Full Broadcast · Project Glasswing = Shravan Bansal
BRMSTE LTD · Companies House 15310393 · GB2607860
```
