---
name: onboarding
description: >-
  Guided, step-by-step first-run setup for this Claude Code sandbox template. Walks a new user
  from a fresh clone to fully productive in a few minutes: activates the git hook, creates .env,
  verifies the auto-loading plugins (and fixes them if they error), explains the protected git
  flow, sets up the optional pieces (gh CLI, Obsidian vault in docs/), fills in project config,
  and points to the looping engine. Idempotent — detects what is already done and skips it. Use
  when the user just cloned/opened this template, types "/onboarding", asks "how do I set this
  up", "get started", "how do I use this", "what do I need to set up", or when plugins show
  "✘ error" and they want a walkthrough. Fire this before doing project work in a fresh sandbox.
---

# Onboarding — get this sandbox to 100% in a few minutes

Run this the first time you open the template. It is a **guided, interactive** flow: do each
step, confirm, move on. Everything is idempotent — if a step is already done, say so and skip it.
Keep it light: **only the git hook + `.env` are required**; the rest is optional and clearly
marked. Speak the user's language; default to concise, friendly, one step at a time.

Work through the steps in order. After each, show a one-line ✓/→ status and continue.

## Step 1 — Required: activate the git hook

Protects `main` from direct commits (see `.claude/rules/git-workflow.md`).

```bash
git config core.hooksPath .githooks
```

Verify: `git config core.hooksPath` returns `.githooks`. → ✓ "main is now protected."

## Step 2 — Required: create your `.env`

```bash
test -f .env || cp .env.example .env
```

Tell the user `.env` is gitignored and holds secrets (see `.claude/rules/secrets-guardrails.md`).
Ask if they want to fill in `GITHUB_TOKEN` / `ANTHROPIC_API_KEY` now or later (both optional to start).

> Steps 1–2 are exactly what `make setup` does. If they already ran `make setup`, confirm and skip.

## Step 3 — Verify the plugins load

The plugin ecosystem is **pre-configured and auto-loads** via `extraKnownMarketplaces` +
`enabledPlugins` in `.claude/settings.json` — no manual `/plugin marketplace add` needed
(full list + sources: `setup/plugins/plugin_setup.md`).

Ask the user to run `/plugin` (or check the startup banner). Three cases:
- **All green** → ✓ done, move on.
- **Some "✘ error"** → the marketplaces likely need one refresh. Have them run `/reload-plugins`
  (or restart Claude Code). If still failing on an old Claude Code build, walk through the manual
  `/plugin marketplace add ...` fallback in `setup/plugins/plugin_setup.md`.
- **They don't need all of them** → point out they can trim `enabledPlugins` in settings.json.

Do **not** overwhelm — name the 3-4 they'll use first: `superpowers`, `claude-mem`, `context7`,
`skill-creator`.

## Step 4 — Optional: GitHub CLI

Needed only for the `gh-pm` skill and `github-project` plugin (Issues / Projects / PRs).

```bash
gh auth status   # already logged in?
```

If not and they want it: `gh auth login`. If they don't use GitHub yet, skip — the template
works fine without it.

## Step 5 — Optional: Obsidian for docs/

`docs/` is a ready-to-use **Obsidian vault** (numbered structure, ADR template, `.obsidian`
config already committed). It is also plain Markdown — Obsidian is a nice-to-have, not required.

If they use Obsidian: open Obsidian → "Open folder as vault" → select the `docs/` folder.
Per-machine state (`workspace.json`, `cache`) is gitignored; the vault config travels with the repo.
Explain the layout briefly: `00_project/` context, `01_adr/` decisions, `02_specs/`, `03_help_desk/`.

## Step 6 — Understand the git flow (30 seconds)

Explain, don't run:
- `main` is protected; you work on `feature/*` branches.
- Land changes with **`/local-pr`** (validated squash-merge) — the only official way onto `main`.
- Emergency direct commit: `/break-glass` (admin only).
- Status any time: `/where`.

## Step 7 — Fill in project config

Open `.claude/config/project.md` and ask the user for: project **name**, **type**
(e.g. Python backend / React app / docs), and **language** (German/English). Fill the placeholders.
This is the single source of truth skills read from — keep it accurate.

## Step 8 — Confirm setup

```bash
make smoke-test   # or: bash setup/executions/smoke_test.sh
```

Expect `SMOKE TEST: PASS`. → ✓ "You're set up."

## Done — what to do next

Wrap up with a short, encouraging summary of what's ready and one concrete next action:

> You're ready. The core engine is **`/looping <goal>`** — it turns a goal into a merge-ready
> feature branch (research → plan → validate → execute → verify → review) instead of editing
> blindly. Try it on your first task, or run `/recommend` to find the right skill for what you
> want to do.

Keep the whole flow tight — a new user should feel productive, not audited.
