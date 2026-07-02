# Runbook: Agentic Project Setup

**Blueprint version:** 1.2.0

This runbook sets up a complete Claude Code Agentic Framework in a new OR existing repository. It is executed step by step by a Claude Code agent — automatic steps directly, manual steps as an instruction to the user.

**Production-tested in:** several internal repos (greenfield + brownfield)

**Version convention:** Every repo that instantiates this blueprint documents the instantiation in `setup/genes/agentic_project_structure.gene.md` (see `_gene_template.md`). On blueprint updates, genes follow the update checklist at the end of this document.

**Related blueprints:**
- `feature_branch_git_workflow.md` — in-depth description of the 3-stage Git flow (Model A++) for repos with an external deployment chain (preview deploys / separate dev and prod environments)

---

## Prerequisites

Before you start, check:

- [ ] Claude Code CLI installed (`claude` in the terminal)
- [ ] Git installed and configured
- [ ] GitHub CLI installed (`gh auth login` done)
- [ ] Node.js >= 18 (optional, for plugins/tooling)
- [ ] uv (optional, for the Python/notebook skills — `uv sync` / `uv run`)
- [ ] pipx (optional, for Graphify)

---

## Step 0: Brownfield-Detect

> Before the intake starts, check whether the repo is **empty (greenfield)** or **already populated (brownfield)**.
> Brownfield setups are the default case in practice.

### 0.1 Detection Checks

```bash
# Detect existing structures
test -f .gitignore && echo "gitignore: present (merge strategy needed)"
test -f .claude/settings.json && echo "settings.json: present (merge strategy needed)"
test -d .claude/skills/looping && echo "Looping: already included (Step 7 = confirmation only)"
test -f graphify-out/graph.json && echo "Graphify: already initialized (Step 8 reduced)"
test -f CLAUDE.md && echo "CLAUDE.md: present (extend instead of replace)"
test -d .loop && echo "Looping state: present (check running loops)"
git rev-parse --is-inside-work-tree 2>/dev/null && echo "Git: initialized (skip Step 2.1)"
```

### 0.2 Merge-vs-Replace Decision Matrix

| File | Greenfield | Brownfield |
|-------|------------|------------|
| `.gitignore` | Completely new from template | KEEP existing patterns, append the agentic block |
| `.claude/settings.json` | Completely new from template | Merge `enabledPlugins` + `hooks.UserPromptSubmit`, do not overwrite existing hooks |
| `CLAUDE.md` | From template Step 9 | Extend with sections, keep existing project context |
| `Looping` | Step 7 = confirmation only | Skill already lives in `.claude/skills/looping/` — no installer |
| `Graphify` | Run Step 8 | Only `graphify update .` if the graph is stale |
| `Git branches` | Create `main` | Do not change existing `dev`/`main` convention |

### 0.3 Brownfield Mandatory Notes

For every intentional deviation from the blueprint **for brownfield reasons**, document it later in `setup/genes/agentic_project_structure.gene.md` under "Intentional Variations" — with a reason.

---

## Step 1: Project Intake

> Before files are created, the agent must understand the project context.
> Ask these questions interactively, one after another.

### Mandatory Questions

**1. Project goal**
> What is the goal of this repo? (e.g. "IaC monorepo for Azure", "Python backend service", "React frontend app", "documentation operator")

**2. Tech Stack**
> Which technologies are used?
> - Programming languages (Python, TypeScript, Go, Terraform, ...)
> - Frameworks (FastAPI, React, Next.js, Django, ...)
> - Infrastructure (Docker, Kubernetes, Azure, AWS, ...)
> - Databases (PostgreSQL/Supabase, MongoDB, Redis, ...)

**3. Team context**
> - How many developers work on the repo?
> - Are there related repos that should be linked?
> - Which language for communication? (German/English)

### Optional Questions (as needed)

**4. Orchestration**
> Is an orchestrator used? (Temporal, n8n, none)

**5. API Testing**
> Is an API testing tool used? (Bruno, Postman, none)

**6. Additional integrations**
> Are there external services that should be connected via MCP? (Jira, Linear, Slack, Notion, ...)

---

## Step 2: Git Init + Root Files

> Create the repository skeleton.

### 2.1 Git Init (if there is no repo yet)

```bash
git init
git checkout -b main
```

### 2.2 `.gitignore`

Create `.gitignore` adapted to the tech stack from the intake. Always include:

```gitignore
# Environment
.env
.env.*
!.env.example

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp

# Claude Code (local)
.claude/settings.local.json
.claude/worktrees/
.claude-work/

# Graphify (generated)
graphify-out/

# Looping (state, local)
.loop/

# Dependencies (depending on stack)
__pycache__/
*.pyc
node_modules/
.venv/
venv/

# Links (symlinks to other repos — local)
setup/links/*
!setup/links/.gitkeep
```

> Add stack-specific patterns based on the intake (e.g. `.terraform/`, `dist/`, `build/`).

### 2.3 `.env.example`

```env
# === Template — copy to .env and fill in ===

# GitHub
GITHUB_TOKEN=

# (further keys based on the tech stack from the intake)
```

### 2.4 `.mcp.json`

```json
{
  "$schema": "https://raw.githubusercontent.com/anthropics/claude-code/main/packages/core/mcp-schema.json",
  "mcpServers": {}
}
```

> Never edit manually — always use `claude mcp add`.

### 2.5 `README.md`

```markdown
# {{PROJECT_NAME}}

{{Short description from intake}}

## Setup

1. Clone the repository
2. `cp .env.example .env` and fill in
3. `git config core.hooksPath .githooks`
4. `gh auth login`
5. See `setup/plugins/plugin_setup.md` for Claude Code plugin setup

## Development

Work only on `feature/*` branches. Merge into main via `/local-pr`.
```

### 2.6 `LICENSE`

> Ask the user which license (MIT, Apache 2.0, proprietary, none).

---

## Step 3: Claude Workspace Architecture

> Create the complete `.claude/` directory structure.

```bash
mkdir -p .claude/rules
mkdir -p .claude/skills
mkdir -p .claude/agents
mkdir -p .claude/commands
mkdir -p .claude/hooks
```

### 3.1 `settings.json`

```json
{
  "permissions": {
    "allow": [],
    "deny": []
  },
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/branch-guard.sh"
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "claude-mem@thedotmack": true,
    "context7@claude-plugins-official": true,
    "code-review@claude-plugins-official": true,
    "code-simplifier@claude-plugins-official": true,
    "claude-md-management@claude-plugins-official": true,
    "skill-creator@claude-plugins-official": true,
    "claude-api@anthropic-agent-skills": true,
    "github@claude-plugins-official": true,
    "git-workflow@netresearch-claude-code-marketplace": true,
    "github-project@netresearch-claude-code-marketplace": true,
    "andrej-karpathy-skills@karpathy-skills": true,
    "chrome-devtools-mcp@claude-plugins-official": true,
    "web-quality-skills@claude-plugins-official": true,
    "mcp-server-dev@claude-plugins-official": true
  }
}
```

> The `enabledPlugins` list is the core standard (v1.1.0: 15 plugins). Project-specific plugins (Supabase, Microsoft Docs, n8n, Terraform, Pydantic AI, Azure etc.) are added in Step 6 based on the tech stack.
>
> **New in v1.1 (4 plugins):**
> - `andrej-karpathy-skills` — behavioral guidelines against LLM coding pitfalls (Think Before Coding, Simplicity First, Surgical Changes). Repo-agnostic, universally useful.
> - `chrome-devtools-mcp` — browser debugging via DevTools Protocol. Today standard for every repo with a web UI or API tests.
> - `web-quality-skills` — Lighthouse / Core Web Vitals / A11y / SEO audits. Complementary to chrome-devtools-mcp.
> - `mcp-server-dev` — build + bundle MCP servers. Useful even when only consuming (understanding the patterns).

> **Hooks:** The `branch-guard` hook (UserPromptSubmit) is set here as a base. Graphify optionally adds a PreToolUse hook when used (Step 8). Looping brings no hooks.

---

## Step 4: Core Rules

> These core rules apply in EVERY project. Create them verbatim.

### 4.1 `.claude/rules/mcp-policy.md`

```markdown
# Directive: MCP Policy

## Golden Rule

**Do not build your own MCP servers.** Use existing packages/endpoints via `claude mcp add`.

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
|--------|-------|
| `claude mcp add` | Add a server |
| `claude mcp list` | All servers + health check |
| `claude mcp remove <name>` | Remove a server |

## Forbidden

- Do not write your own MCP servers (no Python, no Node wrapper)
- No `git clone` + `npm run build` workflows for MCP
- No manual REST wrappers when an MCP package exists

## Research Order

1. Official MCP endpoints of the provider (HTTP)
2. Search npmjs.com for `<service>-mcp` (stdio)
3. GitHub MCP server directories (modelcontextprotocol/servers, awesome-mcp-servers)
4. Only when nothing exists: check back with the user
```

### 4.2 `.claude/rules/skill-ecosystem.md`

```markdown
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
| Custom Skill | `.claude/skills/{name}/SKILL.md` | Markdown with frontmatter |
| Custom Agent | `.claude/agents/{name}.md` | Markdown with frontmatter |
| Plugin | Marketplace (global) | Via `/plugin install` |
| MCP Server | `.mcp.json` (local) | Via `claude mcp add` |

## Forbidden

- No `npx skills i` (creates the `.agents/` format)
- No OpenClaw / ClawHub
- No `.agents/` directory in the repo
- No `skills-lock.json`
```

### 4.3 `.claude/rules/skill-quality.md`

```markdown
# Directive: Skill Quality

## Rule

For **new custom skills**, always use the `skill-creator` skill (via `/skill-creator`). This ensures:

- Optimal description for triggering accuracy
- Correct frontmatter
- DRY: no duplication of CLAUDE.md or rules content
- Token-efficient structure

## Anti-Patterns (avoid)

- Repeating API rules in skills (they belong in `.claude/rules/`)
- "Future Enhancements" sections
- Status/Version/Last Updated footer (git tracks that)
- More than 1 example per pattern
```

### 4.4 `.claude/rules/persona-quality.md`

```markdown
# Directive: Persona Quality

## Rule

New persona agents must be created according to the **CO-STAR + TIDD-EC hybrid framework**.

## Mandatory Sections

| Section | Content |
|---------|--------|
| **Persona** | Name, role, situational grounding |
| **Competence & Blind Spots** | What is mastered, what is overlooked |
| **Speech Style** | Linguistic signature + 3 speech samples |
| **Emotional Triggers** | Situation → reaction (min. 4) |
| **Mode** | Review lens vs. execution mode |
| **Do / Don't** | 5-7 behavioral rules each |
| **Output Format** | Structured output |
| **Guardrails** | Boundaries and quality rules |

## Authenticity Principles

- **Bounded Competence**: the persona is NOT omniscient
- **Cognitive Blind Spots**: build in realistic biases
- **Strong Opinions**: real experts have clear preferences
- **Speech Samples > abstract descriptions**

## Anti-AI-Slop

- No balanced pro/con lists
- No diplomatic hedging
- No generic recommendations
- No omniscience
```

### 4.5 `.claude/rules/worktree-policy.md`

```markdown
# Directive: Worktree Policy

## When to use worktrees

Only when ALL conditions are met:
- 2+ agents run in parallel (same wave)
- Agents modify overlapping files
- Merge effort is smaller than waiting sequentially

## When NOT to use worktrees

- Single agents
- Parallel agents without file overlap
- After manual user changes

## Clean up after every wave

```bash
git worktree list
git worktree remove .claude/worktrees/<name> --force
git branch -D worktree-agent-<id>
```

## Anti-Patterns

- Worktree for every agent out of habit
- Leaving worktrees around after a merge
- Manual edits on main while worktree agents are running
```

### 4.6 `.claude/rules/conventional-commits.md`

```markdown
# Directive: Conventional Commits

## Golden Rule

**Commit messages follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/).** A dry run for later semantic-release tooling — today a manual discipline layer.

## Format

`<type>(<scope>): <description>` — body optional, footer for breaking changes.

## Types (mandatory)

| Type | When |
|------|------|
| `feat` | New user-visible feature |
| `fix` | Bug fix |
| `docs` | Docs only |
| `refactor` | Restructure without behavior change |
| `test` | Tests added/changed |
| `chore` | Tooling, maintenance, dependencies |
| `perf` | Performance optimization |
| `ci` | CI pipeline change |
| `build` | Build system (Makefile, Dockerfile) |

## Anti-Patterns

- `wip:` without a type on main/dev (ok on `feature/*`)
- Capitalized type (`Feat`, `FIX`) — exact lowercase
- Body missing on breaking changes
- Multiple types in one commit (`feat+fix(app):...`) — split them
- Commit message > 72 chars in the first line

## Discipline now = auto-tooling later

A pre-commit hook or semantic-release will automate the discipline later. Write it manually today — clean from day 1.
```

### 4.7 `.claude/rules/graphify-usage.md`

```markdown
# Directive: Graphify Knowledge Graph Usage

## Golden Rule

**The graph is a map, not a mirror.** It was built at a point in time and can become outdated. Always verify statements from the graph against the current code with `Read`/`Grep`.

## When to consult the graph

| Question type | Why the graph helps |
|----------|-------------------|
| Architecture overview | Communities + god nodes show structure without reading 50 files |
| Impact analysis | Edges show callers/importers without ripgrep over everything |
| Cross-cutting discovery | Edge type `imports`/`calls` filterable |
| Onboarding / mental model | Community clusters + top nodes |

## When NOT

- Current code content → `Read`/`Grep` directly
- Recent changes → `git log`/`git diff`
- Concrete values (configs, constants) → read the file
- After larger refactors without a rebuild → the graph is stale

## Staleness Check (mandatory)

`graphify status` before use. On `STALE`: either run `graphify update .` or skip the graph.

## Verification Requirement

After every answer that relies on graph data: verify the claim with `Read`/`Grep` before presenting it to the user. On a discrepancy: trust the code reality.
```

---

## Step 5: Git Workflow

> Protects `main` and establishes the feature branch convention. Two variants — the default is the simple 2-stage variant.

### 5.0 Decision Tree: Which Variant?

**Question 1:** Does this repo have an **external deployment chain** with separate dev and prod environments (preview branches, GitHub Actions deploy to 2 envs)?

| Answer | Variant | Branches |
|---------|----------|----------|
| **No** (default — applies to 80% of repos: library, tool, operator, internal repo) | **Variant A: 2-stage** | `main` + `feature/*` |
| **Yes** (applies to deploy repos, frontend-with-preview-deploys, etc.) | **Variant B: 3-stage Model A++** | `main` + `dev` + `feature/*`, ff-only |

**Variant A** is described in detail here. **Variant B** is fully documented in [`feature_branch_git_workflow.md`](feature_branch_git_workflow.md) (MERGE_HEAD hook, 3-step `/local-pr`, `/break-glass` with mandatory resync, bootstrap sync).

**Precedence (typical cases):**
- Repos with an external deployment chain (separate dev/prod environments): 3-stage Model A++
- Library, tool, operator or internal repos without a deployment chain: 2-stage (default)

The following snippets describe **Variant A (2-stage, default)**. For Variant B: jump to the Variant B block in Step 5.6.

### 5.1 `.githooks/pre-commit`

```bash
mkdir -p .githooks
```

Create `.githooks/pre-commit` (executable):

```sh
#!/bin/sh
#
# pre-commit hook: Block direct commits to main branch.
# Exception: squash-merge commits (SQUASH_MSG exists after git merge --squash)
#
# Setup: git config core.hooksPath .githooks

branch=$(git branch --show-current)

if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  if [ -f "$(git rev-parse --git-dir)/SQUASH_MSG" ]; then
    exit 0
  fi
  echo ""
  echo "  BLOCKED: Direct commit on '$branch' is not allowed."
  echo ""
  echo "  How to do it right:"
  echo "    1. git stash"
  echo "    2. git checkout -b feature/<description>"
  echo "    3. git stash pop"
  echo "    4. git add . && git commit -m 'wip: ...'"
  echo "    5. When done: /local-pr"
  echo ""
  exit 1
fi
```

```bash
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
```

### 5.2 `.claude/hooks/branch-guard.sh`

Create `.claude/hooks/branch-guard.sh` (executable):

```sh
#!/bin/sh
# UserPromptSubmit Hook: Check if user is on a feature branch

branch=$(git branch --show-current 2>/dev/null)
if [ -z "$branch" ]; then
  exit 0
fi

if echo "$branch" | grep -q '^feature/'; then
  echo "Branch: $branch"
else
  dirty=$(git status --porcelain 2>/dev/null)
  if [ -n "$dirty" ]; then
    echo "WARNING: You are on '$branch' with uncommitted changes."
    echo "Create a feature branch: git checkout -b feature/<description>"
  else
    echo "NOTE: You are on '$branch'. Create a feature branch before you start:"
    echo "  git checkout -b feature/<description>"
  fi
fi
```

```bash
chmod +x .claude/hooks/branch-guard.sh
```

### 5.3 `.claude/rules/git-workflow.md`

```markdown
# Directive: Git Workflow

## Golden Rule

**Main is protected.** No direct commit, no direct push to main.
Only way: the `/local-pr` skill (local PR with squash-merge).

## Branch Convention

- Work ONLY on `feature/*` branches
- Naming: `feature/<short-description>` (lowercase, hyphens)

## Session Start

Check at every new session:
1. Which branch am I on?
2. If `feature/*` → keep working
3. If `main` → create a feature branch BEFORE work begins
4. If `main` with a dirty tree → stash, feature branch, stash pop

## Commits

- On `feature/*`: free, `wip:` prefix allowed
- On `main`: **FORBIDDEN** — blocked by the pre-commit hook
- Conventional Commits on main mandatory (after squash-merge)

## Merge into Main

**ONLY via the `/local-pr` skill.** Manual merge is forbidden.

## Forbidden

- `git commit` on main (blocked by `.githooks/pre-commit`)
- `git push --force` on any branch
- `git rebase` on shared/remote branches
- Bypassing or disabling `.githooks/` files

## Onboarding

Every new user must run once:
```bash
git config core.hooksPath .githooks
gh auth login
```
```

### 5.4 `.claude/skills/local-pr/SKILL.md`

```markdown
---
name: local-pr
description: "Merge a feature branch into main via validated squash-merge. The only official way to land changes on main."
user_invocable: true
trigger: "When user wants to merge, finish work, local PR, or says done."
allowed_tools:
  - Bash(git:*)
  - Read
---

# Local PR — Feature Branch → Main

## Flow

### 1. Pre-Flight Check
- Branch MUST be `feature/*`, otherwise abort
- Working tree MUST be clean, otherwise: "Please commit first"
- Check `gh auth status`

### 2. Sync with Main
- `git fetch origin main` (MANDATORY)
- If main is ahead: `git merge origin/main`, resolve conflicts interactively

### 3. Validation
- No merge markers (`<<<<<<`) in files
- No secrets (.env, .key, .pem, credentials)

### 4. Commit Overview
- Show `git log --oneline main..HEAD` + `git diff --stat main`
- Have the user confirm

### 5. Squash-Merge
- `git checkout main`
- `git merge --squash feature/<name>`
- Clean commit: `<type>(scope): Description`
- Co-Authored-By footer

### 6. Wrap-Up
- Do NOT push automatically
- Do NOT delete the feature branch
- Show a summary
```

### 5.5 `.claude/skills/break-glass/SKILL.md`

```markdown
---
name: break-glass
description: "Emergency direct commit on main. Bypasses pre-commit hook. Admin only."
user_invocable: true
trigger: "When user explicitly asks for break-glass, emergency commit, or hotfix on main."
allowed_tools:
  - Bash(git:*)
  - Read
---

# Break Glass — Direct Commit on Main

Emergency mechanism. Deliberately bypasses the pre-commit hook.

## Flow

1. Ask the user explicitly: "Break Glass: direct commit on main. Are you sure?"
2. Only on confirmation: `git commit --no-verify -m "<message>"`
3. Do NOT push automatically
```

### 5.6 Variant B (3-stage, Model A++) — only with an external deployment chain

If the decision-tree question in 5.0 was answered with **Yes**:

1. **Skip** the snippets in 5.1-5.5 (they are written for Variant A)
2. Instead work through [`feature_branch_git_workflow.md`](feature_branch_git_workflow.md) — that is the complete Model A++ blueprint
3. `feature_branch_git_workflow.md` covers:
   - `.githooks/pre-commit` blocks direct commits on **dev AND main** (not just main)
   - `/local-pr` with rebase + ff-only (no squash)
   - `/break-glass` with mandatory resync afterwards (`dev → main` or `feature → dev`)
   - Bootstrap sync for migration from an existing squash convention

**Important note for the agent:** Do not mix the two variants. If Variant B was chosen, the rules + skills in 5.3/5.4/5.5 (Variant A) are to be replaced by the Variant B equivalents from `feature_branch_git_workflow.md` — not merged.

---

## Step 6: Marketplace Plugins

> ⚠️ MANUAL: The user must run these commands.

### 6.1 Register marketplaces (once per machine)

```bash
/plugin marketplace add anthropics/skills
/plugin marketplace add anthropic-agent-skills/skills
/plugin marketplace add thedotmack/claude-mem
/plugin marketplace add obra/superpowers
/plugin marketplace add netresearch-claude-code-marketplace/skills
/plugin marketplace add multica-ai/andrej-karpathy-skills
```

> Karpathy marketplace: https://github.com/multica-ai/andrej-karpathy-skills — behavioral guidelines.

### 6.2 Install plugins

The `enabledPlugins` in `settings.json` (Step 3.1) activate the plugins automatically on the next session start. If plugins are not loaded:

```bash
/plugin add
```

Interactively select the following:

| Plugin | Marketplace | Purpose | Core? |
|--------|-------------|-------|-------|
| superpowers | obra | Engineering skill set (TDD, plans, debugging, git worktrees) | Yes |
| claude-mem | thedotmack | Persistent memory across sessions (SQLite) | Yes |
| context7 | claude-plugins-official | Current library documentation (live, not training) | Yes |
| code-review | claude-plugins-official | Code review for PRs | Yes |
| code-simplifier | claude-plugins-official | Simplify & optimize code | Yes |
| claude-md-management | claude-plugins-official | Maintain & audit CLAUDE.md | Yes |
| skill-creator | claude-plugins-official | Create / test / benchmark skills | Yes |
| claude-api | anthropic-agent-skills | Claude API / Anthropic SDK help | Yes |
| github | claude-plugins-official | GitHub integration (issues, PRs) | Yes |
| git-workflow | netresearch | Branching, Conventional Commits, PRs | Yes |
| github-project | netresearch | Branch protection, GitHub Actions | Yes |
| andrej-karpathy-skills | karpathy-skills (multica-ai) | Behavioral guidelines: Think Before Coding, Simplicity First, Surgical Changes | Yes (v1.1) |
| chrome-devtools-mcp | claude-plugins-official | Browser debugging via DevTools Protocol (DOM, Network, Performance) | Yes (v1.1) |
| web-quality-skills | claude-plugins-official | Lighthouse, Core Web Vitals, A11y, SEO, performance audits | Yes (v1.1) |
| mcp-server-dev | claude-plugins-official | Build + bundle MCP servers (MCPB) | Yes (v1.1) |

### 6.3 Project-specific plugins (based on intake)

> Ask the user based on the tech stack:

| If the tech stack contains... | Recommend plugin | Marketplace |
|-----------------------------|------------------|-------------|
| Supabase / PostgreSQL | supabase | claude-plugins-official |
| Azure / Microsoft / .NET | microsoft-docs, azure-skills | claude-plugins-official |
| n8n | n8n-mcp-skills | n8n-mcp-skills |
| Terraform / IaC | terraform | claude-plugins-official |
| Pydantic AI Agents | pydantic-ai | claude-plugins-official |
| Analytics / Tracking | product-tracking-skills | claude-plugins-official |
| Playwright / E2E tests | playwright | claude-plugins-official |
| TypeScript-heavy | typescript-lsp | claude-plugins-official |

> Add recommended plugins to `settings.json` under `enabledPlugins`.
> Register the marketplace if new (e.g. `n8n-mcp-skills/n8n-mcp-skills`).

---

## Step 7: Looping (already included)

> Not an installer step. The `looping` skill already lives in `.claude/skills/looping/`.

**Looping** is this framework's goal-based engineering loop (replacement for GSD). It is already included as a skill — no `npx` installer, no `.planning/` tree, no separate SDK. Usage:

```
/looping <goal>
```

Looping runs a goal-driven plan-execute-verify loop and stores its state under `.loop/` when needed (gitignored). No additional commands, agents or hooks are needed — the skill encapsulates the entire loop.

> Nothing to install. In brownfield repos where `.claude/skills/looping/` already exists: leave it unchanged.

---

## Step 8: Graphify Knowledge Graph

> ⚠️ MANUAL: The user must run these commands — **unless Graphify is already installed** (see pre-check).

### 8.0 Pre-Check (brownfield safeguard)

```bash
if [ -f graphify-out/graph.json ]; then
  echo "Graphify already initialized"
  echo "→ Only 'graphify update .' if STALE"
  graphify status
else
  echo "Graphify not initialized — run Step 8.1"
fi
```

### 8.1 Installation (only if the pre-check says "not initialized")

```bash
# Once globally (if not yet installed)
pipx install graphify

# Per project
graphify claude install    # CLAUDE.md section + PreToolUse hook
graphify update .          # Initial graph build
```

Graphify creates:
- `graphify-out/graph.json` — knowledge graph
- `graphify-out/graph.html` — interactive visualization
- `graphify-out/GRAPH_REPORT.md` — god nodes + community structure
- PreToolUse hook in `settings.json` (Glob/Grep → graph hint)
- CLAUDE.md section with usage rules

> `graphify-out/` is in `.gitignore` — generated locally, not versioned.
> Discipline rule: see `.claude/rules/graphify-usage.md` (Step 4.7).

---

## Step 9: CLAUDE.md

> Generate `CLAUDE.md` based on the intake answers. Use this template:

```markdown
## Project Overview

**{{PROJECT_NAME}}** — {{Short description from intake}}

### Tech Stack

| Component | Purpose |
|------------|-------|
{{Table from intake answers}}

### Project Structure

```
{{Check the actual directory structure with `ls` and document it}}
```

## Development Rules

1. {{Project-specific rules based on tech stack}}
2. **Type hints** on all functions
3. {{Further rules as needed}}

## Custom Skills (`.claude/skills/`)

| Skill | Trigger | Purpose |
|-------|---------|-------|
{{Table of installed skills — filled in Step 10}}

## Conventions

- {{Communication language from intake}}
- Git prefixes: `feat` (new), `fix` (bugfix), `refactor` (restructure), `docs` (documentation), `test` (tests)

## Git Workflow

**Main is protected.** No direct commit/push. Work only on `feature/*` branches.

```bash
# Onboarding (once after clone)
git config core.hooksPath .githooks
gh auth login

# Create a feature branch
git checkout -b feature/<short-description>

# Merge into main: ONLY via the /local-pr skill
# Emergency: /break-glass (admin only)
```

**Protection**: `.githooks/pre-commit` (blocks commits on main) · `.claude/hooks/branch-guard.sh` (reminds about the feature branch) · `.claude/rules/git-workflow.md` (agent knowledge)

## Linked Repositories

{{If given in the intake — symlinks + description}}
```

> **Not in CLAUDE.md:** Generic dev tips, content that belongs in rules, file structures you can see with `ls`.

---

## Step 10: Custom Skills

> Create general standard skills (10.1) + project-specific skills (10.2).

### 10.1 General Standard Skills (universal, repo-agnostic)

These skills are useful in every repo — not stack-conditional:

| Skill | Trigger | Purpose | Already in v1.0? |
|-------|---------|-------|------------------|
| `local-pr` | `/local-pr`, "done", "merge" | Promotion feature → main (or dev in Variant B) | Yes |
| `break-glass` | `/break-glass`, "emergency" | Emergency direct commit + mandatory resync | Yes |
| `where` | `/where`, "where do we stand" | Single-command status: branch, tag, ahead/behind, top CHANGELOG | New in v1.1 |
| `team-update` | `/team-update`, "team-update for X", "colleague update" | Slack/Teams update in outcome style from git context | New in v1.1 |
| `release-tag` | `/release-tag` | Semver tag + CHANGELOG skeleton + push | New in v1.1 |
| `recommend` | `/recommend`, "which skill", "what can I use for X" | Recommends a fitting skill/plugin/rule for a task | New in v1.1 |
| `new-spike` | `/new-spike` | Spike setup (sandbox + docs) — for exploratory repos | Optional |

> **Important:** Do not write skills by hand — always use `/skill-creator` (see `.claude/rules/skill-quality.md`).
> Source for skill content: existing skills from a reference repo's `.claude/skills/` as a reference (adapt, do not copy — repo context changes).

### 10.2 Project-specific Skills (based on tech stack)

| If the tech stack contains... | Recommend skill | Purpose |
|-----------------------------|-----------------|-------|
| Python | `python` | uv-managed, type-first, Pydantic, pytest patterns |
| Docker / docker-compose | `docker` | Dockerfile best practices, Compose, health checks |
| PowerShell | `powershell` | Module conventions, error handling, Pester |
| Jupyter Notebooks | `notebook` | Execution, sys.path, formatting |

### 10.3 Creation Process

For each recommended skill from 10.1 and 10.2:

1. Ask the user: "Should I create the `{{skill-name}}` skill?"
2. If yes: create `.claude/skills/{{skill-name}}/SKILL.md` via `/skill-creator`
3. Add to the skills table in CLAUDE.md

> **Important:** Do not write skills by hand — always use `/skill-creator` (see `.claude/rules/skill-quality.md`).

### 10.4 Anti-Patterns: Do NOT generalize repo-specific skills

Examples of skills that are **deliberately repo-specific** and do not belong in the blueprint default:

| Skill (example) | Binding | Reason |
|------------------|---------|-------|
| `promote` | Deploy layer | Multi-stage promotion (dev+prd) is a deploy-layer pattern, not a generic pattern |
| `vm-audit` | Deploy layer | VM inventory is deployer domain |
| `secret-sync` | Deploy layer | Secret-store-specific, deploy layer |
| Personality skills | private (gitignored) | Not generally applicable |

When needed, these are used as an **inspiration template**, but not rolled out 1:1 via the blueprint.

---

## Step 11: Setup Meta Structure

> Create the `setup/` directory structure for project metadata.

```bash
mkdir -p setup/plugins
mkdir -p setup/workflows
mkdir -p setup/blueprints
mkdir -p setup/executions
mkdir -p setup/links
touch setup/links/.gitkeep
```

### 11.1 `setup/plugins/{{project}}_stack.csv`

```csv
name,type,category,purpose,access,status,notes
{{All active tools, plugins, skills from this setup as CSV rows}}
```

**Columns:** `name,type,category,purpose,access,status,notes`
**Type values:** `tool`, `plugin`, `skill`, `mcp`, `format`, `integration`
**Category values:** `local`, `operator`, `project`, `cloud`, `file`
**Status values:** `active`, `stage`, `planned`, `archived`

> Fill in based on all installed plugins (Step 6), skills (Step 10), and tools.

### 11.2 `setup/plugins/plugin_setup.md`

```markdown
# Plugin Setup Guide

Guide for setting up the Claude Code plugins for this project.

**Stack inventory:** `{{project}}_stack.csv` (source of truth)

## Prerequisite

Claude Code CLI installed and functional.

## For New Team Members

### Register marketplaces (once, global)

```bash
/plugin marketplace add anthropics/skills
/plugin marketplace add anthropic-agent-skills/skills
/plugin marketplace add thedotmack/claude-mem
/plugin marketplace add obra/superpowers
/plugin marketplace add netresearch-claude-code-marketplace/skills
{{further marketplaces if project-specific plugins}}
```

### Install plugins

The `.claude/settings.json` already brings `enabledPlugins`. After registering the marketplace:

```bash
/plugin add    # Select interactively
/reload-plugins
/plugin list   # Check that everything is active
```

### Standalone Tools

**Looping:** Already included as a skill (`.claude/skills/looping/`) — nothing to install. Usage: `/looping <goal>`.

**Graphify (optional):**
```bash
pipx install graphify
graphify claude install
graphify update .
```

## Scope Distinction

| Level | File | Versioned |
|-------|-------|-------------|
| Global | `~/.claude/settings.json` | No |
| Project (shared) | `.claude/settings.json` | Yes |
| Project (local) | `.claude/settings.local.json` | No |
```

### 11.3 ``

```markdown
# Workflows Index — {{PROJECT_NAME}}

## Workflows

| Workflow | Trigger | Scope | Output | Status |
|----------|---------|-------|--------|--------|
| Feature Branch Flow | Every code change | Project | Promotion via `/local-pr` (Model A+: rebase + ff-only, or simple variant: squash-merge) | active |
| Branch Guard | UserPromptSubmit | Session | Warning when on main | active |
| Pre-Commit Hook | git commit on main | Git | Commit blocked | active |

## Available Skills (.claude/skills/)

| Skill | Trigger | Purpose |
|-------|---------|-------|
| `local-pr` | `/local-pr`, "done", "merge" | Feature Branch → Main |
| `break-glass` | `/break-glass`, "emergency" | Emergency commit on main |
{{further skills from Step 10}}

## Available Agents (.claude/agents/)

{{Initially no project-specific agents — add as needed}}

## Important Paths

| Path | Content |
|------|---------|
| CLAUDE.md | Project context |
| setup/plugins/ | Stack documentation |
| setup/workflows/ | Workflow overview |
{{further paths}}
```

### 11.4 `setup/executions/hello_world.py`

```python
#!/usr/bin/env python3
"""Smoke Test — checks that the Python environment works."""

def main():
    print("Setup OK")

if __name__ == "__main__":
    main()
```

### 11.5 Linked Repositories (if given in the intake)

```bash
# Per linked repo
ln -s /absolute/path/to/repo setup/links/repo-name
```

> Do NOT commit symlinks. Only `setup/links/.gitkeep` is versioned.
> Document every symlink in CLAUDE.md.

---

## Step 11.5: Parallel Workstreams (optional)

> With multiple independent topics in one repo (e.g. frontend, backend and infra simultaneously), parallel workstreams can be run lightweight via feature branches and `looping`.

### 11.5.1 When needed

| Situation | Parallel stream? |
|-----------|------------------|
| Multiple parallel topics that touch different files and progress independently | **Yes** |
| Multiple Claude Code sessions simultaneously on different topics | **Yes** |
| Work that builds sequentially on each other | **No** — one loop, multiple steps |

### 11.5.2 Implementation

- One dedicated `feature/<topic>` branch per topic (see Step 5).
- Goal-driven work per stream via `/looping <goal>` — the loop keeps its state per stream under `.loop/`.
- Sketch larger, cross-cutting endeavors as a plan document under `.input/plans/` before individual loops are started.
- Isolate sessions that actually run in parallel and cannot share the same working tree via git worktrees (see `.claude/rules/worktree-policy.md`).

---

## Step 12: Smoke Test

> Check that everything is set up correctly.

### Automatic Checks

```bash
# Git hooks active?
git config core.hooksPath  # Expected: .githooks

# Pre-commit hook executable?
test -x .githooks/pre-commit && echo "OK" || echo "MISSING"

# Branch-guard hook executable?
test -x .claude/hooks/branch-guard.sh && echo "OK" || echo "MISSING"

# settings.json present?
test -f .claude/settings.json && echo "OK" || echo "MISSING"

# Core rules present?
for rule in mcp-policy skill-ecosystem skill-quality persona-quality worktree-policy git-workflow conventional-commits graphify-usage; do
  test -f ".claude/rules/$rule.md" && echo "$rule OK" || echo "$rule MISSING"
done

# Skills present?
test -f .claude/skills/local-pr/SKILL.md && echo "local-pr OK" || echo "MISSING"
test -f .claude/skills/break-glass/SKILL.md && echo "break-glass OK" || echo "MISSING"

# Looping skill included?
test -f .claude/skills/looping/SKILL.md && echo "looping OK" || echo "looping MISSING"

# Graphify graph built?
test -f graphify-out/graph.json && echo "Graphify OK" || echo "Graphify MISSING"

# CLAUDE.md present?
test -f CLAUDE.md && echo "CLAUDE.md OK" || echo "MISSING"
```

### Manual Checks

- [ ] Start a Claude Code session — are the plugins loaded?
- [ ] `/plugin list` — are all plugins active?
- [ ] Try to commit on main — is it blocked?
- [ ] Create a `feature/test` branch — is the branch-guard info shown?

---

## Summary: What Was Created

### Root Files
| File | Purpose |
|-------|-------|
| `.gitignore` | Ignore patterns (stack-specific) |
| `.env.example` | Environment template |
| `.mcp.json` | MCP server config (empty) |
| `README.md` | Project description + onboarding |
| `CLAUDE.md` | Master context for Claude Code |
| `LICENSE` | License |

### .claude/ Workspace
| Path | Content |
|------|--------|
| `settings.json` | Plugins, hooks, permissions |
| `rules/` | 8 core rules (mcp-policy, skill-ecosystem, skill-quality, persona-quality, worktree-policy, git-workflow, conventional-commits, graphify-usage) |
| `skills/local-pr/`, `skills/break-glass/` | Promotion + emergency (Variant A: squash-merge, Variant B: rebase + ff-only with mandatory resync) |
| `skills/where/`, `skills/team-update/`, `skills/release-tag/`, `skills/recommend/` | General standard skills (status, team communication, tagging, skill discovery) |
| `skills/looping/` | Goal-based engineering loop (already included, `/looping <goal>`) |
| `skills/{{...}}/` | Project-specific skills (stack-conditional from Step 10.2) |
| `hooks/branch-guard.sh` | Session hook (feature branch) |

### .githooks/
| File | Purpose |
|-------|-------|
| `pre-commit` | Blocks commits on main |

### setup/
| Path | Content |
|------|--------|
| `plugins/{{project}}_stack.csv` | Stack inventory (source of truth) |
| `plugins/plugin_setup.md` | Onboarding + plugin management |
| `workflows/_INDEX.md` | Workflow overview |
| `blueprints/` | If this repo itself hosts blueprints |
| `genes/agentic_project_structure.gene.md` | Lineage docs: which blueprint, which version, which variations (see `_gene_template.md`) |
| `executions/hello_world.py` | Smoke test |
| `links/` | Symlinks to related repos (not versioned, only `.gitkeep`) |

### External Tools (manually installed)
| Tool | Command |
|------|--------|
| Graphify (optional) | `pipx install graphify` + `graphify claude install` |
| 15+ marketplace plugins (v1.1) | 6 marketplaces + `enabledPlugins` in settings.json |

> **Looping** is not an external tool — the skill already lives in `.claude/skills/looping/`.

---

## Anti-Patterns

- **Hallucinated skills/commands** — only create when a concrete workflow exists
- **Duplicating rules in CLAUDE.md** — CLAUDE.md = context, rules = directives
- **Editing MCP manually in .mcp.json** — always `claude mcp add`
- **Committing .env** — belongs in .gitignore
- **Committing symlinks** — keep local, only track `setup/links/.gitkeep`
- **Generic dev tips in CLAUDE.md** — no "write clean code"
- **Skills without Skill Creator** — always use `/skill-creator`
- **`docker compose down -v` on data stacks** — irreversibly deletes all volumes/data
- **Keeping cold items in the stack** — remove what is not relevant

---

## Next Steps After Setup

1. **Initial commit** on the `feature/initial-setup` branch
2. **Create the gene file** in `setup/genes/agentic_project_structure.gene.md` based on `_gene_template.md`
3. `/local-pr` to merge (Variant A: main, Variant B: dev)
4. Start `/looping <goal>` for the first goal-driven work
5. Create project-specific skills via `/skill-creator`
6. Add MCP servers as needed via `claude mcp add`

---

## Changelog

### v1.2.0

**Engineering loop switched: Looping instead of GSD**

- **Step 7: Looping (already included)** — no installer anymore. The `looping` skill lives in `.claude/skills/looping/` and replaces GSD. No `.planning/` tree, no GSD commands/agents/hooks.
- **Rule `gsd-tooling.md` removed** — rules set reduced to 8 core rules.
- **Step 11.5 simplified** — parallel workstreams via feature branches + `/looping` + `.input/plans/` instead of GSD workstreams.
- **Skills table 10.2 slimmed down** — only the project-specific skills included in the template (`python`, `docker`, `notebook`, `powershell`).
- **Branding generalized** — company-/product-specific mentions replaced by neutral wording.

### v1.1.0 (2026-05-25)

**Broken back from productive genes into the blueprint:**

- **Step 0 (NEW): Brownfield-Detect** — merge-vs-replace now explicit
- **Step 5: Git workflow switched** — default = 2-stage (`main` + `feature/*`), 3-stage Model A++ as an option with a decision tree + reference to `feature_branch_git_workflow.md`
- **Step 8: Already-installed pre-check** — Graphify is no longer blindly reinstalled
- **Step 10: General skills added** — `where`, `team-update`, `release-tag`, `recommend` as standard (in addition to `local-pr`, `break-glass`)
- **Step 11.5 (NEW): Parallel workstreams**
- **Update checklist for genes** added
- **Gene template standardized** — see `_gene_template.md`

**Plugin list extended (4 new core plugins):**

- `andrej-karpathy-skills@karpathy-skills` (multica-ai) — behavioral guidelines
- `chrome-devtools-mcp@claude-plugins-official` — browser debugging
- `web-quality-skills@claude-plugins-official` — Lighthouse / Core Web Vitals / A11y
- `mcp-server-dev@claude-plugins-official` — MCP server development

**Rules set extended (2 new core rules):**

- `conventional-commits.md` — commit-format discipline (dry run for semantic-release)
- `graphify-usage.md` — knowledge-graph discipline (graph = map, not mirror)

### v1.0.0 (2026-04-21)

Initial version. Production-tested in several internal repos (brownfield).

---

## Update Checklist for Existing Repos

For every repo that already has an older gene:

1. **Pre-check**: `cat setup/genes/agentic_project_structure.gene.md | head -10` — the Blueprint Version is there
2. **Read the diff**: `git log --oneline setup/blueprints/agentic_project_structure.md` in the source repo
3. **Check variations**: hold the existing "Intentional Variations" section against the new changes — conflicts?
4. **Migrate incrementally**:
   - Add rules (`conventional-commits`, `graphify-usage`) if relevant; remove `gsd-tooling.md` if present
   - Activate core plugins (Karpathy, Chrome DevTools, Web Quality, MCP Server Dev) in `settings.json`
   - Create general skills (`where`, `team-update`, `release-tag`, `recommend`) via `/skill-creator`
   - Check the `looping` skill (`.claude/skills/looping/`); retire the earlier engineering loop (GSD)
5. **Update the gene file** (`_gene_template.md`): lineage bump, variation sub-tables, update checklist section
6. **Run the smoke test** (Step 12, current rules list)
