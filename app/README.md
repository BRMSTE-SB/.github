# OCTA — BRMSTE Global Systems Integrator Platform

**BRMSTE LTD · Companies House 15310393 · GB2607860 · PCT/GB2026/050406**

OCTA is BRMSTE's own Global Systems Integrator (GSI) platform — a real-time operations hub for managing client organisations, registered services, integration health, and the OCTA work queue.

## Stack

- **Frontend:** React 18 + TypeScript + Vite
- **Backend:** [Convex](https://convex.dev) — reactive real-time database + serverless functions
- **Auth:** OIDC-compatible (WorkOS, Clerk, Auth0 — plug in via `convex.setAuth`)

## Platform Modules

| Module | Description |
|---|---|
| **Dashboard** | Live overview — service count, org count, integration health scores, open/critical tickets |
| **Service Registry** | Register and manage OCTA-provided capabilities (Re-Tyre, BRMSTE Mining Pool, Carbon, AI, etc.) |
| **Organisation Board** | Kanban board of client orgs across onboarding → active → suspended lifecycle |
| **Work Queue** | Operational tickets with priority lanes (critical / high / medium / low) and status progression |

## Data Model

### Tables

| Table | Purpose | Key Indexes |
|---|---|---|
| `users` | Platform users with role (admin / operator / viewer) | `by_token`, `by_role` |
| `organisations` | Client orgs managed by OCTA | `by_slug`, `by_status` |
| `services` | OCTA service capabilities | `by_code`, `by_category`, `by_status` |
| `integrations` | Org ↔ Service connections with health scores | `by_org`, `by_service`, `by_org_and_service`, `by_status` |
| `tickets` | Operational work queue | `by_status`, `by_priority`, `by_assignee` |

### Role-Based Access

| Role | Permissions |
|---|---|
| `admin` | Full access including role management |
| `operator` | Create/update orgs, services, integrations, tickets |
| `viewer` | Read-only across all modules |

## Project Structure

```
app/
├── convex/
│   ├── schema.ts              # All five tables with indexes
│   ├── users.ts               # store, me, setRole
│   ├── organisations.ts       # list, get, create, update
│   ├── services.ts            # list, get, create, update
│   ├── integrations.ts        # listByOrg, listByService, listAll, create, updateStatus
│   ├── tickets.ts             # list, listMine, create, update, remove
│   └── lib/auth.ts            # getCurrentUser, requireAdmin, requireOperator
├── src/
│   ├── main.tsx               # ConvexProvider entry
│   ├── App.tsx                # Sidebar nav + tab routing
│   ├── App.css                # Full dark-mode styles
│   └── components/
│       ├── Dashboard.tsx      # Stat cards + integration health
│       ├── ServiceRegistry.tsx
│       ├── OrgBoard.tsx       # Kanban layout
│       └── WorkQueue.tsx      # Priority ticket list
├── index.html
├── package.json
└── vite.config.ts
```

## Getting Started

```bash
cd app
npm install

# Start Convex backend (development only — NOT deploy)
npx convex dev

# In a second terminal:
npm run dev
# → http://localhost:5173
```

## Production Deployment

```bash
npx convex deploy   # Deploy Convex functions (production only)
npm run build       # Build frontend → dist/
```

Deploy `dist/` to Vercel, Cloudflare Pages, or any static host.

---

*BRMSTE LTD · GB2607860 · PCT/GB2026/050406 · Beneficiary: Dimpy Bansal · Dimpy Bansal Trust*
