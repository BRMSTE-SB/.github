# Hetzner fleet · collect on Mac

**15 Hetzner nodes** · live registers on `brmste.com` · SSH from **THE KOHINOOR MAC** only.

## Why GitHub logos looked different

The live **Carbon Collider Token** (SHA `63f7904d…`) is served at:

- `https://brmste.com/brmste-favicon.svg`
- `https://brmste.com/favicon.svg`

An earlier GitHub copy of `brmste-gsi-collider-logo.svg` had edited SVG metadata (different SHA). **Canonical rule:** GSI collider = **byte-identical** to `brmste-carbon-token-collider.svg`.

## One command on your Mac

```bash
curl -fsSL "https://raw.githubusercontent.com/BRMSTE-SB/.github/main/scripts/download-all-hetzner-to-mac.sh" \
  | bash -s -- "$HOME/Downloads/BRMSTE-HETZNER-ALL"
```

Or from a cloned repo:

```bash
bash scripts/download-all-hetzner-to-mac.sh ~/Downloads/BRMSTE-HETZNER-ALL
```

## What gets collected

| Folder | Contents |
|--------|----------|
| `logos/` | Live-edge collider, wordmark, cursor-agent (SHA verified) |
| `substrate/hetzner/` | fleet, servers, all-sales-to-paypal, admin, rain, russia, … |
| `substrate/brmste/` | hydrated-logos.json |
| `hetzner-ssh/` | Per-server probe (if SSH configured) |
| `github/` | Governance mirror for diff |

## 15 Hetzner servers (from live `servers.json`)

| ID | IP | SSH (read-only) |
|----|-----|-----------------|
| lucifer | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| REDACTED-SSH-KEY | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| sdbm-os | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| commercial-com | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| commercial-ai-sb | REDACTED-IP | `REDACTED-SSH-KEY-sb-ro` |
| patent-box | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| patent-carbon | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| carbon-usa | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| carbon-usa2 | REDACTED-IP | `REDACTED-SSH-KEY2-ro` |
| retyre | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| foundry-pool | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| siemens | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| bizstrat | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| leading | REDACTED-IP | `REDACTED-SSH-KEY-ro` |
| shravan-hetzner | REDACTED-IP | `REDACTED-SSH-KEY-ro` |

Setup SSH: `npm run setup:server-ssh` (Fort Knox tooling · Kohinoor Mac).

## Live binds

- Fleet: https://brmste.com/substrate/hetzner/fleet.json
- Servers: https://brmste.com/substrate/hetzner/servers.json
- Sales → PayPal: https://brmste.com/substrate/hetzner/all-sales-to-paypal.json
- Hydrated logos: https://brmste.com/substrate/brmste/hydrated-logos.json

BRMSTE LTD · Shravan Bansal · GB2607860
