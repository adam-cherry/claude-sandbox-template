---
name: promptify
description: Convert any user request into a copy-paste-ready, high-quality prompt. Also use when designing/refining prompts for new Claude agents, skills, or LLM workflows. Use when user asks to "build a prompt", "design an agent prompt", "make this prompt better", or "promptify this".
---

# Promptify

Turns a request into a production-ready prompt. Works for ad-hoc prompts AND for system prompts of new Claude agents/skills.

Input: $ARGUMENTS

## Phases

### 1. Intent & Context
- What is the real goal behind the request?
- Domain, target audience, usage context?
- Explicit requirements, implicit expectations, constraints?
- Missing critical info? → record it as assumptions and move on, do not ask back (unless absolutely blocking)

### 2. Quality Check
- Flag ambiguities / conflicts / unclear scope
- Classify complexity: simple / medium / complex
- Decide: work with defaults OR append 1-3 clarifying questions at the end

### 3. Prompt Design
Produce a prompt with:
- A clear role definition for the model
- A precise task definition
- A step-by-step method — only as many steps as needed
- Output requirements (format, depth, style)
- Constraints (length, tone, tools, "do not hallucinate", etc.)

Approach by use case:
- **Creative** → variation space, tone guidance, ideation structure
- **Technical** → precision, deterministic steps, validation rules
- **Strategic** → frameworks, trade-offs, decision logic
- **Complex** → break into sub-tasks with clear deliverables

## Special Case: Prompt for a Claude Agent / Skill

When the output becomes a **system prompt for a new agent or skill**:

1. Check existing conventions:
   - Personas → `.claude/rules/persona-quality.md` (CO-STAR + TIDD-EC, required sections)
   - Skills → `.claude/rules/skill-quality.md` (DRY, concise description, references instead of copies)
   - Skill ecosystem → `.claude/rules/skill-ecosystem.md`
2. Consult the `skill-creator` skill if not done already
3. Use existing agents/skills as a style template (`.claude/agents/`, `.claude/skills/`)
4. Set the frontmatter correctly (skills: only `name` + `description`; agents: `name`, `description`, `tools`, `model`)
5. Trigger the prompt-architect plugin (if installed) for style refinement — otherwise continue

## Output Format

```markdown
## [Prompt title]

### Optimized Prompt
<copy-paste-ready prompt block>

### Improvements (max 5)
- ...

### Variants (optional)
- Short / Detailed / Other language
```

For agent/skill prompts, additionally:
- Suggested location (`.claude/agents/<name>.md` or `.claude/skills/<name>/SKILL.md`)
- Suggested `description` (trigger-optimized)

## Rules

- No filler, no hype, no buzzwords
- Clarity and reusability > strict completeness
- Do not invent facts — state assumptions explicitly
- Style: `.claude/rules/writing-style.md`
