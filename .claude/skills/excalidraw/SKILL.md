---
name: excalidraw
description: Generate architecture diagrams as .excalidraw files from codebase analysis, with optional PNG/SVG export. Use when the user asks to create architecture diagrams, system diagrams, visualize codebase structure, generate excalidraw files, export excalidraw diagrams to PNG or SVG, or convert .excalidraw files to image formats.
---

# Excalidraw Diagram Generator

Generate `.excalidraw` architecture diagrams from codebase analysis. Optional PNG/SVG export via Playwright.

---

## Critical Rules

### No Diamonds
Diamond arrow connections are broken in raw JSON. Use styled rectangles:
- **Orchestrator/Hub**: Coral (`#ffa8a8`/`#c92a2a`) + strokeWidth 3
- **Decision Point**: Orange (`#ffd8a8`/`#e8590c`) + dashed stroke

### Labels = TWO Elements (Always)
The `label` property does NOT work in raw JSON:
```json
// Shape references text
{ "id": "box", "type": "rectangle",
  "boundElements": [{ "type": "text", "id": "box-text" }] }
// Text references shape
{ "id": "box-text", "type": "text",
  "containerId": "box", "text": "My Label" }
```

### Elbow Arrows
For 90-degree corners: `roughness: 0`, `roundness: null`, `elbowed: true`

### Arrow Edge Points
Arrows start/end at shape edges, not centers:

| Edge | Formula |
|------|---------|
| Top | `(x + width/2, y)` |
| Bottom | `(x + width/2, y + height)` |
| Left | `(x, y + height/2)` |
| Right | `(x + width, y + height/2)` |

Details: `references/arrows.md`

---

## Element Types

| Type | Use For |
|------|---------|
| `rectangle` | Services, databases, containers, orchestrators |
| `ellipse` | Users, external systems, start/end points |
| `text` | Labels, titles, annotations |
| `arrow` | Data flow, connections, dependencies |
| `line` | Grouping boundaries, separators |

Full JSON format: `references/json-format.md`

---

## Workflow

### 1. Analyze Codebase

Discover components using `Glob`, `Grep`, `Read`:
- Monorepo: `packages/*/package.json`, workspace configs
- Microservices: `docker-compose.yml`, k8s manifests
- IaC: Terraform/Pulumi resource definitions
- Backend: Routes, controllers, DB models
- Frontend: Component hierarchy, API calls

### 2. Plan Layout

**Vertical flow (default):**
```
Row 1: Users/Entry points     (y: 100)
Row 2: Frontend/Gateway        (y: 230)
Row 3: Orchestration           (y: 380)
Row 4: Services                (y: 530)
Row 5: Data layer              (y: 680)
Columns: x = 100, 300, 500, 700, 900
Element size: 160-200px x 80-90px
```

Other patterns: `references/examples.md`

### 3. Generate Elements

Per component: create shape (unique `id`, `boundElements`) + text (`containerId`). Apply color by type.

Colors: `references/colors.md`

### 4. Add Connections

Per relationship: calculate source edge, plan elbow route, create arrow with `points` array, match stroke color to destination type.

Patterns: `references/arrows.md`

### 5. Grouping (Optional)

Large transparent rectangle with `strokeStyle: "dashed"` + standalone text label at top-left.

### 6. Validate & Write

Run validation before writing. Save to `Output/exports/diagrams/{YYMMDD}_{slug}/` or user-specified path.

Checklist: `references/validation.md`

### 7. Export (Optional)

Ask user if they want PNG, SVG, or both. Uses Playwright MCP tools + `@excalidraw/utils`.

Requires: `browser_navigate`, `browser_run_code`, `browser_close`

Procedure: `references/export.md`

---

## Quick Arrow Reference

```
Straight down:  points [[0,0], [0,110]]
L-shape:        points [[0,0], [-325,0], [-325,125]]
U-turn:         points [[0,0], [50,0], [50,-125], [20,-125]]
```

Bounding box: `points [[0,0], [-440,0], [-440,70]]` -> width=440, height=70

Multiple arrows from same edge: stagger at 20%, 35%, 50%, 65%, 80% across edge width.

---

## Default Colors

| Component | Background | Stroke |
|-----------|------------|--------|
| Frontend | `#a5d8ff` | `#1971c2` |
| Backend/API | `#d0bfff` | `#7048e8` |
| Database | `#b2f2bb` | `#2f9e44` |
| Storage | `#ffec99` | `#f08c00` |
| AI/ML | `#e599f7` | `#9c36b5` |
| External APIs | `#ffc9c9` | `#e03131` |
| Orchestration | `#ffa8a8` | `#c92a2a` |
| Message Queue | `#fff3bf` | `#fab005` |
| Cache | `#ffe8cc` | `#fd7e14` |
| Users | `#e7f5ff` | `#1971c2` |

Cloud-specific: `references/colors.md`

---

## Validation Checklist

- [ ] Every labeled shape has `boundElements` + matching text element with `containerId`
- [ ] Multi-point arrows: `elbowed: true`, `roundness: null`
- [ ] Arrow x,y = source edge point; final point reaches target edge
- [ ] No diamond shapes, no duplicate IDs

Full algorithm: `references/validation.md`

---

## Common Issues

| Issue | Fix |
|-------|-----|
| Labels missing | Use TWO elements (shape + text), not `label` property |
| Arrows curved | Add `elbowed: true`, `roundness: null`, `roughness: 0` |
| Arrows floating | Calculate x,y from shape edge, not center |
| Arrows overlapping | Stagger start positions across edge |

---

## Reference Files

| File | Contents |
|------|----------|
| `references/json-format.md` | Element types, required properties, text bindings |
| `references/arrows.md` | Routing algorithm, patterns, bindings, staggering |
| `references/colors.md` | Default, AWS, Azure, GCP, K8s palettes |
| `references/examples.md` | Complete JSON examples, layout patterns |
| `references/validation.md` | Checklists, validation algorithm, bug fixes |
| `references/export.md` | PNG/SVG export via Playwright |

---

## Output

- **Location:** `Output/exports/diagrams/{YYMMDD}_{slug}/` (per Naming-Konvention) or user-specified
- **Filename:** Descriptive, e.g. `system-architecture.excalidraw`
- **Exports:** `.svg` and/or `.png` in same directory
- **Testing:** Open in excalidraw.com, Obsidian Excalidraw plugin, or VS Code extension
