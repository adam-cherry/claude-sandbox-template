---
name: local-pr
description: "Merge a feature branch into main via validated squash-merge. The only official way to land changes on main."
user_invocable: true
trigger: "When user wants to merge, finish work, local PR, or says done/fertig."
allowed_tools:
  - Bash(git:*)
  - Read
---

# Local PR — Feature Branch → Main

## Steps

### 1. Pre-Flight Check
- Branch MUST be `feature/*`, otherwise abort
- Working tree MUST be clean, otherwise: "Please commit first"
- Check `gh auth status`

### 2. Sync with Main
- `git fetch origin main` (REQUIRED)
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
- Clean commit: `<type>(scope): description`
- Co-Authored-By footer

### 6. Wrap-Up
- Do NOT push automatically
- Do NOT delete the feature branch
- Show a summary
