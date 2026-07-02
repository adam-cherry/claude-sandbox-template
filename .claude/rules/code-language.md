# Directive: Code Language

## Rule

**Code is English.** Docstrings, comments, variable names, function names, YAML descriptions, schema descriptions, log messages, error messages — everything in English.

## Scope

- Python scripts (`*.py`)
- Script metadata (`*.script.yaml`)
- Flow definitions (`*.flow.yaml`, `flow.yaml`)
- Tests (`test_*.py`)
- Config files with descriptions

## Exceptions

- `CLAUDE.md`, rules, skills, docs — stay in the project language
- Git commit messages — English (Conventional Commits)
- Obsidian Vault (`docs/`) — project language allowed

## Anti-patterns

- Docstrings in the project language inside Python code
- Mixed languages in a single file (half project language, half English)
- Non-English YAML descriptions in tool/job metadata
- Transliterated umlauts in code (`ue`, `ae`, `oe` instead of real umlauts — avoid both)
