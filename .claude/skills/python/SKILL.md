---
name: python
description: "Python conventions for this operator: type hints on all functions, Pydantic for data models, pytest for tests, no print debugging."
user_invocable: false
trigger: "When editing or creating .py files in this repo."
allowed_tools:
  - Read
  - Write
  - Edit
  - Bash(python:*)
  - Bash(pytest:*)
---

# Python Conventions

## Required

- **Type hints** on all function signatures (always specify `-> ReturnType`)
- **Pydantic v2** for all data models (no `dataclass` except for internal performance)
- **pytest** for tests, never `unittest`
- **pathlib.Path** instead of `os.path` string manipulation
- **structlog** instead of `print` for logging
- **ruff** as linter/formatter — `pyproject.toml` config

## Anti-patterns

- `print(...)` for debugging in production code
- `from x import *`
- Untyped `**kwargs` without a TypedDict
- `try/except Exception:` without re-raise or logging
- Mutable default args (`def f(x=[])`)

## Test Convention

- Files: `tests/test_<module>.py`
- Function: `test_<scenario>_<expected>()`
- Fixtures in `tests/conftest.py`

## Tooling (uv)

Use [uv](https://docs.astral.sh/uv/) — not pip/venv directly. Deps live in `pyproject.toml`,
pinned in `uv.lock` (committed).

```bash
# Sync the environment (creates .venv, installs deps + dev group from pyproject.toml)
uv sync

# Add dependencies
uv add <package>          # runtime dependency
uv add --dev <package>    # dev tooling

# Run anything inside the project env (no manual activate)
uv run python script.py

# Lint + Format
uv run ruff check . --fix
uv run ruff format .

# Tests
uv run pytest -v
uv run pytest --cov=src --cov-report=term-missing
```
