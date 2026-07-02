---
name: where
description: "Show repo status in one shot: current branch, latest tag, ahead/behind main, top of CHANGELOG if present."
user_invocable: true
trigger: "When user asks 'where are we', 'wo stehen wir', '/where', or wants a quick status overview."
allowed_tools:
  - Bash(git:*)
  - Bash(cat:*)
  - Bash(head:*)
  - Read
---

# Where — Single-Command Repo Status

Returns in one shot: current branch, latest release tag, distance to main, top CHANGELOG entry.

## Steps

1. `git branch --show-current` — current branch
2. `git describe --tags --abbrev=0` — latest tag (if any)
3. `git rev-list --left-right --count main...HEAD` — ahead/behind main
4. `git log -1 --pretty=format:'%h %s (%cr)' HEAD` — latest commit
5. If `CHANGELOG.md` exists: show the top entry

## Output

Short form, max 8 lines. Example:

```
Branch:     feature/example-topic
Tag:        release/2026-05-20 (7 days ago)
Ahead/Behind main: 3 / 0
Last:       a1b2c3d feat(wiki): add onboarding runbook (2h ago)
```
