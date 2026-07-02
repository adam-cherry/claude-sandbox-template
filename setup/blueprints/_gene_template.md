# Gene Template: Blueprint Instantiation

> This file is the **standard template** for gene files in repos that have instantiated a blueprint.
> On every blueprint instantiation, copy the block under "Template" to `<repo>/setup/genes/<blueprint-name>.gene.md`.
> Standardized as of Blueprint v1.1.0 (2026-05-25).

---

## Why Genes?

Genes document **which blueprint at which version** was rolled out in a repo — including lineage (commit SHA), intentional deviations, and the update path on blueprint bumps.

**Benefit:** When the blueprint changes, all genes can be checked systematically for updates — intentional variations are not accidentally reverted.

**Where the gene file lives:** A `setup/genes/` directory in the target repo. Each blueprint has a `*.gene.md` there.

---

## Template

```markdown
# Gene: <Blueprint Name in Titlecase>

## Lineage

| Field | Value |
|------|------|
| **Blueprint** | `<blueprint-name>.md` |
| **Blueprint Version** | `<x.y.z>` |
| **Blueprint Source** | `<source-repo>/setup/blueprints/<blueprint-name>.md` |
| **Blueprint Commit** | `<SHA>` (from the source repo, short form is fine) |
| **Generated on** | `YYYY-MM-DD` |
| **Generated for** | `<this-repo-name>` |
| **Implementation Plan** | `<optional: link to the plan file if present>` |

## Implemented Steps

| Blueprint Step | Status | Note |
|-------------------|--------|-------|
| 0. Brownfield-Detect | Done / Skipped (Greenfield) | <Which pre-check hits?> |
| 1. Project Intake | Done | <Stack summary in 1 line> |
| 2. Git Init + Root Files | Done | <Notable Modifications, e.g. ".gitignore extended not replaced"> |
| 3. Claude Workspace | Done | <Plugin count, hook modifications> |
| 4. Core Rules | Done | <X of 8 — which are missing + why> |
| 5. Git Workflow | Done | <Variant A (2-stage) or B (3-stage Model A++)> |
| 6. Marketplace Plugins | Done | <Number of core + stack-conditional> |
| 7. Looping (included) | Confirmed | <Skill present in .claude/skills/looping/?> |
| 8. Graphify | Done / Skipped / Pending | <Reason> |
| 9. CLAUDE.md | Done | <new / extended> |
| 10. Custom Skills | Done | <Number of skills, which general + which project-specific> |
| 11. Setup Meta Structure | Done | <Notable Modifications> |
| 11.5. Parallel Workstreams | Done / Not relevant | <if yes: which streams> |
| 12. Smoke Test | Done | <X/X checks passed> |

## Intentional Variations (deviating from the blueprint)

> Per variation: what the blueprint says, what this repo does, **why**.
> This list is the most important information during a later blueprint upgrade.

### Structure

| Topic | Blueprint | This Repo | Reason |
|-------|-----------|-------------|-------|
| <Example> | <Default> | <Variation> | <Why> |

### Skills

| Topic | Blueprint | This Repo | Reason |
|-------|-----------|-------------|-------|
| | | | |

### Plugins

| Topic | Blueprint | This Repo | Reason |
|-------|-----------|-------------|-------|
| | | | |

### Rules

| Topic | Blueprint | This Repo | Reason |
|-------|-----------|-------------|-------|
| | | | |

## Update Checklist

On a blueprint update from `<current-version>` to a newer version:

1. Read the diff: `git diff <old-version>..<new-version> -- setup/blueprints/<blueprint-name>.md` in the source repo
2. Identify new/changed steps
3. Check against "Intentional Variations" — keep variations, do not let them get lost due to the update
4. Adopt the relevant updates
5. Update this gene file: Blueprint Version, Blueprint Commit, "Implemented Steps" table
6. If a new intentional variation: add it to the appropriate table
```

---

## Standardization — what the template guarantees

| Element | Earlier genes (inconsistent) | This template |
|---------|--------------------------------|-----------------|
| Lineage header | Inconsistent (sometimes "Field", sometimes "## Lineage") | Consolidated under `## Lineage` |
| Variations section | Sometimes numbered, sometimes in tables | Four sub-tables: Structure, Skills, Plugins, Rules |
| Update checklist | Not present everywhere | Mandatory in every gene |
| Step 0 (Brownfield-Detect) | Previously not in the blueprint | Own row in "Implemented Steps" |
| Step 11.5 (Parallel Workstreams) | Previously not in the blueprint | Own row in "Implemented Steps" |

---

## Example Genes

- A data-stack gene (brownfield, 3-stage Git flow)
- An automation-stack gene (brownfield, 2-stage Git flow)

Older genes are lifted to the current template format on the next blueprint upgrade (update checklist item 5).
