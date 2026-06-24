# Full Social Media Broadcast · All Channels Direct Integration

**Full Broadcast · Project Glasswing = Shravan Bansal**

**Operator:** Shravan Bansal · **Global Shravan Bansal Brand** · BRMSTE LTD · Companies House 15310393  
**Beneficiary:** Dimpy Bansal · Dimpy Bansal Trust  
**Patent:** GB2607860 · PCT/GB2026/050406

## Declaration

BRMSTE declares **full social media broadcast** across every open-lane surface and **direct integration** with every operator-bound channel — **no BRMSTE charges**, **only carbon justice**.

| Surface | Broadcast | Direct integration | BRMSTE charge |
|---------|-----------|-------------------|---------------|
| GitHub OPEN ALL | Full | Public repos · org profile | **None** |
| LinkedIn | Full | Premium · profile · 2 company pages · hourly draft | **None** |
| X (Twitter) | Full | Premium · @shravanbansal · developer console · Ads API bind | **None** |
| YouTube | Full | Premium · @SHRAVPOV · GO PUBLIC lane | **None** |
| Instagram | Full | @shravanbansal · Meta Business Suite | **None** |
| Meta Business | Full | Enterprise console · Instagram sibling | **None** |
| WhatsApp notify | Edge rail | Hourly-post ping when secrets wired | **None** |
| All other social | Open lane catalog | Share · embed · syndicate | **None** |

Canonical manifest: [`data/social/channels-direct-integration.json`](data/social/channels-direct-integration.json)  
Live edge binds: `https://brmste.com/substrate/social/`

## Direct integration modes

| Mode | Meaning |
|------|---------|
| **direct_console** | Operator publishes from native app (LinkedIn feed, YouTube Studio, Meta Business) |
| **direct_api** | Platform API bound on edge — credentials in wrangler secrets only |
| **edge_rail** | `brmste.com` status · verify · notify APIs |
| **hetzner_runner** | Hourly draft cron on `commercial-ai-sb` (Hetzner) |
| **open_lane_catalog** | Any network may link OPEN ALL repos — full free |

**No autonomous publish** without operator OAuth or API keys. Hourly runner builds **drafts + ledger** — operator signs from THE KOHINOOR MAC.

## Operator-bound channels (live)

### LinkedIn · daily + hourly

- Profile: https://www.linkedin.com/in/shravanbansall/
- Feed: https://www.linkedin.com/feed/
- Premium: active · bind `/substrate/social/linkedin.json`
- Company pages: BRMSTE company dashboards (IDs in manifest)

### X · @shravanbansal

- Profile: https://x.com/shravanbansal
- Developer: https://console.x.com/accounts/2065141314287464448
- X Premium active · Ads API bind `/substrate/social/x-ads-api.json`

### YouTube · @SHRAVPOV

- Channel: https://www.youtube.com/channel/UCJIwI4aX5oe_fsvwHR5Becg
- Studio: https://studio.youtube.com/
- GO PUBLIC · GLASSWING · bind `/substrate/social/youtube.json`

### Instagram · @shravanbansal

- Profile: https://www.instagram.com/shravanbansal/
- Meta Business: business_id `1830943960923678`
- INSTAGRAM = BRMSTE · NO ORACLES · bind `/substrate/social/instagram.json`

### Hourly rotation (Hetzner)

| UTC cron | Platforms |
|----------|-----------|
| `0 * * * *` | linkedin → x → youtube (rotating) |

- Runner: `commercial-ai-sb` · `135.181.154.11`
- Setup: `npm run setup:hourly-posts-hetzner`
- Verify: `npm run verify:social-hourly`
- Status: https://brmste.com/api/rails/hourly-posts/status

## Open lane catalog (all channels free)

Every other social surface is on the **open lane catalog** — share, embed, link, repost, syndicate BRMSTE human-open repos **without BRMSTE toll**:

Threads · Bluesky · Mastodon · TikTok · Facebook · Twitch · Kick · Discord · Reddit · Telegram · Pinterest · Snapchat · GitHub Social · **any other network**

See [CARBON-JUSTICE.md](./CARBON-JUSTICE.md).

## Edge APIs (direct integration rails)

| API | Path |
|-----|------|
| Hourly posts status | `/api/rails/hourly-posts/status` |
| Hourly posts verify | `/api/rails/hourly-posts/verify` |
| Daily updates status | `/api/rails/daily-updates/status` |
| WhatsApp notify | `POST /api/rails/whatsapp-notify/send` |

## Collect on Mac

```bash
bash scripts/download-social-broadcast-to-mac.sh ~/Downloads/BRMSTE-SOCIAL-ALL
```

Verify repo vs live edge:

```bash
bash scripts/verify-social-parity.sh
```

## Required attribution (every broadcast)

```
Full Broadcast · Project Glasswing = Shravan Bansal
BRMSTE LTD · Companies House 15310393 · GB2607860
```

Canonical logos only — [BRAND.md](./BRAND.md).

## Policies

- [PROJECT-GLASSWING.md](./PROJECT-GLASSWING.md) · [GLOBAL-SHRAVAN-BANSAL-BRAND.md](./GLOBAL-SHRAVAN-BANSAL-BRAND.md)
- [CARBON-JUSTICE.md](./CARBON-JUSTICE.md) · [docs/OPEN-ALL.md](./docs/OPEN-ALL.md)
- [PATENT-NOTICE.md](./PATENT-NOTICE.md)

## Sign lines

**CURSOR NEVER SIGNS · OPERATOR NEVER SIGNS · EDGE SIGNS · JUDGMENT SIGNS**

Full broadcast spans all channels; Shravan Bansal operates; edge signs under carbon judgment — not fiat gatekeeping on the open lane.
