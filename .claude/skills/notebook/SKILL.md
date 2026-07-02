---
name: notebook
description: "Execute and manage Jupyter notebooks with correct dependency handling and sys.path setup."
trigger: "When user asks to run, create, or fix a Jupyter notebook."
---

# Jupyter Notebook Patterns

## Execution

```bash
.venv/bin/jupyter nbconvert --to notebook --execute <notebook>.ipynb
```

## Cell 1 Setup (required)

```python
import sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd().parent))
```

## Structure Rules

1. **Header cell** — title, purpose, date
2. **Setup cell** — sys.path, imports, config
3. **Step cells** — numbered, one logical step each
4. **Summary cell** — summarize the results

## Gotchas

- `sys.path` is REQUIRED when imports from the project root are needed
- Dependencies not in `requirements.txt`: install them in the setup cell
- Relative paths always from the notebook location
