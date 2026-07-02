---
tags: [rule, style, writing]
---

# Directive: Writing Style

Baseline style rules for all generative outputs (content, responses, reports, documentation). Specialized agents may be sharper, but not softer.

## Core Principles

- **Professional, not pathetic** — no superlatives, no promises of salvation
- **Precise and compact** — every sentence carries weight, no filler
- **Active over passive** — "we deploy", not "it gets deployed"
- **Concrete over abstract** — component or service names instead of "cloud solution"
- **Short sentences, short paragraphs** — readability over elegance
- **Direct address allowed** — occasional "you" / "your team" when it adds closeness
- **Solution-oriented** — even for problems, name the next step
- **Sparing with terminology** — technical terms correct, but not overloaded; briefly explain on first use
- **Smooth transitions** — no hard topic jumps without a bridge

## Buzzword Blacklist

Never use: revolutionary, game-changer, disruptive, forward-looking, trailblazing, seamless, frictionless, holistic, ecosystem (as a metaphor), state-of-the-art, cutting-edge, "In summary", "In conclusion".

## Language

- Align **language** with the project convention (see `code-language.md`)
- Stay consistent within a document, don't mix

## When a Rule Doesn't Fit

Briefly justify why (1 sentence) and move on. No rule is more important than clarity.

## Release Text (Standalone)

For release-ready documents (exports, anything external), additionally (see [[release-quality]]):

- **No meta-boilerplate**: no "What this section does / What's here / What's NOT here" preambles.
  A natural introductory line suffices.
- **No source references in the text**: no `(Source: ...)`, no transcript timecodes, no `Input/...` paths
  in running text. Provenance belongs in the frontmatter `sources:`.
- **No floods of parentheses**: sparing with asides; if a sentence consists only of parenthetical additions, rewrite it.
