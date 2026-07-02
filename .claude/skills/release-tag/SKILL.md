---
name: release-tag
description: "Create a semver release tag with CHANGELOG entry. Default schema: release/YYYY-MM-DD (date-based) or vX.Y.Z (semver)."
user_invocable: true
trigger: "When user wants to '/release-tag', 'tag a release', 'cut a release', or finalize a milestone."
allowed_tools:
  - Bash(git:*)
  - Read
  - Edit
---

# Release Tag — Semver/Date Tag + CHANGELOG Skeleton

## Steps

### 1. Pre-Flight
- Branch MUST be `main`
- Working tree MUST be clean
- `git fetch origin --tags`

### 2. Choose the Tag Schema
- **Date-based** (default for the wiki operator): `release/YYYY-MM-DD`
- **Semver**: `vX.Y.Z` (let the user choose explicitly when relevant)

### 3. Create the Tag
```bash
git tag -a release/$(date +%Y-%m-%d) -m "<release summary from user input>"
```

### 4. CHANGELOG Skeleton (if CHANGELOG.md exists)

Insert an entry at the top:
```markdown
## release/<YYYY-MM-DD>
- <bullet from /team-update output, if available>
- ...
```

### 5. Wrap-Up
- Do NOT push automatically
- Inform the user: `git push origin --tags`

## Forbidden

- Tag on a feature branch
- Tag with a dirty working tree
- Auto-push (the user decides)
