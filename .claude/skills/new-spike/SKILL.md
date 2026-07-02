---
name: new-spike
description: "Create a new spike experiment with sandbox folder, docs folder, and optional GSD workstream."
user_invocable: true
trigger: "When user wants to start a new spike, experiment, POC, or prototype."
---

# New Spike Setup

## Input

| Parameter | Description | Example |
|-----------|-------------|----------|
| `name` | Spike name (lowercase, hyphenated) | `data-pipeline` |
| `description` | Short description | "Explore a data pipeline approach" |
| `docker` | Docker setup needed? | yes/no |
| `port` | Base port (range 9000-9099) | 9010 |

## Creates

### 1. Sandbox Folder
```
sandbox/spike-{name}/
├── README.md          # Spike description, setup, results
├── docker-compose.yml # (only if docker=yes)
└── ...                # Spike-specific files
```

### 2. Docs Folder
```
docs/04_spikes/{name}/
└── overview.md        # Goal, approach, findings, decision
```

### 3. GSD Workstream (optional)
If GSD is installed: `/gsd-workstreams` → create a new workstream `{name}`.

## Conventions

- **Naming**: `spike-{name}` (sandbox), `{name}` (docs)
- **No production code** during a spike — exploration only
- **Unique ports**: each spike has its own ports (range 9000-9099)
- **Archiving**: once finished, update the spike docs with the decision
