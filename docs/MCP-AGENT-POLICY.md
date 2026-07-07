# MCP agent policy · strict only

**Agents never ask for tokens in chat.** Credentials belong in Cursor MCP configuration or operator-managed CI secrets — not in conversation.

## Operator setup (one-time, outside chat)

1. Open **Cursor → Settings → Tools & MCP**
2. Connect each server this repo uses:

| Server | Purpose |
|--------|---------|
| **Cloudflare-bindings** | List Workers, D1, KV, R2 |
| **Cloudflare-builds** | Deploy Workers via Builds |
| **Cloudflare-observability** | Worker logs and metrics |
| **Cloudflare-docs** | Product documentation search |
| **Render** | Render services (if used) |
| **Etoro-api-docs** | eToro public API reference |

3. Optional project file: `.cursor/mcp.json` (see `.cursor/mcp.json.example` — never commit real secrets)
4. **Reload Window** after changing MCP config

## Agent behavior (mandatory)

| Do | Don't |
|----|-------|
| `mcp_get_tools` then `mcp_call_tool` | "Please paste your CF_API_TOKEN" |
| Point to **Tools & MCP → Connect** on auth failure | Export env vars and ask user to fill in chat |
| Use `workers_list` to verify deploy state | Raw Cloudflare API with user-supplied bearer |
| Confirm before MCP **write** actions | Assume silent permission on destructive writes |

## Cloudflare coming-soon via MCP

```
workers_list                          → confirm brmste-com-coming-soon exists
workers_get_worker(scriptName=...)    → script id / metadata
Cloudflare-builds (connected)         → deploy new version
query_worker_observability            → post-deploy logs
curl https://brmste.com/health        → expect brmste-coming-soon-v5
```

## Cursor GitHub App (operator setup, one-time)

Cloud agents can push branches but need the **Cursor GitHub App** authorized on the repo to open pull requests. Without it, PR creation fails with `must be a collaborator`.

1. Open <https://github.com/apps/cursor> → **Configure**
2. Select the **BRMSTE-SB** organization (org admin required)
3. Under **Repository access**, choose **All repositories** — or **Only select repositories** and add `.github` (and any other agent-worked repos)
4. Save — agents can then create PRs; pushed branches are unaffected either way

Fallback while unauthorized: agents push the branch and link the GitHub compare URL for the operator to open the PR manually.

## CI vs MCP

GitHub Actions `deploy-coming-soon.yml` uses repository secrets configured by the operator in GitHub Settings. Agents may trigger or monitor workflows via `gh` but **must not request secret values**.

## Related

- [.cursor/rules/mcp-strict-only.mdc](../.cursor/rules/mcp-strict-only.mdc)
- [AGENTS.md](../AGENTS.md)
- [DEPLOY-COMING-SOON.md](../DEPLOY-COMING-SOON.md)
- [CARBON-JUSTICE.md](../CARBON-JUSTICE.md)
