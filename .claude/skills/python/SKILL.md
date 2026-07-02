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

## Tooling

```bash
# Install
pip install -e ".[dev]"

# Lint + Format
ruff check . --fix
ruff format .

# Tests
pytest -v
pytest --cov=src --cov-report=term-missing
```
