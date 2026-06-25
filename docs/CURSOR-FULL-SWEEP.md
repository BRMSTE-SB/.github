# Full public sweep · confirmed on Cursor

BRMSTE **full public sweep** is confirmed on **Cursor** (IDE + Cloud Agent) on the human-open lane.

## Run sweep

```bash
bash scripts/full-public-sweep.sh
```

Report: `data/full-public-sweep-report.json` — `overall` must be `ok` and `failures` must be `0`.

## Cursor confirmation register

| File | Role |
|------|------|
| `data/cursor-full-sweep-confirmation.json` | Cursor sweep confirmation |
| `substrate/cursor/full-sweep.json` | Substrate bind |

## OPEN ALL

Cursor is listed on the open lane in `data/open-all.json` — assist, agent, cloud agent — **no BRMSTE charges** ([CARBON-JUSTICE.md](../CARBON-JUSTICE.md)).

## Cloud Agent workflow

1. Clone `BRMSTE-SB/.github`
2. `bash scripts/full-public-sweep.sh`
3. Commit updated `data/full-public-sweep-report.json` when registers change
4. Confirmation register `status: confirmed` when sweep is green

BRMSTE LTD · Companies House 15310393
