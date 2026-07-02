# Directive: Release Quality

Applies to **release-ready, standalone artifacts** — docs, PDF exports, concept documents, anything that
goes to a jury, customers, or externally. Goal: a high, consistent quality bar without working-doc character.

## Golden Rule

A release document stands **on its own**. It reads like a human-written professional text —
not like a work-in-progress or interim state.

## 1. No Internal Source References in the Body

In running text and tables, do NOT include: `(Source: ...)`, paths like `Input/reviews|protocols|sources/...`,
transcript timecodes (`Marco ~47:17`, `Workshop 4 (...)`), people-as-evidence, `source conflict disclosed`.
Provenance lives in the frontmatter `sources:` and in change tracking — never in the document text. Internal
cross-references (`-> §6`, `see §9`) are allowed.

## 2. No Draft Markers in the Release

`[SOURCE MISSING: ...]` and `[OPEN: ...]` are **draft markers**. Before release: obtain the source and back up the
statement OR remove the statement. Real open items bundled and minimal in an "Open Items" section,
not scattered as markers throughout the text.

## 3. Natural Text, No Slop

Human-readable, as if for a jury. No meta-boilerplate ("What this section does / What's here /
What's NOT here"), no floods of parentheses, no filler sentences. Baseline: [[writing-style]].

## 4. One Canonical Diagram, Verbatim

A recurring diagram (e.g. the overview diagram) is defined ONCE and inserted **character-for-character identical**
in all sections — never redrawn per section (otherwise it diverges).

## 5. Don't Reset the Maturity Level

When revising, take the last clean state (e.g. the previous version in Git) as the baseline and apply only the
agreed deltas — don't regenerate (regeneration reproduces slop and hallucinations).

## 6. Simple, Not Over-Engineered

Build only what is asked for. No exhaustive auto-dumps, no overloaded tables/frameworks/personas.
When in doubt, the simpler variant.

## 7. Generation via Agents

Release content rework with an **Opus** executor (not Sonnet — reproducibly produces slop, source references, and
hallucinations), effort high. Provide shared diagrams verbatim instead of having each agent redraw them.
Adversarial final acceptance with grep for the prohibitions from (1)+(2).

## Relationship to the Provenance Rules

[[no-placeholders]] applies to the **creation process** (draft/review): there, check sources,
set `[SOURCE MISSING]`, track provenance. This rule applies to the **delivery state**:
provenance in frontmatter/change tracking, clean body. No contradiction — different maturity levels.
