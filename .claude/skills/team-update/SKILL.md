---
name: team-update
description: "Generate an outcome-style Slack/Teams update from git context (last commits, merged feature branches, open work). Written in the project's language (see code-language.md)."
user_invocable: true
trigger: "When user asks for 'team-update', 'team update', '/team-update', or wants a written status for stakeholders."
allowed_tools:
  - Bash(git:*)
  - Read
  - Glob
---

# Team Update — Outcome-Style Status Message

Generates an update message from git context that names outcomes instead of activities.

## Flow

1. Determine the time window (default: last 7 days, overridable)
2. Read `git log --since="<window>" --pretty=format:'%h %s'`
3. Extract squash merges on main (= released features)
4. Read `Input/plans/AP_*.md` — status `final` as "done", `review` as "in QA", `draft` as "planned"
5. Structure the update:
   - **What was completed**: final APs + squash merges (outcome language)
   - **In progress**: APs in review + open feature branches
   - **Next week**: draft APs

## Output Format

```markdown
**Team Update <date> (<window>)**

**Done:**
- ...

**In progress:**
- ...

**Next week:**
- ...
```

## Style

- Name outcomes, not activities ("onboarding runbook live" instead of "5 commits on the onboarding doc")
- Write in the project's language (see `.claude/rules/code-language.md`)
- Max 3 bullets per section
- No internal paths in the public variant
