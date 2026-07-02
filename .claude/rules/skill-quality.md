# Directive: Skill Quality

## Rule

For **new custom skills**, always use the `skill-creator` skill (via `/skill-creator`). It ensures:

- An optimal description for triggering accuracy
- Correct frontmatter
- DRY: no duplication of CLAUDE.md or rules content
- A token-efficient structure

## Anti-patterns (avoid)

- Repeating API rules in skills (they belong in `.claude/rules/`)
- "Future Enhancements" sections
- Status/version/last-updated footers (git tracks that)
- More than 1 example per pattern
