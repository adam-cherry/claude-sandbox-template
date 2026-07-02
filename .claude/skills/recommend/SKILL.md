---
name: recommend
description: "Recommend the right skill/plugin/rule/agent for a given task. Reads .claude/skills, .claude/agents, .claude/rules and returns best match."
user_invocable: true
trigger: "When user asks 'which skill', 'what can I use for X', '/recommend', or seems unsure which tool fits."
allowed_tools:
  - Read
  - Glob
  - Grep
---

# Recommend — Skill/Plugin/Rule Discovery

## Steps

1. Capture the user task in 1 sentence
2. Read `.claude/skills/*/SKILL.md` via Glob — extract `description` + `trigger` frontmatter
3. Read `.claude/agents/*.md` via Glob — extract `description`
4. Read `.claude/rules/*.md` via Glob — read the title + golden-rule section
5. Matching: propose the top 3 by relevance to the user task
6. Per suggestion: name, trigger phrase, one-line rationale

## Output Format

```
For "<user-task>" I recommend:

1. /<skill-name> — <why it fits>
2. <agent-name> — <why it fits>
3. <rule-name> — <why it fits>
```

## Style

- At most 3 suggestions (not 10)
- If there is no clear match: "No existing skill matches clearly. Create one via /skill-creator?"
- No pro/con comparisons
