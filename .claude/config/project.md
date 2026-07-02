# Project Config

Single source of truth for project-wide paths + conventions. Skills read here —
do not duplicate this in CLAUDE.md or other files. Fill in when instantiating the template.

## Project Identity

| Field | Value |
|------|------|
| **Name** | `<your-project>` |
| **Type** | `<e.g. Python Backend / React Frontend / CLI Tool / Docs>` |
| **Blueprint** | `agentic_project_structure.md` |
| **Domain** | `<short>` |
| **Language** | `<German / English>` (see `.claude/rules/code-language.md`) |

## Path Mapping

| Purpose | Path |
|-------|------|
| **Input / WIP** | `.input/` (research, drafts, plans — gitignored) |
| **Docs** | `docs/` |
| **Setup meta** | `setup/` (blueprints, genes, plugins, workflows, executions) |
| **Looping state** | `.loop/<slug>/` (per run, gitignored) |

## Git Workflow

Two stages: `main` + `feature/*`, squash-merge via `/local-pr`. Direct commits to `main`
are blocked by the pre-commit hook (`.githooks/pre-commit`). Details: `.claude/rules/git-workflow.md`.
