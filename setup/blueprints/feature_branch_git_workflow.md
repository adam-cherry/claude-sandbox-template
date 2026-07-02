# Blueprint: Model A+ Git Flow for Claude Code Projects (ff-only, 3-Branch)

Sets up a collaborative Git flow with fast-forward-only promotion and pre-commit protection in a Claude Code project.
Production-tested in a deploy repo with an external deployment chain.

> **Predecessor blueprint:** Model A++ (squash-merge) is deprecated. Model A+ fixes 4 structural pains of the squash-based workflow:
> 1. SHA divergence between source/target after every squash-merge
> 2. Silent deletion loss through auto-merge with `--theirs` conflict resolution
> 3. 3-branch SHA drift in multi-stage promotion
> 4. Skill complexity (override flags as symptom fixes)

---

## Result

- 3-branch model: `feature/*` (workbench) → `dev` (staging) → `main` (prod)
- `main` and `dev` are moved exclusively by `git merge --ff-only`
- Conflict resolution on the workbench via `git rebase origin/dev`, never on the deploy branches
- `/local-pr` skill: rebase + ff-only promotion (3 steps, 0 override flags)
- `/break-glass` skill: admin emergency, enforced mandatory resync `dev ← main` afterwards
- Pre-commit hook blocks non-ff-merges + non-merge commits on main
- Session hook automatically reminds about the feature branch
- Tags `release/YYYY-MM-DD` mark release points (workstream-agnostic)

---

## File Overview

```
.githooks/
└── pre-commit                 # Only hard blocker (Git level, MERGE_HEAD detection)

.claude/
├── hooks/
│   └── branch-guard.sh        # Session hook (info, no block)
├── rules/
│   ├── git-workflow.md        # Agent knowledge: Model A+ directive
│   └── worktree-policy.md     # Worktree rules (optional, when using agents)
├── skills/
│   ├── local-pr/SKILL.md      # rebase + ff-only promotion skill (3 steps)
│   └── break-glass/SKILL.md   # Admin emergency with mandatory resync
└── settings.json              # Hook registration
```

---

## Implementation Order (docs-first)

1. **Spec/docs first**: write `release-management-manual.md` or `git-workflow.md` — mental model + mechanics
2. `.githooks/pre-commit` — MERGE_HEAD detection
3. `.claude/rules/git-workflow.md` — agent directive
4. `.claude/hooks/branch-guard.sh` + `settings.json` — session hook
5. `.claude/skills/local-pr/SKILL.md` — 3-step ff-only
6. `.claude/skills/break-glass/SKILL.md` — mandatory resync
7. `.claude/rules/worktree-policy.md` (optional)
8. Add `CLAUDE.md` Git section
9. Add `README.md` onboarding
10. **Bootstrap sync** (only when migrating from Model A++): one-time `git push --force-with-lease=dev:<old-sha> origin origin/main:dev` to resolve the squash SHA divergence. Backup tag MANDATORY beforehand.
11. Live test: feature → dev → main with tag `release/YYYY-MM-DD`

---

## Step 1: Git pre-commit Hook

Create `.githooks/pre-commit` (executable):

```sh
#!/bin/sh
#
# pre-commit hook: Block direct/non-ff commits on main.
# Model A+ — main only accepts fast-forward merges (= no commits through this hook,
# because ff-only creates no merge commit). Any commit attempt here is therefore either
# direct-edit, non-ff-merge or squash — all three are forbidden.
#
# Allowed exceptions:
#   - --no-verify bypass (used by /break-glass skill, intentional)
#
# `dev` is allowed (Model A+ — fast dev loop, hotfix-friendly).
#
# Setup: git config core.hooksPath .githooks

branch=$(git branch --show-current)

if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  GIT_DIR=$(git rev-parse --git-dir)

  # Detect non-ff merge or squash merge attempt — both forbidden
  if [ -f "$GIT_DIR/MERGE_HEAD" ]; then
    echo ""
    echo "  BLOCKED: non-ff-merge or squash-merge on '$branch' is not allowed (Model A+)."
    echo ""
    echo "  Model A+ only allows fast-forward merges:"
    echo "    git checkout main"
    echo "    git merge --ff-only origin/dev"
    echo ""
    echo "  If ff-only fails: first rebase dev onto main,"
    echo "  then merge ff-only again."
    echo ""
    echo "  Emergency (outage): /break-glass (admin only, with --no-verify)."
    echo ""
    exit 1
  fi

  # No MERGE_HEAD = direct commit attempt → BLOCK
  echo ""
  echo "  BLOCKED: Direct commit on '$branch' is not allowed (Model A+)."
  echo ""
  echo "  Model A+ flow:"
  echo "    feature/<name>  ──/local-pr (rebase + ff)──►  dev  ──/local-pr (ff-only)──►  main"
  echo ""
  echo "  How to do it right:"
  echo "    1. git reset HEAD                               # Unstage staged files"
  echo "    2. git stash                                    # Save changes"
  echo "    3. git checkout dev && git pull origin dev      # Switch to dev"
  echo "    4. git checkout -b feature/<description>        # Create feature branch"
  echo "    5. git stash pop                                # Restore changes"
  echo "    6. git add . && git commit -m 'wip: ...'        # Commit on feature branch"
  echo "    7. /local-pr                                    # Rebase + ff-only into dev"
  echo "    8. /local-pr (on dev)                           # ff-only promotion dev → main"
  echo ""
  echo "  Emergency (outage): /break-glass (admin only, enforces dev-resync afterwards)."
  echo ""
  exit 1
fi

# dev and feature/* are allowed — no block.
exit 0
```

```bash
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
```

**Why MERGE_HEAD detection?** With `git merge --ff-only` NO merge commit is created (the target pointer is only fast-forwarded to the source HEAD). The pre-commit hook therefore does not fire at all during the ff-only operation. What it must block: any other `git commit` on main (direct, non-ff-merge, squash). MERGE_HEAD only exists during an active non-ff-merge — the perfect trigger.

---

## Step 2: Claude Session Hook

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
elif [ "$branch" = "dev" ]; then
  dirty=$(git status --porcelain 2>/dev/null)
  if [ -n "$dirty" ]; then
    echo "WARNING: You are on 'dev' with uncommitted changes."
    echo "Create a feature branch: git checkout -b feature/<description>"
  else
    echo "Branch: dev (hotfix-friendly — direct commits OK)"
  fi
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

Register in `.claude/settings.json`:

```json
{
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
  }
}
```

**Important**: This hook only informs — it does not block. The only hard blocker is the pre-commit hook.

---

## Step 3: Git Workflow Rule

Create `.claude/rules/git-workflow.md`:

```markdown
# Directive: Git Workflow

## Golden Rule

**Model A+ — feature → dev → main with fast-forward only.** Promotion via `/local-pr` (rebase + `git merge --ff-only`). Conflicts are resolved on the feature branch through rebase, never on dev/main.

```
feature/*  ──(rebase + ff-only)──►  dev  ──(ff-only)──►  main
                                     │                    │
                                     ▼                    ▼
                                PaaS-Dev          PaaS-Prod
                                (manual deploy)      (autoDeploy)
```

## Branch Convention

| Branch | Persistent? | Direct commit? | Protection |
|--------|-------------|----------------|--------|
| `feature/<name>` | no | yes, free (`wip:` ok) | — |
| `dev` | **yes** | allowed (hotfix-friendly) | — |
| `main` | **yes, protected** | **FORBIDDEN** (pre-commit hook blocks non-ff-merges + non-merge commits) | `.githooks/pre-commit` |

- Feature naming: `feature/<short-description>` (lowercase, hyphens)
- Promotion via `/local-pr` (rebase + ff-only) — manual `git merge --ff-only` only when the skill explicitly recommends it

## Session Start

1. Check the current branch
2. `feature/*` or `dev` → keep working
3. `main` → branch a feature off dev BEFORE work begins:
   ```bash
   git checkout dev && git pull origin dev
   git checkout -b feature/<description>
   ```

## Commits

- On `feature/*`: free, atomic or messy both ok, optionally `git rebase -i origin/dev` before promotion for cleaner history
- On `dev`: allowed for hotfixes; **Conventional Commits recommended**
- On `main`: **FORBIDDEN** as a direct commit; only `git merge --ff-only origin/dev` (orchestrated by the skill)

## Promotion Mechanics

Conflict resolution happens on the workbench, not on the deploy branch:

```bash
# Phase A — feature work
git checkout -b feature/<topic>
# atomic / messy commits, all ok

# Phase B — prepare promotion
git rebase origin/dev   # linearizes onto dev's HEAD; resolve conflicts here
make smoke-local         # green?

# Phase C — Promote feature → dev
git checkout dev
git merge --ff-only feature/<topic>
git push origin dev
make smoke-dev

# Phase D — Promote dev → main
git checkout main
git merge --ff-only origin/dev
git push origin main     # autoDeploy via webhook
make smoke-prd
git tag -a release/$(date +%Y-%m-%d) -m "<release-summary>"
git push origin release/$(date +%Y-%m-%d)
```

## Forbidden

- `git commit` on main (blocked by `.githooks/pre-commit`)
- Skipping `dev` (feature direct → main) — skill refuses
- `git push --force` on `dev` or `main`
- `git rebase` on `dev` or `main` (only allowed on the feature branch)
- `git merge --no-ff` or `git merge --squash` on dev/main — Model A++ legacy, no longer allowed
- Bypassing or disabling `.githooks/` files

## Emergency

`/break-glass` (admin only) bypasses the pre-commit hook for a direct commit on main.
**Mandatory afterwards:** `git checkout dev && git merge --ff-only main && git push origin dev` — otherwise dev and main diverge structurally.

## Onboarding

Every new user must run once:
```bash
git config core.hooksPath .githooks
gh auth login    # GitHub CLI: HTTPS, Login with web browser
git checkout dev # Default branch for work
git pull origin dev
```
```

---

## Step 4: /local-pr Skill (3-Step ff-only)

Create `.claude/skills/local-pr/SKILL.md`:

```markdown
---
name: local-pr
description: "Promotion between the branch stages: feature/* → dev (test) or dev → main (promotion). Model A+ — rebase + ff-only."
user_invocable: true
trigger: "When user wants to merge, finish work, local PR, ship to dev/prod, or says done."
allowed_tools:
  - Bash(git:*)
  - Bash(make smoke-*)
  - Read
---

# Local PR — Model A+ (ff-only)

Two-stage fast-forward promotion with rebase on the workbench:

```
feature/<name>  ──/local-pr──►  dev  ──/local-pr──►  main
   (rebase + ff-only)            (ff-only)
```

## Flow

### Step 1 — Pre-Flight + Rebase onto Target

- Detect the source branch:
  - `feature/*` → `TARGET=dev`
  - `dev` → `TARGET=main`
  - otherwise → ABORT
- The working tree MUST be clean, otherwise: "Please commit first"
- Check `gh auth status` — if not: `! gh auth login`
- `git fetch origin $TARGET` (MANDATORY)

**Rebase stage** (only when `TARGET=dev`):

```bash
git rebase origin/$TARGET
# On conflict: user resolves, then: git rebase --continue
```

When `TARGET=main` (source is `dev`): NO rebase needed — dev already has an ff relationship to main.

### Step 2 — Validation + Pre-Deploy Hooks

- No merge markers (`<<<<<<`) in files
- No secrets in changed files
- Show `git log --oneline $TARGET..HEAD` and `git diff --stat $TARGET`
- When `TARGET=main`: project-specific pre-deploy hooks (e.g. `make smoke-dev`, env-verify)

HARD BLOCK, no override flags. (Model A+ has no `--allow-drift`/`--skip-smoke`/`--no-reset`.)

### Step 3 — Fast-Forward Merge + Push

```bash
git checkout $TARGET
git merge --ff-only $SOURCE
```

If ff-only fails: the user must go back to the source and `git rebase origin/$TARGET` again. ABORT.

**Do NOT push automatically.** Inform the user of the next step.

**When TARGET=main** additionally recommend a tag:
```bash
git tag -a release/$(date +%Y-%m-%d) -m "<summary>"
git push origin --tags
```

## Forbidden

- Force-push on `dev` or `main`
- Skipping `dev` (feature direct to main)
- `git merge --no-ff` or `git merge --squash`
- Override flags — they do not exist in Model A+
```

---

## Step 5: /break-glass Skill (with Mandatory Resync)

Create `.claude/skills/break-glass/SKILL.md`:

```markdown
---
name: break-glass
description: "Emergency direct commit on main. Bypasses pre-commit hook. Admin only. ENFORCES dev←main resync after."
user_invocable: true
trigger: "When user explicitly asks for break-glass, emergency commit, or hotfix on main."
allowed_tools:
  - Bash(git:*)
  - Read
---

# Break Glass — Direct Commit on Main (with Mandatory Resync)

Emergency mechanism. Model A+ requires: after a direct commit on main, dev MUST be resynced, otherwise dev and main diverge structurally.

## Flow

### Step 1 — User Confirmation

Ask the user explicitly, noting the mandatory resync afterwards. Only continue on `yes`.

### Step 2 — Direct Commit (no auto-push)

```bash
git commit --no-verify -m "<user-supplied-message>"
```

The skill informs the user: "Push with `git push origin main`."

### Step 3 — Mandatory Resync (AFTER user push)

```bash
git checkout dev
git merge --ff-only main
git push origin dev
```

If `git merge --ff-only main` fails: ABORT with a note that dev has divergent commits.

### Step 4 — Tag (optional but recommended)

```bash
git tag -a release/$(date +%Y-%m-%d)-hotfix -m "<description>"
git push origin --tags
```

## Forbidden

- Direct push to main without dev resync
- Multiple break-glass commits in a row without push + resync in between

## When not to break-glass

- Routine hotfixes (~5min standard path): use `/local-pr` via feature/hotfix-x → dev → main
```

---

## Step 6: Worktree Policy (optional)

Only relevant when agents are used with `isolation: "worktree"`. Content unchanged from the Model A++ blueprint — the ff-only switch does not affect the worktree policy.

---

## Step 7: CLAUDE.md Git Section

```markdown
## Git Workflow — Model A+

**Three branches:** `feature/*` → `dev` → `main`. Promotion via `git merge --ff-only` (no squash).

```
feature/<name>  ──(rebase + ff-only)──►  dev  ──(ff-only)──►  main
                                          │                    │
                                          ▼                    ▼
                                     PaaS-Dev          PaaS-Prod
                                     (auto-deploy)        (auto-deploy)
```

**Golden Rule:** `dev` and `main` are moved exclusively by `git merge --ff-only`. Conflicts are resolved on the feature branch through `git rebase origin/dev`, never on the deploy branches.

```bash
# Onboarding (once after clone)
git config core.hooksPath .githooks
gh auth login
git checkout dev

# Start a feature
git checkout dev && git pull origin dev
git checkout -b feature/<short-description>
git add . && git commit -m "wip: ..."

# Test stage: feature → dev (rebase + ff-only)
/local-pr
git push origin dev

# Promotion: dev → main (ff-only, only when dev is green)
/local-pr
git push origin main
git tag -a release/$(date +%Y-%m-%d) -m "<summary>" && git push origin --tags

# Emergency: /break-glass (admin only) — direct commit + mandatory resync `dev ← main`
```

**Protection:** `.githooks/pre-commit` (MERGE_HEAD detection) · `.claude/hooks/branch-guard.sh` · `.claude/rules/git-workflow.md`
```

---

## Migration from Model A++ (squash) to Model A+ (ff-only)

If the project already has a squash workflow: a one-time bootstrap sync is needed, because dev and main are typically content-equivalent but SHA-divergent (squash generates new SHAs each time).

### Steps

1. **Diagnosis:** `git diff origin/main..origin/dev` — if 0 lines, they are content-identical.
2. **Backup tag:** `git tag pre-bootstrap-dev-$(date +%Y%m%d) <old-dev-sha> && git push origin --tags` — restore path.
3. **Force-sync:** `git push --force-with-lease=dev:<old-sha> origin origin/main:dev` — origin/dev jumps to origin/main HEAD. Zero content change. (User executed via `! cmd` if the harness blocks.)
4. **Local sync:** `git fetch origin && git checkout dev && git reset --hard origin/dev`
5. **First Model A+ promotion:** feature → dev (ff-only) → main (ff-only) → tag `release/YYYY-MM-DD`

### Risks / Mitigations

- ⚠️ Force-push on a shared branch → backup tag makes restore possible
- ⚠️ PaaS-Dev triggers re-deploy → idempotent if there is no code change
- ⚠️ Open feature branches sitting on old dev history → the devs must rebase (one-time friction)

---

## Architecture Decisions

### Why ff-only instead of squash?

Squash creates a new SHA on the target branch after every merge. Source and target diverge structurally even though the content is identical. Consequences:
1. The source branch accumulates useless commits (discipline-requiring reset recommendation)
2. `git diff dev..main` is never "what's coming in the next release" — but accumulated squash divergence
3. Conflict resolution happens on the deploy branches, not on the workbench
4. Deletions can get silently lost (auto-merge with `--theirs` treats "file exists only on one side" as no conflict)

ff-only solves all 4 problems structurally (through git's behavior), not through discipline.

### Why 3 branches instead of 2?

`feature → main` (GitHub Flow) is simpler, but `dev` as a staging layer pays off for:
- Pre-promotion smoke test against the dev deployment (catch issues before prod)
- Hotfix-friendly direct commits (iterate faster during outages)
- Auto-deploy trigger per env (PaaS pulls from a branch, not a tag — industry standard for Docker PaaS)

### Why MERGE_HEAD instead of SQUASH_MSG?

`git merge --ff-only` creates NO merge commit (the target pointer is only fast-forwarded). The pre-commit hook therefore does not fire — perfect, because ff-only is legitimate. What it must block: any other commit type on main. MERGE_HEAD only exists during an active non-ff-merge or squash — the exact trigger.

### Why rebase on feature, not merge?

`git rebase origin/dev` on the feature branch:
- Linearizes the branch history (no explicit merge commit)
- Conflicts are resolved on the workbench (where the mental context of your own changes is fresh)
- The result is ff-mergeable into dev (a clean pointer advance)

`git merge origin/dev` on feature would create merge commits that later prevent the ff-only push.

### Why gh auth login as a mandatory onboarding step?

`git fetch origin` over HTTPS fails silently without GitHub CLI auth. The local-pr skill checks `gh auth status` explicitly and gives a clear error message instead of failing silently.

### Why only ONE hard blocker (pre-commit)?

Tested and rejected: a PreToolUse hook that blocks `git commit` on main. Problem: stdin-based, cannot reliably read the context. One hard blocker (pre-commit, Git-native) + soft guidance (session hook + rule) is more robust than several blocking layers that get in each other's way.

---

## Reference Implementation

A deploy repo with an external deployment chain serves as the reference for Model A+:
- Quick/refactor docs — the switch itself (plan, verification, live-test trail)
- Release tag — Model A+ inauguration
- Issue doc — decisions + research
- Master docs (release management manual) — running ops standard
