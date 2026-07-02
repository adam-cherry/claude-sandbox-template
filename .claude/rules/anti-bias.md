# Directive: Anti-Bias

Active for: architecture decisions, assessment results, ADR drafts, technology recommendations, structuring questions.

## Known Bias Patterns

### 1. People-Pleaser Effect

The operator confirms the user's architecture or technology decisions instead of questioning them. Quick agreement without checking sources.

**Countermeasure:** For architecture and technology decisions, always steelman the opposing position first before agreeing. Agreement in the first response without checking sources is a warning sign. At least one critical follow-up question or trade-off list.

### 2. Reliance on the Current State

Infrastructure described verbally is treated as verified knowledge — without IaC or a protocol as evidence.

**Countermeasure:** Before any statement about the current state, check:
- Is there IaC code as evidence? (`Input/code/`)
- Is there a protocol that confirms it? (`Input/protocols/`)
- If not: mark it with `[SOURCE MISSING: ...]`, do not state it as fact

### 3. Sunk Cost on Existing ADRs

Existing ADRs are defended too strongly because work went into them — not because the rationale still holds. Especially risky for ADRs made before concrete operational experience.

**Countermeasure:** For every revision proposal, check — was the ADR made with or without operational experience? Without: it is a hypothesis, not a fact. New findings from protocols or code can supersede it.

### 4. Echo Chamber

Wiki pages are built on what was said in conversation — without validating against actual sources. Internal assumptions are treated as facts.

**Countermeasure:** Every statement in a wiki page needs at least one external source reference. "Mentioned in conversation..." is not evidence — a `sources:` entry in the frontmatter with a concrete file is more like it.

### 5. Confirmation Bias

Signals that support the preferred architectural direction are overweighted. Risks or counterarguments are ticked off as "considered" but not built into the ADRs.

**Countermeasure:** For every ADR draft, an explicit "Contra" section. Not just pro arguments, but the strongest arguments against the chosen option — documented on equal footing.

### 6. Complexity Bias

Simple matters are unnecessarily complicated. Documentation sections, governance frameworks, and personas are stacked on top of each other until the added value over a simple table is unclear.

**Countermeasure:** After every synthesis, run the "reading test": would a stakeholder understand in 30 seconds what is documented and what the next action is? If not: simplify. Tables > prose, bullet points > paragraphs.

### 7. Completeness Illusion

Sections are phrased as if the topic were fully covered — even when only partial sources exist. Gaps are filled with plausible-sounding assumptions instead of being marked.

**Countermeasure:** Explicitly flag sections based on incomplete sources. Better an honest `[SOURCE MISSING: <topic>]` than a confident false statement. See [[no-placeholders]].

## Operational Rules

1. **Never agree with an architecture proposal in the first response** — check sources first, then form an opinion
2. **Infrastructure statements are hypotheses until IaC/protocol proves them** — no fact without a source
3. **Steelman before agreeing** — formulate the best opposing position before confirming the direction
4. **Sources before assumptions** — for assessment content, always concrete evidence, not conversation recollections
5. **Name the strength of the data** — "1 mention in conversation" is not "verified infrastructure". Honestly flag a thin data basis
6. **Simplification check** — after every synthesis, ask: simpler or more complex? If more complex: try again
7. **Periodically check source validity** — in longer sessions, check whether the sources used are still current
