# Vercel MCP — Connect in Cursor

**BRMSTE LTD · Companies House 15310393 · GB2607860**

The official Vercel MCP server lets agents search Vercel docs, list projects/deployments, and inspect logs without leaving Cursor.

## Why MCP shows `error` in Cloud Agents

Vercel MCP uses **browser OAuth**. Cloud Agents cannot complete the login flow interactively. You must authorize once in **Cursor Desktop**:

1. Open this repo in Cursor Desktop.
2. Confirm `.cursor/mcp.json` contains:

```json
{
  "mcpServers": {
    "vercel": {
      "url": "https://mcp.vercel.com"
    }
  }
}
```

3. Go to **Settings → Tools & MCP** (or `Cmd+Shift+P` → “MCP”).
4. Find **Vercel** and click **Connect** / **Needs login**.
5. Complete the Vercel OAuth flow in your browser.

After auth, the Vercel MCP tools (`list_projects`, `get_deployment`, `search_vercel_docs`, etc.) become available to local and cloud agents that share your Cursor account.

## One-click setup (alternative)

Vercel documents a one-click add for Cursor: [Use Vercel's MCP server](https://vercel.com/docs/agent-resources/vercel-mcp)

CLI setup (interactive, on your Mac):

```bash
npx vercel mcp --clients Cursor
```

## OAuth redirect errors

If you see **“The app redirect URL is invalid”**, this is a Vercel-side OAuth client registration issue with Cursor’s callback URI (`cursor://anysphere.cursor-mcp/oauth/callback`). Report it to Vercel support and watch [Cursor forum thread #159005](https://forum.cursor.com/t/vercel-mcp-oauth-fails-app-configuration-error-redirect-url-is-invalid/159005).

## Off-Cloudflare Vercel domains

Per `data/hetzner/hydrated-logos.json`, these domains are **not** on Cloudflare Workers:

| Domain | Host |
|--------|------|
| `leadingmetals.com` | Vercel |
| `leadingmetalloys.com` | LiteSpeed (not this workflow) |

Deploy the branded coming-soon fleet to Vercel: [DEPLOY-VERCEL.md](../DEPLOY-VERCEL.md)

## Carbon justice lane

MCP access is part of the open lane in [CARBON-JUSTICE.md](../CARBON-JUSTICE.md) — no BRMSTE charges; carbon justice only.
