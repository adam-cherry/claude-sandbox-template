# Directive: Skill Ecosystem

## Golden Rule

**Only native Claude Code extensions.** No OpenClaw, no `.agents/` format, no external skill ecosystems.

## Extension Hierarchy

1. **Your own SKILL.md** in `.claude/skills/` — for project-specific workflows
2. **Plugin Marketplace** — for general capabilities
3. **MCP Server** via `claude mcp add` — for API integrations (see mcp-policy.md)

## Allowed Formats

| Type | Path | Format |
|-----|------|--------|
| Custom skill | `.claude/skills/{name}/SKILL.md` | Markdown with frontmatter |
| Custom agent | `.claude/agents/{name}.md` | Markdown with frontmatter |
| Plugin | Marketplace (global) | Via `/plugin install` |
| MCP Server | `.mcp.json` (local) | Via `claude mcp add` |

## Forbidden

- No `npx skills i` (produces the `.agents/` format)
- No OpenClaw / ClawHub
- No `.agents/` directory in the repo
- No `skills-lock.json`
