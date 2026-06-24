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

## Verify parity (no download)

```bash
bash scripts/verify-hetzner-parity.sh
```

Confirms `data/hetzner/*` and collider logos **byte-match** live `brmste.com` before you collect on Mac.

## What gets collected

| Folder | Contents |
|--------|----------|
| `logos/` | Live-edge collider, wordmark, cursor-agent (SHA verified) |
| `substrate/hetzner/` | fleet, servers, all-sales-to-paypal, admin, rain, russia, … |
| `substrate/brmste/` | hydrated-logos.json |
| `substrate/gi/` | hetzner.json GI bind |
| `substrate/global-fleet/` | manifest.json |
| `substrate/control-plane/` | manifest.json |
| `api/` | hetzner status, control-plane status, live-pay |
| `hetzner-ssh/` | Per-server probe (SSH aliases or direct IP) |
| `github/` | Governance mirror for diff |
| `COLLECT-MANIFEST.txt` | SHA256 of every file in the bundle |

## 15 Hetzner servers (from live `servers.json`)

| ID | IP | SSH (read-only) |
|----|-----|-----------------|
| lucifer | 5.223.86.44 | `brmste-lucifer-ro` |
| brmste-db | 178.104.79.112 | `brmste-db-ro` |
| sdbm-os | 178.104.82.164 | `brmste-commercial-ai-ro` |
| commercial-com | 135.181.153.241 | `brmste-commercial-com-ro` |
| commercial-ai-sb | 135.181.154.11 | `brmste-commercial-ai-sb-ro` |
| patent-box | 5.161.49.73 | `brmste-patent-box-ro` |
| patent-carbon | 178.156.239.245 | `brmste-patent-carbon-ro` |
| carbon-usa | 178.156.238.78 | `brmste-carbon-usa-ro` |
| carbon-usa2 | 5.78.232.16 | `brmste-carbon-usa2-ro` |
| retyre | 178.104.90.207 | `brmste-retyre-ro` |
| foundry-pool | 167.233.21.99 | `brmste-foundry-pool-ro` |
| siemens | 46.224.23.51 | `brmste-siemens-ro` |
| bizstrat | 5.78.66.96 | `brmste-bizstrat-ro` |
| leading | 138.199.170.193 | `brmste-leading-ro` |
| shravan-hetzner | 5.161.239.112 | `brmste-shravan-hetzner-ro` |

Setup SSH: `npm run setup:server-ssh` (Fort Knox tooling · Kohinoor Mac).

## Live binds

- Fleet: https://brmste.com/substrate/hetzner/fleet.json
- Servers: https://brmste.com/substrate/hetzner/servers.json
- Sales → PayPal: https://brmste.com/substrate/hetzner/all-sales-to-paypal.json
- Hydrated logos: https://brmste.com/substrate/brmste/hydrated-logos.json

BRMSTE LTD · Shravan Bansal · GB2607860
