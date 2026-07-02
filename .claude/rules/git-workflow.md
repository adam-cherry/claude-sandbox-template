# Directive: Git Workflow

## Golden Rule

**Main is protected.** No direct commit, no direct push to main.
The only way: the `/local-pr` skill (local PR with squash merge).

## Branch Convention

- Work ONLY on `feature/*` branches
- Naming: `feature/<short-description>` (lowercase, hyphenated)

## Session Start

At the start of every new session, check:
1. Which branch am I on?
2. If `feature/*` → continue working
3. If `main` → create a feature branch BEFORE starting work
4. If `main` with a dirty tree → stash, feature branch, stash pop

## Commits

- On `feature/*`: free, `wip:` prefix allowed
- On `main`: **FORBIDDEN** — blocked by the pre-commit hook
- Conventional Commits required on main (after squash merge)

## Merge to Main

**ONLY via the `/local-pr` skill.** A manual merge is forbidden.

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
