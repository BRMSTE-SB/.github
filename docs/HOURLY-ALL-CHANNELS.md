# Hourly posts · all channels

Post **every hour** to X, YouTube, Instagram, LinkedIn, Meta Business, and WhatsApp rail.

## One command (Kohinoor Mac)

```bash
bash scripts/hourly-post-all-channels.sh --open
```

Creates `~/Downloads/BRMSTE-HOURLY-ALL/YYYYMMDD-HHMM/` with:

| File | Platform |
|------|----------|
| `latest-x.txt` | @shravanbansal |
| `latest-linkedin.txt` | shravanbansall + company pages |
| `latest-youtube.txt` | @SHRAVPOV community tab |
| `latest-instagram.txt` | @shravanbansal |
| `latest-whatsapp.txt` | notify / Sinch |
| `latest-meta_business.txt` | Meta Business Suite cross-post |
| `MCP_BATCH_PROMPT.txt` | Paste into connected Cursor + Zapier |
| `manifest.json` | consoles · intent URLs |

## MCP batch (Zapier + Sinch connected)

```bash
bash scripts/hourly-post-all-channels.sh --mcp-prompt
```

Paste output into **local Cursor** where Zapier MCP is connected.

## Mac cron (every hour UTC)

```bash
(crontab -l 2>/dev/null; echo "0 * * * * $(pwd)/scripts/hourly-post-all-channels.sh --open") | crontab -
```

Hetzner runner (`commercial-ai-sb`) still runs `0 * * * *` for server-side ledger.

## Policy

[SOCIAL-MEDIA-BROADCAST.md](../SOCIAL-MEDIA-BROADCAST.md) · [docs/SOCIAL-MCP-CONNECTED.md](./SOCIAL-MCP-CONNECTED.md)

Manifest: `data/social/hourly-all-channels.json`
