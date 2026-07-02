# Directive: Graphify Knowledge Graph Usage

## Golden Rule

**The graph is a map, not a mirror.** It was built at a point in time and can go stale. Always verify claims from the graph against the current code with `Read`/`Grep`.

## When to Consult the Graph

| Question type | Why the graph helps |
|----------|-------------------|
| Architecture overview | Communities + god-nodes show structure without reading 50 files |
| Impact analysis | Edges show callers/importers without ripgrep over everything |
| Cross-cutting discovery | Edge type `imports`/`calls` is filterable |
| Onboarding / mental model | Community clusters + top nodes |

## When NOT To

- Current code content → `Read`/`Grep` directly
- Recent changes → `git log`/`git diff`
- Concrete values (configs, constants) → read the file
- After larger refactors without a rebuild → the graph is stale

## Staleness Check (Required)

`graphify status` before use. On `STALE`: either run `graphify update .` or skip the graph.

## Verification Requirement

After every answer that relies on graph data: verify the claim with `Read`/`Grep` before presenting it to the user. On a discrepancy: trust the code reality.
