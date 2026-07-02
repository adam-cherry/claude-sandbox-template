# CLAUDE.md

Guidance for Claude Code (claude.ai/code) in this repository.

## What this is

**claude-sandbox-template** is an **agnostic starting point** for new projects with
a ready-to-use Claude Code **agentic framework**: curated skills, rules,
a plugin ecosystem, a protected Git workflow and the `looping` engineering loop.
No GSD, no project-specific code — clone it as a GitHub template, fill in the placeholders,
get going.

It does not replace a concrete stack: Python, Node, Docker, Docs — the framework is
technology-neutral. Project-specific conventions go into `.claude/config/project.md`.

## Getting started

1. Clone the template as a repo / "Use this template" on GitHub.
2. `make setup` — activates the Git hook (`core.hooksPath=.githooks`), creates `.env` from
   `.env.example` and runs the smoke test. (`make help` shows all targets.)
3. Fill in `.claude/config/project.md` (name, type, language) and populate `.env`.
4. Start `claude` and run **`/onboarding`** — the guided flow sets up the rest
   (verify plugins, Obsidian/gh optional, project.md, Git flow explanation).

## Git workflow (protected)

Two stages: `main` + `feature/*`. Direct commits to `main` are blocked by the `pre-commit` hook.
Changes land on `main` via `/local-pr` (validated squash-merge).

- `branch-guard` (hook) reminds you at session start/prompt when you are not on `feature/*`.
- Emergency: `/break-glass` (deliberately bypasses the hook — admin only).
- Details: `.claude/rules/git-workflow.md`, `.claude/rules/conventional-commits.md`.

## Looping — the engineering loop

`/looping <goal>` is the core: instead of editing directly, it runs
**research → plan → validate → [gate] → execute (parallel, on feature branch) → verify → review**.
Two tracks: **code** (features/refactors/fixes) and **content** (consistent multi-file
docs rollouts). The GSD successor — without its machinery. For non-trivial,
multi-step work; for a one-liner just edit directly.

Flags: gates `--auto` / (default) / `--careful`; cost `--lite` / (default) / `--ultra`;
`--track=code|content`.

## Skills (`.claude/skills/`)

| Skill | Purpose |
|-------|-------|
| `onboarding` | Guided first-run setup (hook, .env, plugins, Obsidian, Git flow, project.md) — `/onboarding` |
| `looping` | Goal-based engineering loop (research→plan→validate→execute→verify→review) |
| `local-pr` | Feature branch → `main` (validated squash-merge) |
| `break-glass` | Emergency commit to `main` (admin only) |
| `new-spike` | Set up a spike sandbox + docs for experiments |
| `debugging` | Research-first debugging (root-cause, condition-based-waiting, defense-in-depth) |
| `python` | Python conventions (type hints, Pydantic, pytest) |
| `docker` | Docker/Compose best practices |
| `powershell` | PowerShell automation best practices |
| `notebook` | Run Jupyter notebooks + dependency handling |
| `release-tag` | Semver/date release tag + CHANGELOG |
| `where` | Status in one command: branch, tag, ahead/behind |
| `recommend` | Recommend a matching skill/plugin/rule/agent for a task |
| `update-context` | Consolidate project context into a vNext snapshot |
| `promptify` | Request → copy-paste-ready, high-quality prompt |
| `gh-pm` | GitHub Issues + Projects (V2) via `gh` CLI |
| `team-update` | Outcome-style Slack/Teams update from git context |
| `screen-input` | Raw notes → structured bullets |
| `excalidraw` | Architecture diagrams as `.excalidraw` + PNG/SVG export |
| `html-presentation` | HTML slide deck from Markdown (reveal.js) |

Never create new skills by hand — use `skill-creator` (`.claude/rules/skill-quality.md`).

## Rules (`.claude/rules/`)

Binding directives. Selection:

- **git-workflow** / **conventional-commits** — branch model, commit format
- **secrets-guardrails** — never put secrets in Git, keep `.env.example` up to date
- **mcp-policy** — don't build your own MCP servers, use existing ones via `claude mcp add`
- **skill-ecosystem** / **skill-quality** — only native Claude Code extensions, DRY
- **worktree-policy** — worktrees only for parallel, file-overlapping agents
- **code-language** — language convention (code vs. docs)
- **writing-style** / **anti-bias** / **no-placeholders** / **release-quality** — output quality
- **persona-quality** — persona agents following CO-STAR + TIDD-EC
- **graphify-usage** — knowledge graph of the codebase (optional, via `pipx install graphify`)

## Plugins

The plugin ecosystem is preconfigured **declaratively** in `.claude/settings.json`:
`extraKnownMarketplaces` registers the marketplaces (GitHub sources) project-locally,
`enabledPlugins` activates the plugins. As a result they load automatically on the first
`claude` start — **no manual `/plugin marketplace add`**. Among others superpowers, claude-mem,
context7, code-review, skill-creator, github, git-workflow, document-skills. Full
list, marketplace sources + fallback on load errors: `setup/plugins/plugin_setup.md`.
Inventory of all components: `setup/plugins/stack.csv`.

## Directory layout

- `.claude/` — skills, rules, hooks, config, settings
- `.githooks/` — pre-commit (protects `main`)
- `Makefile` — `setup` / `hooks` / `smoke-test` / `status` targets (`make help`)
- `setup/blueprints/` — versioned repo structure templates (agentic_project_structure)
- `setup/genes/` — blueprint lineage tracking (which version, which deviations)
- `setup/plugins/` — plugin setup guide + `stack.csv` (inventory)
- `setup/workflows/` — workflow/skill index
- `setup/executions/` — smoke test + hello world
- `docs/` — **Obsidian Vault** (docs, ADRs in `01_adr/`, specs) — open as vault: `docs/`
- `.input/` — research, drafts, plans (gitignored)

## MCP

`.mcp.json` is empty (project-scoped). Add servers via `claude mcp add` — HTTP
preferred, stdio for npm packages. Never build your own MCP servers (`.claude/rules/mcp-policy.md`).
