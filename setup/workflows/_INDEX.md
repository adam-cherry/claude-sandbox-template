# Workflows Index

## Automatic Guards

| Workflow | Trigger | Scope | Output | Status |
|----------|---------|-------|--------|--------|
| Branch Guard | SessionStart, UserPromptSubmit | Session | Warning when on main | active |
| Pre-Commit Hook | git commit on main | Git | Direct commits to main blocked | active |
| Feature Branch Flow | Every change | Project | Squash merge via `/local-pr` | active |

## Skills (.claude/skills/)

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `onboarding` | `/onboarding`, "get started", "how do I set this up", first start | Guided first-time setup: hook, .env, plugins, Obsidian, gh CLI, git-flow, project.md |
| `looping` | `/looping <goal>`, "build X", "refactor Y", "roll this across the docs" | Goal-based engineering loop (research → plan → validate → execute → verify → review). GSD successor, code and content track. |
| `local-pr` | `/local-pr`, "done", "merge" | Feature branch → main (validated squash merge) |
| `break-glass` | `/break-glass`, "emergency" | Emergency commit to main (admin only) |
| `new-spike` | "new spike", "experiment" | Set up spike sandbox + docs |
| `debugging` | Bugs, errors, failures | Research-first debugging (root-cause, condition-based-waiting, defense-in-depth) |
| `python` | Python code, scripts | Python conventions |
| `docker` | Docker, Compose, containers | Docker/Compose best practices |
| `powershell` | PowerShell scripts | PowerShell automation best practices |
| `notebook` | Jupyter notebooks | Notebook execution + dependency handling |
| `release-tag` | `/release-tag`, "release", "tag" | Semver/date release tag + CHANGELOG |
| `where` | "where do we stand?", `/where` | Status: branch, tag, ahead/behind |
| `recommend` | "which skill/plugin", `/recommend` | Recommend the right skill/plugin/rule/agent |
| `update-context` | "update context" | Consolidate project context into a vNext snapshot |
| `promptify` | "build a prompt", "promptify" | Request → copy-paste-ready prompt |
| `gh-pm` | GitHub issue/project, "onto the board" | GitHub Issues + Projects (V2) via gh CLI |
| `team-update` | "team-update", "update for Slack/Teams" | Outcome-style update from git context |
| `screen-input` | "structure notes" | Raw notes → structured bullets |
| `excalidraw` | "architecture diagram", "excalidraw" | Diagrams as .excalidraw + PNG/SVG export |
| `html-presentation` | "slide deck", "reveal.js" | HTML slide deck from Markdown (reveal.js) |
