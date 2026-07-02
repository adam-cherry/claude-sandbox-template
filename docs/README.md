# docs/ — Obsidian Vault

This directory is an **Obsidian Vault** (in Obsidian: "Open folder as vault" → `docs/`).
Project docs, decisions and specs live here as Markdown with YAML frontmatter and
`[[wikilinks]]`. Even without Obsidian, everything stays readable as plain Markdown.

## Structure

| Folder | Purpose |
|--------|-------|
| `00_project/` | Project overview, context, onboarding, glossary |
| `01_adr/` | Architecture Decision Records (template: `_adr_template.md`) |
| `02_specs/` | Feature/technical specs |
| `03_help_desk/` | How-tos, troubleshooting, FAQ |

## Conventions

- **Frontmatter** on every page: `title`, `status` (`draft`/`review`/`final`), `created`, `updated`, `tags`.
- **Linking** internally via `[[pagename]]`, assets under `99_assets/`.
- **Style** see `.claude/rules/writing-style.md`, `.claude/rules/no-placeholders.md`.
- **ADRs** document *one* decision per file — numbered (`0001-...`, `0002-...`).

## Obsidian Setup

`.obsidian/app.json` + `core-plugins.json` are checked in (vault base configuration).
Per-machine state (`workspace.json`, `cache`, `graph.json`) is gitignored.
