---
name: update-context
description: "Consolidate project context into a vNext document. Reads recent APs, wiki updates, decisions and produces a single context-snapshot."
user_invocable: true
trigger: "When user says '/update-context', 'consolidate context', or after a milestone/release."
allowed_tools:
  - Read
  - Write
  - Glob
  - Bash(git:*)
---

# Update Context — Project Context Snapshot

Builds a consolidation document from the most recent APs + wiki updates for
onboarding new stakeholders or as a session reset point.

## Steps

### 1. Define the Time Window
- Default: since the last `release/*` tag
- Alternatively: user input

### 2. Gather Sources
- Glob `Input/plans/AP_*.md` — status `final` within the window
- Glob `wiki/**/*.md` — status `final`, `updated >= window-start`
- `git log --since="<window>"` — squash-merges on main
- `Output/qa/reports/*` — consolidate which reviewer perspectives were hot

### 3. Generate the Snapshot File
- Path: `wiki/01_management/context-snapshot-<YYYY-MM-DD>.md`
- Sections:
  - **What was documented** (wiki pages with status final, grouped by section)
  - **Which APs ran** (with a short description + source list)
  - **Which decisions were made** (from records within the window)
  - **Which reviewer topics recurred** (from QA reports)
- Frontmatter: `status: final` (a snapshot is final by definition)

### 4. Update the Wiki Index
- If present: add an entry to the table in `wiki/01_management/README.md`

### 5. Wrap-Up
- Inform the user: the snapshot can be used for onboarding sessions

## Forbidden

- A snapshot without a source list (every statement must be traceable to an AP/record/wiki page)
- Hot edits in old wiki pages — a snapshot is a read-only consolidation
