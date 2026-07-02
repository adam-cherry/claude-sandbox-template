# Plugin Setup Guide

This template loads its plugin ecosystem **declaratively** — normally
**no manual steps** are required. `.claude/settings.json` contains two blocks:

- `extraKnownMarketplaces` — automatically registers the required marketplaces (GitHub sources)
  on first start, project-locally. No global `/plugin marketplace add` needed.
- `enabledPlugins` — enables the individual plugins per marketplace.

On the first `claude` start in the cloned repo, the marketplaces are pulled and the
plugins are loaded. Prerequisite: Claude Code CLI installed, GitHub reachable.

**Stack inventory:** `stack.csv` (source of truth for plugins/skills/rules/tools).

## Marketplaces (preconfigured in settings.json)

| Marketplace (Name) | GitHub source |
|--------------------|---------------|
| `claude-plugins-official` | `anthropics/claude-plugins-official` |
| `anthropic-agent-skills` | `anthropics/skills` |
| `thedotmack` | `thedotmack/claude-mem` |
| `netresearch-claude-code-marketplace` | `netresearch/claude-code-marketplace` |
| `karpathy-skills` | `multica-ai/andrej-karpathy-skills` |
| `addy-web-quality-skills` | `addyosmani/web-quality-skills` |

## Included Plugins

| Plugin | Marketplace | Purpose |
|--------|-------------|---------|
| superpowers | claude-plugins-official | Engineering workflows (TDD, plans, debugging, worktrees) |
| claude-mem | thedotmack | Persistent memory across sessions |
| context7 | claude-plugins-official | Live library docs |
| code-review | claude-plugins-official | Code review for PRs |
| code-simplifier | claude-plugins-official | Simplify code |
| claude-md-management | claude-plugins-official | Audit CLAUDE.md |
| skill-creator | claude-plugins-official | Create / test skills |
| claude-api | anthropic-agent-skills | Anthropic SDK / caching / model reference |
| github | claude-plugins-official | GitHub integration |
| git-workflow | netresearch-claude-code-marketplace | Branching + conventional commits |
| github-project | netresearch-claude-code-marketplace | Branch protection / repo config |
| andrej-karpathy-skills | karpathy-skills | Behavioral guidelines (Karpathy) |
| chrome-devtools-mcp | claude-plugins-official | Browser debugging via DevTools |
| web-quality-skills | addy-web-quality-skills | Lighthouse / a11y / performance |
| mcp-server-dev | claude-plugins-official | Build + bundle MCP servers |
| document-skills | anthropic-agent-skills | PPTX / DOCX / PDF export |
| frontend-design | claude-plugins-official | Frontend / UI design guidance |
| security-guidance | claude-plugins-official | Security best practices |
| claude-code-setup | claude-plugins-official | Claude Code configuration |

## If plugins still show up as "✘ error"

Older Claude Code versions may not recognize `extraKnownMarketplaces`. In that case, register them
manually once and reload:

```bash
/plugin marketplace add anthropics/skills
/plugin marketplace add thedotmack/claude-mem
/plugin marketplace add netresearch/claude-code-marketplace
/plugin marketplace add multica-ai/andrej-karpathy-skills
/plugin marketplace add addyosmani/web-quality-skills
/plugin marketplace list   # should show all marketplaces
```

Then run `/reload-plugins` or restart Claude Code. `claude-plugins-official` is the
official marketplace and is usually already known globally.

## Standalone Tools (optional)

**Graphify** (knowledge graph, see `.claude/rules/graphify-usage.md`):
```bash
pipx install graphify && graphify claude install && graphify update .
```

## Customizing

Remove plugins you don't need from `.claude/settings.json` under `enabledPlugins`; their
marketplace can stay in `extraKnownMarketplaces` (no harm) or be removed too.
Additional plugins: add the marketplace under `extraKnownMarketplaces` (if new),
then add an entry in `enabledPlugins`. Rule: `.claude/rules/skill-ecosystem.md`.
