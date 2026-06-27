# BRMSTE Coming Soon · Theme Source

**Canonical Desktop theme:** `/Users/sachindabas/Desktop/brmste-coming-soon`

**Repo deploy path:** `coming-soon/site/`

## Sync Desktop → repo (THE KOHINOOR MAC)

```bash
bash scripts/sync-desktop-coming-soon-theme.sh
# preview:
bash scripts/sync-desktop-coming-soon-theme.sh --dry-run
```

Override paths:

```bash
BRMSTE_DESKTOP_THEME=~/Desktop/brmste-coming-soon \
BRMSTE_SITE_DIR=./coming-soon/site \
bash scripts/sync-desktop-coming-soon-theme.sh
```

Then deploy:

```bash
cd coming-soon && npm run deploy
```

## Theme tokens (brmste-coming-soon)

| Token | Value |
|-------|-------|
| Substrate | `#07101f` |
| Panel | `#0c1829` |
| Gold | `#d4af37` |
| Light gold | `#f5e6b8` |
| Emerald | `#10b981` |
| Ink | `#f7f1df` |
| Muted | `#9fb0c3` |

Shell classes: `brand-header`, `brand-nav`, `brand-main`, `brand-hero`, `brand-highlight`, `brand-footer`.
