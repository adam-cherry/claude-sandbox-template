# Directive: No Placeholders

## Rule

No empty placeholders like `[TODO]`, `[TBD]`, `[PLACEHOLDER]`, `...` in final or review-status documents. Every placeholder MUST be concretely justified.

## Allowed

- `[TODO: clarify stakeholder list with Tim — by 2026-06-15]`
- `[SOURCE MISSING: number of active VMs in subscription X]`
- `[OPEN: which compliance requirement applies to legacy data?]`

## Not Allowed

- `[TODO]`
- `[insert text here]`
- `...`
- `[to be added]`

## When Information Is Missing

1. Search the repo's sources of truth (docs, code, specs, prior decisions/ADRs)
2. Check the upstream references the task points to
3. If still not found: set a concrete marker describing what is missing — don't guess

## In a Release

`[SOURCE MISSING]`/`[OPEN]` are draft markers and do NOT belong in a release-ready document. Before release:
provide evidence or remove; real open items bundled in an "Open Items" section, minimal. See [[release-quality]].
