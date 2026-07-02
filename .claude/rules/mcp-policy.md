# Directive: MCP Policy

## Golden Rule

**Don't build your own MCP servers.** Use existing packages/endpoints via `claude mcp add`.

## Installation

**HTTP (hosted):**
```bash
claude mcp add --transport http <name> <url>
```

**stdio (npm):**
```bash
claude mcp add --transport stdio <name> -- npx -y <package> [flags]
```

- Prefer HTTP when the provider has an endpoint
- stdio for npm packages without a hosted endpoint
- Use tool filters when a package offers more than needed
- Config lands in `.mcp.json` (project scope, versioned)

## Management

| Command | Purpose |
|--------|--------|
| `claude mcp add` | Add a server |
| `claude mcp list` | All servers + health check |
| `claude mcp remove <name>` | Remove a server |

## Forbidden

- Don't write your own MCP servers (no Python, no Node wrapper)
- No `git clone` + `npm run build` workflows for MCP
- No manual REST wrappers when an MCP package exists

## Research Order

1. Official MCP endpoints of the provider (HTTP)
2. Search npmjs.com for `<service>-mcp` (stdio)
3. GitHub MCP server directories (modelcontextprotocol/servers, awesome-mcp-servers)
4. Only when nothing exists: check back with the user
