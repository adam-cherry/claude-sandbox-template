---
name: gh-pm
description: Manage GitHub Projects (V2 boards) and Issues for this repo's GitHub project via the gh CLI. Use whenever the user wants to create, edit, assign, label, close, or delete GitHub Issues, or add/move/update cards on a GitHub Project board, set board status/fields, or list board items. Triggers on "GitHub Issue", "GitHub Project", "Projects board", "gh issue", "gh project", "create/assign/close issue", "onto the board", "set status to Done/In Progress", "move card", or any task/board/sprint/Epic reference.
---

# GitHub Project Management (gh CLI)

Manages **GitHub Issues** + **GitHub Projects V2 (boards)** of this repo via `gh`. Org/owner, repo, and board number come from the project configuration or are determined live via `gh` — not hardwired.

## Determine context (live, re-read on drift)

| Fact | How to determine |
|------|---------------|
| Owner (org or user) | `gh repo view --json owner --jq '.owner.login'` or from `<owner>/<repo>` of the current repo |
| Account | `gh auth status` — the active account needs scopes `repo` + `project` (both required). Another account logged in in parallel may NOT see an org. |
| Issues repo | Default = current repo (`<owner>/<repo>`). For a different target, set `--repo <owner>/<repo>` explicitly. |
| Active board | `gh project list --owner <owner>` — board number `<project-number>` from it |
| Project ID | `gh project view <project-number> --owner <owner> --format json --jq '.id'` (e.g. `PVT_xxx`) |

> **Provenance:** Board/field/option IDs come from `gh project field-list <project-number> --owner <owner> --format json`. IDs can change — on `INVALID` errors or a new field, re-read first, don't guess. The `field-list` output is the single source of truth for IDs.

## Pre-Flight

```bash
gh auth status 2>&1 | grep -i scope          # 'project' must be included
gh auth switch --hostname github.com --user <account>   # if another account is active
```

If `project` is missing: the user must run `gh auth refresh -h github.com --scopes project` themselves (interactive device login). Only then do `gh project` commands work.

Pass `--owner <owner>` on EVERY `gh project` command — otherwise, for an org, the empty personal scope applies.

## Issues

| Task | Command |
|---------|--------|
| Create | `gh issue create --title "…" --body "…" [--label … --assignee @<assignee> --milestone …]` |
| List/search | `gh issue list --search "…" --state open` |
| View | `gh issue view <nr> [--comments]` |
| Edit | `gh issue edit <nr> --title/--body/--add-label/--add-assignee/--milestone` |
| Comment | `gh issue comment <nr> --body "…"` |
| Close/reopen | `gh issue close <nr> [--reason completed]` · `gh issue reopen <nr>` |
| Delete | `gh issue delete <nr> --yes` (irreversible — confirm before executing) |

Labels in the repo may be only the GitHub defaults (`bug`, `documentation`, `enhancement`, `question`, …). If there is still **no** project-specific WP/Epic/Sprint label scheme — clarify with the user which convention should apply before inventing a scheme.

## Projects V2 (Boards)

| Task | Command |
|---------|--------|
| List boards | `gh project list --owner <owner>` |
| View board | `gh project view <project-number> --owner <owner> [--web]` |
| Create | `gh project create --owner <owner> --title "…"` |
| Rename/visibility | `gh project edit <project-number> --owner <owner> --title "…" --visibility ORG` |
| Close/delete | `gh project close <project-number> --owner <owner>` · `gh project delete <project-number> --owner <owner>` |
| Issue/PR to board | `gh project item-add <project-number> --owner <owner> --url <issue-url>` |
| Draft card | `gh project item-create <project-number> --owner <owner> --title "…" --body "…"` |
| Read items | `gh project item-list <project-number> --owner <owner> --format json` |
| Remove item | `gh project item-delete <project-number> --owner <owner> --id <item-id>` |
| Create field | `gh project field-create <project-number> --owner <owner> --name "…" --data-type SINGLE_SELECT --single-select-options "A,B,C"` |

## Setting fields/status — the stumbling block

`item-edit` needs **IDs, not names**: project ID, item ID, field ID. Read first, then set.

```bash
# 1. Get IDs
gh project field-list <project-number> --owner <owner> --format json   # Field IDs + option IDs
gh project item-list <project-number> --owner <owner> --format json    # Item IDs

# 2a. Single-select (Status, Size)
gh project item-edit --project-id <project-id> --id <ITEM_ID> \
  --field-id <FIELD_ID> --single-select-option-id <OPTION_ID>

# 2b. Iteration (Sprint)
gh project item-edit --project-id <project-id> --id <ITEM_ID> \
  --field-id <ITERATION_FIELD_ID> --iteration-id <ITER_ID>
```

### Reading field IDs

Field IDs and option IDs are unique per board and change on a board rebuild. Always pull them fresh from `gh project field-list <project-number> --owner <owner> --format json` — don't hardcode. Typical fields:

| Field | Type |
|------|-----|
| Status | Single-select (options e.g. Planned / Ready / In progress / Blocked / Done) |
| Priority | Single-select (options may not be configured yet) |
| Size | Single-select (options e.g. XS / S / M / L / XL) |
| Iteration | Iteration (sprints, may not be created yet) |

If a built-in field like **Priority** exists without options: create the options once in the UI or via GraphQL, then re-read the IDs. **Iteration/sprints** must also be configured first (see iteration mechanics below).

## Iteration field mechanics (createProjectV2Field / updateProjectV2Field)

Iteration fields can only be created/populated via GraphQL:

```graphql
mutation {
  createProjectV2Field(input: {
    projectId: "<project-id>"
    dataType: ITERATION
    name: "Sprint"
  }) {
    projectV2Field { id }
  }
}
```

Add an iteration to the existing field:

```graphql
mutation {
  updateProjectV2IterationField(input: {
    projectId: "<project-id>"
    fieldId: "<ITERATION_FIELD_ID>"
    iterations: [{ startDate: "2026-07-01", duration: 14, title: "SP-001" }]
  }) {
    projectV2Field { id }
  }
}
```

**ITERATION FIELD WARNING:** `updateProjectV2Field` without an `iterations` argument is a **FULL REPLACE** — all existing iterations are deleted. Create new iterations via the GitHub UI or add them targeted via `updateProjectV2IterationField`, never overwrite blindly via CLI. **Always read first, then add in a targeted way.**

## Sub-issue mechanics (parent → child)

Sub-issues **exclusively** via GraphQL — `gh issue edit` has no sub-issue option:

```bash
gh api graphql -f query='
  mutation {
    addSubIssue(input: { issueId: "<PARENT_NODE_ID>", subIssueId: "<CHILD_NODE_ID>" }) {
      issue { id }
    }
  }
'
```

Get node IDs (not the issue number) via:

```bash
gh issue view <nr> --json id --jq '.id'
```

**WARNING auto-add-sub-issues workflow:** If a board has a workflow that automatically pulls sub-issues onto the parent issue's board, duplicates arise in cross-board constellations. Remove the duplicate **manually** via `gh project item-delete` or disable the workflow in the board settings. (Not an issue with a single board — only relevant once further boards are added.)

**The parent-issue field is read-only** in the GitHub UI and via the API — only `addSubIssue`/`removeSubIssue` control the link, not `updateIssue`.

## Date fields (limitation)

`Start date` and `Target date` are **issue-level fields** in GitHub Projects — they cannot be set via `updateProjectV2ItemFieldValue`. If timeline tracking is needed: use the iteration field as a timeline, maintain the date fields manually in the UI.

## GraphQL fallback

What `gh project`/`gh issue` don't cover (multiple views, workflow automations, sub-issue linking): `gh api graphql -f query='…'` with the ProjectV2 API. Only fall back to this when no ready-made command exists.

## Conventions

- **Announce write actions, confirm deletions** — `issue delete` / `project delete` are not reversible.
- **Repo reference:** Issues on the current repo (`<owner>/<repo>`); for a different target repo, set `--repo <owner>/<repo>` explicitly.
- **Style:** Issue titles/bodies per the project writing convention. Code/paths/IDs stay ASCII. (This SKILL file itself uses ASCII umlauts per the repo convention.)
