# Convex Quickstart (React + Vite)

A minimal [Convex](https://convex.dev) + React (Vite + TypeScript) app, scaffolded
from the official [Convex React Quickstart](https://docs.convex.dev/quickstart/react).
It loads a `tasks` table from a Convex deployment and renders it in the browser.

> Maintained by **BRMSTE-SB** as a reference starter. See the org
> [`PATENT-NOTICE.md`](../PATENT-NOTICE.md) and [`BRAND.md`](../BRAND.md).

## What's included

- `convex/schema.ts` — declares the `tasks` table (`text`, `isCompleted`).
- `convex/tasks.ts` — exposes the `api.tasks.get` query.
- `convex/_generated/` — Convex-generated API/types (committed so the app typechecks).
- `src/main.tsx` — wires up `ConvexProvider` + `ConvexReactClient`.
- `src/App.tsx` — uses `useQuery(api.tasks.get)` to render tasks.
- `sampleData.jsonl` — three sample tasks you can import.

## Getting started

```bash
npm install
```

### 1. Connect a Convex deployment

Run the Convex dev server. This logs you in (or creates an anonymous local
deployment), provisions a deployment, regenerates `convex/_generated/`, and writes
`VITE_CONVEX_URL` into `.env.local`. Keep it running to sync your functions.

```bash
npx convex dev
```

To develop fully offline without a Convex account, use the beta anonymous mode:

```bash
CONVEX_AGENT_MODE=anonymous npx convex dev
```

### 2. Seed the sample data

In a second terminal (with the dev server running):

```bash
npx convex import --table tasks sampleData.jsonl
```

### 3. Run the app

```bash
npm run dev
```

Open http://localhost:5173 and you'll see the imported tasks.

## Scripts

- `npm run dev` — start the Vite dev server.
- `npm run build` — typecheck (`tsc -b`) and build for production.
- `npm run lint` — run ESLint.
- `npm run preview` — preview the production build.

## Notes

- `.env.local` holds your deployment URL and is git-ignored — never commit it.
- `convex/_generated/` is committed intentionally; regenerate it any time with
  `npx convex dev` or `npx convex codegen`.
