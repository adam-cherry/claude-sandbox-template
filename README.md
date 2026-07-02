<div align="center">

# claude-sandbox-template

**A batteries-included starting point for [Claude Code](https://claude.com/claude-code).**
Curated skills, guardrail rules, a pre-wired plugin ecosystem, a protected git flow, and a
goal-based engineering loop — cloned and productive in minutes.

[![License: MIT](https://img.shields.io/badge/License-MIT-000.svg?style=flat-square)](./LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/Built%20for-Claude%20Code-da7756.svg?style=flat-square)](https://claude.com/claude-code)
![Template](https://img.shields.io/badge/GitHub-Template-2ea44f.svg?style=flat-square)

</div>

---

Technology-neutral. No project-specific code, no framework lock-in, no GSD. Use it as a sandbox
to explore what Claude Code can do, or as the foundation for a real project. Fork it, rate it,
make it yours.

## Get started in 3 steps

```bash
# 1. Click "Use this template" on GitHub (or clone your fork)
git clone <your-fork> my-project && cd my-project

# 2. One-command setup: git hook + .env + smoke test
make setup

# 3. Open Claude Code and run the guided onboarding
claude
> /onboarding
```

That's it. **`/onboarding`** walks you through everything else — verifying plugins, the git
flow, optional GitHub CLI + Obsidian, and filling in your project config — one step at a time.
Only the git hook and `.env` are required; the rest is optional.

> **Requirements:** [Claude Code](https://claude.com/claude-code) + Git. [uv](https://docs.astral.sh/uv/)
> (Python), GitHub CLI and Obsidian are optional and only needed for specific skills.

## What's inside

**`/looping` — the engineering loop.** The core of the template. Instead of editing blindly, a
goal becomes a merge-ready feature branch:

```
/looping <goal>
research → plan → validate → [gate] → execute (parallel) → verify → review → merge-ready
```

Two tracks (code & docs), tunable gates and depth. The lean successor to GSD — same rigor, none
of the machinery.

**20 skills** — `onboarding`, `looping`, `local-pr`, `break-glass`, `debugging`, `new-spike`,
`release-tag`, `where`, `recommend`, `promptify`, `update-context`, `gh-pm`, `team-update`,
`screen-input`, `excalidraw`, `html-presentation`, plus `python` / `docker` / `powershell` / `notebook`.

**Guardrail rules** — protected git flow, conventional commits, secrets hygiene, MCP policy,
skill quality, worktree policy, writing style, and more (`.claude/rules/`).

**Plugin ecosystem** — 19 plugins pre-wired in `.claude/settings.json` via `extraKnownMarketplaces`
+ `enabledPlugins`, so they **load automatically on first start** — no manual marketplace setup
(superpowers, claude-mem, context7, code-review, skill-creator, github, document-skills, …).

**Blueprints + genes** — a versioned, reusable recipe for standing up this framework in any repo,
with lineage tracking.

## The git flow

`main` is protected — a pre-commit hook blocks direct commits. You work on `feature/*` branches
and land changes with **`/local-pr`** (validated squash-merge). `/break-glass` is the deliberate
emergency escape hatch. Run `/where` any time for branch/tag status.

## Structure

```
.claude/           skills, rules, hooks, config, settings
.githooks/         pre-commit (protects main)
Makefile           setup / hooks / smoke-test / status  (make help)
setup/blueprints/  versioned repo-setup recipes
setup/genes/       blueprint lineage tracking
setup/plugins/     plugin setup guide + stack.csv (inventory)
setup/workflows/   workflow / skill index
docs/              Obsidian vault (docs, ADRs, specs) — open the docs/ folder as a vault
.input/            research, drafts, plans (gitignored)
```

Full guidance for Claude lives in [`CLAUDE.md`](./CLAUDE.md).

## License

MIT © [Adam Cherry](https://github.com/adam-cherry) — see [`LICENSE`](./LICENSE). Use it, fork it,
build on it.
