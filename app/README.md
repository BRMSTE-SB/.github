# BRMSTE Task Manager · Convex Quickstart

A production-ready React + Vite + Convex task manager application.

## Stack

- **Frontend:** React 18 + TypeScript + Vite
- **Backend:** [Convex](https://convex.dev) — real-time reactive database + serverless functions
- **Styling:** Vanilla CSS (dark mode, BRMSTE palette)

## Features

- Real-time task list (updates instantly across all open tabs)
- Create, complete, and delete tasks
- Filter by All / Active / Done
- Full TypeScript type safety from database to UI
- Auth-ready (wire up any OIDC provider to `ConvexReactClient.setAuth`)

## Project Structure

```
app/
├── convex/                  # Backend (Convex functions)
│   ├── schema.ts            # Database schema (users + tasks)
│   ├── users.ts             # User storage mutation
│   ├── tasks.ts             # CRUD operations
│   ├── lib/
│   │   └── auth.ts          # getCurrentUser helper
│   └── _generated/          # Auto-generated types (do not edit)
├── src/                     # Frontend (React)
│   ├── main.tsx             # Entry point + ConvexProvider
│   ├── App.tsx              # Task manager UI
│   ├── App.css              # Styles
│   └── index.css
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

## Getting Started

### Prerequisites

- Node.js 18+
- npm 8+

### 1. Install dependencies

```bash
cd app
npm install
```

### 2. Configure environment

Copy `.env.local.example` to `.env.local`:

```bash
cp .env.local.example .env.local
```

### 3. Start Convex dev server (development only)

```bash
# Always use 'dev' for development — never 'deploy'
npx convex dev
```

This starts a local Convex backend, watches for changes, and writes `VITE_CONVEX_URL` to `.env.local` automatically.

### 4. Start the React app

In a second terminal:

```bash
npm run dev
```

Open [http://localhost:5173](http://localhost:5173).

> **Note:** The app uses `getCurrentUser` which requires an authenticated identity. To test without auth, you can temporarily modify `convex/tasks.ts` to skip the auth check and hardcode a test user, or wire up an auth provider (see below).

## Adding Authentication

The project is designed to work with any OIDC-compatible auth provider. Popular options:

### WorkOS AuthKit (recommended)

```bash
npm install @workos-inc/authkit-react
```

Update `src/main.tsx`:

```tsx
import { useAuth, AuthKitProvider } from "@workos-inc/authkit-react";

const convex = new ConvexReactClient(import.meta.env.VITE_CONVEX_URL);
convex.setAuth(useAuth);

createRoot(document.getElementById("root")!).render(
  <AuthKitProvider clientId={import.meta.env.VITE_WORKOS_CLIENT_ID}>
    <ConvexProvider client={convex}>
      <App />
    </ConvexProvider>
  </AuthKitProvider>
);
```

Add to `.env.local`:

```
VITE_WORKOS_CLIENT_ID=your_client_id
```

### Clerk

```bash
npm install @clerk/clerk-react
```

See [Convex + Clerk docs](https://docs.convex.dev/auth/clerk).

## Production Deployment

```bash
# Deploy Convex functions to production
npx convex deploy

# Build frontend
npm run build
```

Deploy the `dist/` folder to any static host (Vercel, Netlify, Cloudflare Pages).

## Schema

### `users` table

| Field | Type | Description |
|---|---|---|
| `tokenIdentifier` | `string` | OIDC token identifier (indexed) |
| `name` | `string` | Display name |
| `email` | `string` | Email address |

### `tasks` table

| Field | Type | Description |
|---|---|---|
| `userId` | `Id<"users">` | Owner reference (indexed) |
| `title` | `string` | Task text |
| `completed` | `boolean` | Completion state |
| `createdAt` | `number` | Unix timestamp |

Indexes: `by_user`, `by_user_and_completed`

## Learn More

- [Convex Docs](https://docs.convex.dev)
- [Convex React Hooks](https://docs.convex.dev/client/react)
- [Schema & Indexes](https://docs.convex.dev/database/schemas)
