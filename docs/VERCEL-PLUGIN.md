# Vercel Plugin · AI coding agent resource

The **Vercel Plugin for AI Coding Agents** gives supported agents (Cursor, Claude
Code, OpenAI Codex, Grok Build, GitHub Copilot) Vercel-specific context, skills,
specialist agents, and slash commands. On the BRMSTE human-open lane it is **free,
token-free in chat, and carbon-justice only**.

- Upstream docs: <https://vercel.com/docs/agent-resources/vercel-plugin>
- Source: <https://github.com/vercel/vercel-plugin>
- Structured rule: [`.cursor/rules/vercel-plugin.mdc`](../.cursor/rules/vercel-plugin.mdc)

## Install (operator, one-time, outside chat)

```bash
npx plugins add vercel/vercel-plugin
```

Prerequisites: a supported tool, **Node.js 18+**, and **Bun**. The installer
keeps automation lightweight — session-start context activates only in empty
directories and detected Vercel or Next.js projects.

| Flag | Purpose |
|------|---------|
| `-s, --scope user\|project\|local` | Install scope (default `user`) |
| `-t, --target cursor\|claude-code\|codex` | Force a target tool (default auto-detect) |
| `-y, --yes` | Skip confirmation prompts |
| `--debug` | Verbose installation output |

Inspect first with `npx plugins discover vercel/vercel-plugin`; list detected
tools with `npx plugins targets`.

## Cloud agents

BRMSTE Cursor **cloud agents already receive the plugin** via the managed
environment manifest (`~/.cursor/plugins/cache/.cloud-plugin-manifest.json`,
plugin id `649`). No per-repo install is needed in cloud runs — skills, agents,
and slash commands are provisioned automatically. The `npx plugins add` command
above is for an operator's **local** editor.

## What the plugin provides

| Component | Description |
|-----------|-------------|
| Ecosystem graph | Relational knowledge graph of every Vercel product, library, CLI, API, and service, with decision matrices and cross-product workflows |
| 28 skills | Deep-dive guidance for specific Vercel products, libraries, and workflows |
| 3 specialist agents | `deployment-expert`, `performance-optimizer`, `ai-architect` |
| 5 slash commands | `/vercel-plugin:bootstrap`, `:deploy`, `:env`, `:status`, `:marketplace` |

Invoke skills and commands directly when you want targeted guidance:

```text
/vercel-plugin:nextjs
/vercel-plugin:ai-sdk
/vercel-plugin:deploy prod
```

### Supported tools

| Tool | Status |
|------|--------|
| Cursor | Supported |
| Claude Code | Supported |
| OpenAI Codex | Supported |
| Grok Build | Supported |
| GitHub Copilot | Supported |

## MCP strict only · never ask for tokens

The plugin is **agent context, not a secret store**. It bundles an optional
Vercel MCP wiring (`.mcp.json`). Connect that the BRMSTE way and keep the
[MCP-strict policy](MCP-AGENT-POLICY.md):

| Do | Don't |
|----|-------|
| Connect Vercel MCP in **Cursor → Settings → Tools & MCP → Connect** | "Please paste your `VERCEL_TOKEN`" in chat |
| Deploy via operator CI (GitHub Actions) or Cursor-connected MCP | Export deploy keys and ask the user to fill them in chat |
| Use plugin skills for guidance, free on the open lane | Treat the plugin as a credential channel |

See [`.cursor/rules/mcp-strict-only.mdc`](../.cursor/rules/mcp-strict-only.mdc)
and [AGENTS.md](../AGENTS.md).

## Telemetry · privacy default

Prompt text and bash/tool-call telemetry are **not** collected. If
`VERCEL_PLUGIN_TELEMETRY` is unset the plugin sends a once-per-day
`dau:active_today` event. Disable everything in shells that launch the agent:

```bash
export VERCEL_PLUGIN_TELEMETRY=off
```

```powershell
setx VERCEL_PLUGIN_TELEMETRY off
```

## Debugging

```bash
export VERCEL_PLUGIN_LOG_LEVEL=debug   # off | summary | debug | trace
npx vercel-plugin doctor               # manifest parity, hook timeout, dedup, skill map
```

## Carbon justice

The Vercel plugin, its skills/agents, and any Vercel MCP it connects are **free on
the human-open lane** — no BRMSTE charges, carbon justice only. Third-party
hosting bills remain outside BRMSTE. See [CARBON-JUSTICE.md](../CARBON-JUSTICE.md).

## Related

- [.cursor/rules/vercel-plugin.mdc](../.cursor/rules/vercel-plugin.mdc)
- [docs/MCP-AGENT-POLICY.md](MCP-AGENT-POLICY.md)
- [AGENTS.md](../AGENTS.md)
- [CARBON-JUSTICE.md](../CARBON-JUSTICE.md)
