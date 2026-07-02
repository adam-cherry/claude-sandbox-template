---
name: html-presentation
description: Build an HTML slide deck from a Markdown source using reveal.js. Use when the user asks for a presentation, slidedeck, html slides, reveal.js deck, or wants to turn a wiki page into a talk.
---

# HTML Presentation (reveal.js)

Turns a Markdown source into a standalone HTML slide deck (reveal.js via CDN). No npm install needed — the output is a single HTML file, openable via `file://`.

## Flow

### 1. Determine the input

The user provides a source. If not: ask.

Typical sources:
- Wiki page (`wiki/<section>/<page>.md`) — as a basis for a stakeholder update
- Action-plan excerpt
- Fresh outline (user writes bullets, the skill shapes them into slides)

### 2. Create the export directory

Convention: `Output/exports/presentations/{YYMMDD}_{shortname}/`

```bash
mkdir -p Output/exports/presentations/{YYMMDD}_{kurzname}/
```

### 3. Prepare the slide markdown

Create `slides.md` in the export directory. Convention:

- **`---`** separates horizontal slides
- **`--`** separates vertical sub-slides (optional)
- **First H1 = title slide**
- **Remove frontmatter** (otherwise reveal.js renders it as text)
- **Convert wikilinks `[[...]]`** to plain text
- **Images** linked relatively as `./assets/<file>`; create an `assets/` subfolder

Example:

```markdown
# Architecture Update Q2 2026

Your Name · 2026-01-01

---

## Current State

- Monolith with 4 modules
- Growing latency
- Tech debt: legacy auth

---

## Target State

- Split into 3 service domains
- Event bus for domain events
- Auth module replaced with OIDC
```

### 4. Generate index.html

A minimal reveal.js template (CDN, no build) in the same directory:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>{{Title}}</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@5/dist/reveal.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@5/dist/theme/white.css">
  <style>
    .reveal h1, .reveal h2 { color: #0288d1; }
    .reveal pre { font-size: 0.6em; }
  </style>
</head>
<body>
  <div class="reveal">
    <div class="slides">
      <section data-markdown="slides.md"
               data-separator="^---$"
               data-separator-vertical="^--$"></section>
    </div>
  </div>
  <script src="https://cdn.jsdelivr.net/npm/reveal.js@5/dist/reveal.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/reveal.js@5/plugin/markdown/markdown.js"></script>
  <script>
    Reveal.initialize({ hash: true, plugins: [ RevealMarkdown ] });
  </script>
</body>
</html>
```

Theme alternatives (instead of `white.css`): `black`, `league`, `beige`, `sky`, `night`, `serif`, `simple`, `solarized`, `moon`, `dracula`.

### 5. Verify

Test locally:

```bash
open Output/exports/presentations/{YYMMDD}_{kurzname}/index.html
# Or in the browser: file:///<absolute-path>/index.html
```

Expectation: slides load, `data-markdown="slides.md"` resolves (the browser must be allowed to read the local file — OK for `file://` calls in modern browsers; if there's a problem, write inline slides directly into the `<section>`).

### 6. Optional PDF export (hand-out)

reveal.js supports PDF export via the `?print-pdf` URL parameter + browser print. Shortcut:

```bash
# Open the browser with ?print-pdf, then "Print to PDF"
open "Output/exports/presentations/{YYMMDD}_{kurzname}/index.html?print-pdf"
```

Alternatively: `md-to-pdf` directly on `slides.md` for a hand-out variant without slide styling (different look, but better print readability).

## Rules

- All slide files (md, html, assets) MUST be in the same directory — relative paths only
- Remove frontmatter from the source markdown
- Resolve wikilinks `[[...]]` (otherwise a text literal in the slide)
- Code blocks: set the `language-` class for highlighting, otherwise reveal.js doesn't render it in color
- Don't override the theme with inline styles — add your own `<style>` block instead of patching the CDN CSS

## Anti-patterns

- Adding npm install / build steps — zero-install is the point
- Slide markdown with YAML frontmatter (reveal.js renders it as the first slide text)
- Multiple decks in one subfolder — one dedicated `{YYMMDD}_{slug}/` folder per deck
- Linking images absolutely (`/Users/...`) — breaks when sharing the folder
