---
name: looping
description: >-
  Portable, repo-agnostic goal-based engineering loop for non-trivial, multi-step work in two tracks
  -- code OR docs/content. A drop-in successor to GSD: same plan->execute->verify rigor, none of the
  machinery (no .planning/ tree, no SDK, no roadmap files) -- it DISCOVERS each repo's build/test/merge
  and doc conventions instead of assuming them. Instead of editing directly it runs: research ->
  validated plan -> [plan-approval gate] -> parallel execute on a feature branch -> adversarial verify
  -> review -> merge-ready, with the heavy lifting as visible Workflow(s). Catches expensive mistakes
  before anything is written and runs independent work concurrently -- far higher quality AND speed
  than naive "just do it" prompting. Fire it for CODE tasks ("build X", "fix Y across the codebase",
  "refactor Z that spans modules", "implement this spec") AND for consistency-critical DOCS/CONTENT
  rollouts where several source-of-truth files must stay aligned ("roll this decision across the docs",
  "apply the validated change through README + architecture doc + CHANGELOG coherently", "land this
  plan across the docs", "update the docs to match the new infra"). The discriminator is loop-worthy (multi-step, spans
  several files, benefits from validate+review) vs. one-shot -- so do NOT fire for a single
  self-contained edit (just edit it) or a recurring interval task (that is /loop). Trigger: "/looping
  <goal>" (goal may be a path to a plan/AP file). Flags are TWO orthogonal axes -- GATES: --auto (0),
  default (1: plan approval), --careful (3); DEPTH/cost: --lite (cheap: fewer agents, lower effort),
  default (balanced, goal-calibrated), --ultra (max: cross-AI plan review, deeper fan-out). Plus
  --track=code|content (override triage). By default it spends thoughtfully -- deep only where it pays
  (plan + adversarial validate), cheap on mechanical execute. Always branches first, never commits to
  the default branch.
---

# Looping — the goal-based engineering loop

`/looping <goal>` turns a goal into a merge-ready feature branch by running a disciplined loop
instead of editing files directly:

```
research -> synthesize+plan -> validate-plan -> [GATE] -> execute-in-waves -> verify -> review -> release-prep (STOP, merge-ready)
```

The thesis: an agent that researches, plans, validates, executes in parallel waves, and then
verifies produces *far* higher quality and is *faster* than one told to "just do it" — because the
expensive mistakes get caught before anything is written, and independent work runs concurrently. This
skill is the lean, cloud-native **drop-in successor to GSD**: it keeps GSD's plan→execute→verify rigor
but drops the machinery — **no `gsd-sdk` CLI, no `ROADMAP.md`/`.planning/`, no milestone or
workstream backing.** The fatal flaw of a naive linear, single-agent pipeline (verification as a
dead-end report, zero feedback loops) is exactly what the loop fixes. Just native primitives + a tiny
`.loop/<slug>/` state dir.

The loop is **track-polymorphic**. The frame (research → plan → validate → gate → execute → verify →
review → release) is identical across tracks; only the *engine per stage* changes:

- **`code`** — software on a real codebase (features, refactors, cross-cutting fixes, specs). Engine:
  worktree-isolated executor waves, `build/test/lint` verify, `/code-review`, `/run`. Deliverable =
  *code that gets tested and merged*.
- **`content`** — docs/content work spanning multiple files whose correctness depends on
  *consistency across documents* (e.g. rolling a decision through README + architecture doc +
  CHANGELOG, or adapting the docs to new infra). Engine: docs-scout research, content executor agents
  (file-disjoint, **no worktrees** — markdown has no build/merge-back), docs-integrity verify
  (internal links resolve, terminology consistent, no contradictions, no placeholders), style/consistency
  review. Deliverable = *reviewed docs/content that gets merged*, with the feedback loops a naive
  one-shot docs pass lacks.

## When to fire (and when not)

Fire for any **non-trivial goal on a real repo** — in either track:

- **code track:** a feature, refactor, cross-cutting bug fix, or spec implementation.
- **content track:** a multi-file docs/content update whose correctness depends on
  *consistency across documents* — e.g. rolling a decision through the README + architecture doc +
  CHANGELOG, or landing a validated infra change across CLAUDE.md + the affected docs pages while
  keeping the terminology and internal references aligned. The research→validate→review rigor is the
  whole point: it catches a contradiction, a stale reference, or a stranded cross-link *before* a
  dozen files drift apart.

**Do not** fire for: a recurring interval task (native `/loop`); a single throwaway shell command; or
a **single, self-contained edit that needs no research/validate/review loop** — just make the edit
directly (or use a single-purpose skill the repo provides).
The discriminator is not code-vs-content; it is **loop-worthy (multi-step, consistency-critical,
benefits from validate+review) vs. one-shot.** Which track to run is decided by pre-flight triage;
`--track=code|content` overrides it.

## Portability — running in any repo

`/looping` is **repo-agnostic**: it discovers each repo's conventions instead of assuming them. On
entry, scan once (cheap, read-only) and record what you find in `goal.md`; anything not found → use
the generic fallback, **never hard-fail**.

| What | Discover (in order) | Fallback |
|------|---------------------|----------|
| **Merge path** | a project merge skill (e.g. `/local-pr`) → `gh pr create` | stop at merge-ready, hand branch to user. **NEVER merge the default branch yourself.** |
| **Default branch + protection** | `git symbolic-ref refs/remotes/origin/HEAD`; hooks in `.githooks/`/`.git/hooks` | assume `main`; branch first regardless |
| **Build / test / lint** (code) | `package.json` scripts, `Makefile`, `pyproject`, CI config | ask, or skip with a logged caveat |
| **Doc structure + style** (content) | `CLAUDE.md`, `.claude/rules/` (`writing-style`, `no-placeholders`, `anti-bias`, `release-quality`), structure/style patterns in sibling files | "match the surrounding files" |
| **Review skills** | repo QA/review skills (`/code-review`, `/verify`, …) | the in-Workflow verifier is the floor |

Throughout this doc **a multi-file docs rollout is the worked content example** (a decision rolled
across README + architecture doc + CHANGELOG, kept internally consistent). In another repo, substitute
its equivalents — the *mechanism* (discover → plan → execute disjoint → verify integrity) is identical.

## The two-layer architecture (read this first)

This is the one thing to get right. There are **two layers**, and they must not be confused:

- **Main loop (you, running this skill):** does the git pre-flight, parses flags, decides triage,
  launches Workflow(s), runs the **plan-approval gate** (`EnterPlanMode`), and runs the track's
  review skills (whatever the repo provides — e.g. code: `/code-review`, `/verify`, `/run`; content:
  a docs-consistency + style/placeholder pass, plus any repo review skill) — then the repo's
  **merge path** (see Portability).
  These are interactive / user-facing and CANNOT run inside a Workflow.
- **Workflow(s) (the engine):** the background, deterministic agent fan-out — research agents,
  the planner, the plan-checker loop, the execute waves (worktree-isolated for code; plain
  file-disjoint `parallel()` for content), the in-workflow verifier. A Workflow runs to completion
  and returns; **it cannot pause for a gate**.

Therefore the loop is **a sequence of Workflow runs with main-loop gates between them**, not one
monolithic Workflow. Concretely:

```
PRE-FLIGHT (main loop)
   |
   v
Workflow #1  "looping-plan/<slug>"   research -> plan -> validate     --> writes plan.md, returns plan+verdict
   |
   v
GATE (main loop)   EnterPlanMode(plan)   [default; skipped by --auto]
   |
   v
Workflow #2  "looping-build/<slug>"  execute waves -> in-wf verify    --> writes changes on feature branch, returns build report
   |
   v
REVIEW (main loop)   code: /run /verify /code-review · content: docs-consistency + style/placeholder pass   [corrective -> re-run #2 on gaps]
   |
   v
RELEASE-PREP (main loop)   write SUMMARY.md; STOP -> "Merge-ready on feature/<slug>." + repo merge cmd (e.g. /local-pr)
```

"Always a Workflow" (per the design decision) holds: every run's heavy work is one or more visible
Workflows. The gates and review skills are the thin main-loop glue between them.

## Pre-flight (main loop, before any Workflow)

1. **Parse** the goal: trailing text after flags = `GOAL` (a goal may be a path to a plan/AP file —
   read it). Flags on two axes — gates: `--auto` / `--careful` (mutually exclusive → if both, ask
   which); depth: `--lite` / `--ultra` (mutually exclusive → if both, ask which). Plus
   `--track=code|content`. Axes compose (e.g. `--auto --lite`).
1b. **Clarify if ambiguous** (see "Clarify" below) — kill scope/intent ambiguity *before* planning, so
   research and the plan build on facts, not guesses.
2. **Track triage**: pick the engine — `code` vs `content`.
   - `--track=` wins if set.
   - Else infer from the deliverable: touches source/tests/build (`*.ts|js|py|go|…`, app code) →
     **code**; touches docs/markdown/README/spec/CHANGELOG → **content**. Mixed → split into two
     `/looping` runs (one per track), or ask.
   - Record the chosen track in `goal.md`. *(Repo-shape hint: a code repo defaults to `code`; a
     docs-heavy repo defaults to `content`.)*
3. **Slug**: `kebab(GOAL)`, max ~40 chars.
4. **Branch guard** (non-negotiable): if on the repo's default branch, run
   `git switch -c feature/<slug>`. If already on a `feature/*` branch, stay. **Never commit to the
   default branch.** Merge only via the repo's merge path (here: `/local-pr`).
5. **State dir**: `mkdir -p .loop/<slug>/` and write `goal.md` (verbatim goal + parsed flags + chosen
   track + any decisions the user already stated). This is the durable floor — survives context resets.
6. **Trivial-triage**: does the goal touch ≤1 file and need no parallelism (typo, one-liner, single
   passage edit)? → run the **degenerate path** (one tiny single-phase Workflow). No waves, no
   worktrees, no gate unless `--careful`. See `references/workflow-templates.md` → "Degenerate
   template". *(For content, a truly trivial single-file edit is usually better as a direct edit —
   see "When to fire".)*
7. **Effort-tier**: set the depth tier — `--lite`/`--ultra` if given, else **goal-calibrate** (see
   "Token economy"): estimate scope (files touched, decision reversibility, blast radius) and pick
   `lite` for small/low-risk, `default` otherwise. When it straddles, go `default`. Record the tier
   in `goal.md`; thread it into the Workflow (the templates read it to set per-stage `model`/`effort`).

## Clarify — kill ambiguity before planning (main loop, cheap)

The cheapest fix is a question asked *before* a plan exists. Right after parsing (step 1b), gauge the
goal's **ambiguity** in one beat: is the scope, the intended outcome, or the success criterion
genuinely under-determined — such that two reasonable readings would produce *different plans*?

- **Clear enough → skip.** Most goals are. Do not interrogate a goal you can already plan. A wrong
  question is friction; only ask when an answer would change the plan.
- **Ambiguous → `AskUserQuestion`** with 2–3 *targeted* questions (scope boundary, which of N readings,
  the done-criterion). Weave the answers into `goal.md` as locked decisions — they now anchor research,
  plan, and verify.
- **Flag interaction:** `--auto` skips Clarify (unattended — it cannot ask; it proceeds on the most
  reasonable reading and records the assumption in `goal.md`). `--careful` always runs Clarify.

This is the lightweight heir to GSD's `discuss-phase`/`spec-phase` — the ambiguity-killing value,
none of the SPEC.md/scoring machinery. It is a main-loop step (questions can't run inside a Workflow).

## Flags — two orthogonal axes

Flags split into **GATES** (how much human sign-off) and **DEPTH/cost** (how much compute). They
compose freely: `--auto --lite` = unattended + cheap; `--careful --ultra` = max sign-off + max rigor.
The loop **body is identical** across all of them — flags change gate count and the per-stage
effort/model tier, never the control flow.

**Gate axis** (human checkpoints):

| Flag | Gates | Behavior |
|------|-------|----------|
| **`--auto`** | 0 | Skip the plan gate. Goal → merge-ready unattended. **Still halts at release-prep** — never auto-merges `main`. |
| **(default)** | 1 | Pause once for plan sign-off (`EnterPlanMode`) where correction is cheapest: before anything is written. |
| **`--careful`** | 3 | Adds a gate after research and after execution, plus the plan gate. For unfamiliar or high-stakes work. |

**Depth axis** (compute — see the effort/model matrix below):

| Flag | Meaning |
|------|---------|
| **`--lite`** | Cheap pass: fewer scouts (2), single validate iteration, lower effort everywhere. For small/low-risk rollouts where the loop's *structure* (plan→execute→verify) is worth more than its depth. |
| **(default)** | **Balanced, goal-calibrated** (see below). Deep where it pays, cheap where it's mechanical. |
| **`--ultra`** | Max rigor: +risk-scout, a cross-AI second opinion on the plan (if a council/cross-AI tool is available), mandatory adversarial verify, `/code-review ultra` + `/security-review` (code) or an adversarial docs-consistency falsification pass (content). Raises *depth*, never adds gates. |

## Token economy — effort & model per stage

This is the heart of spending thoughtfully. **The expensive mistake is running the top model at high
effort on mechanical work.** Deep reasoning belongs in plan + adversarial validate; execution of
scoped edits does not. Default tiers (each agent gets `model`/`effort` opts; omitting `model` inherits
the session model, normally Opus):

| Stage | model (default) | effort | Why |
|-------|-----------------|--------|-----|
| **Research** scouts | `sonnet` | medium | read + structure the codebase/docs; little deep reasoning |
| **Plan** (author) | inherit (Opus) | **high** | the core architectural reasoning — pays for itself |
| **Validate** (adversarial) | inherit (Opus) | **high** | catching expensive mistakes IS the value; keep it deep |
| **Execute** | `sonnet` | medium | scoped edits on planned files — Sonnet is the floor (NOT Haiku) |
| **Integrate** (code) | `sonnet` | low | mechanical branch merge |
| **Verify** | `sonnet` | medium | run checks + falsify "done" |
| **Debug** (persisting fail) | inherit (Opus) | **high** | root-cause reasoning — escalates from blind fix (rare, but depth pays) |
| **Release** | `sonnet` | low | write SUMMARY |

**Depth-flag modifiers** (applied on top of the matrix):
- `--lite`: scouts → 2 and effort `low`; plan/validate → effort `medium`, validate → **1 iteration**; execute/verify effort `low`.
- `--ultra`: +risk-scout (4); validate → 3 iterations + cross-AI second opinion (if available); verify → effort `high`, multi-lens. Execute **stays Sonnet** — ultra buys review/validate rigor, not a heavier executor.

**Goal-calibration (the default's "thoughtful" part):** in pre-flight, size the goal and nudge the
tiers — a 2-file refinement does not need 4 scouts or 3 validate rounds; a 20-file cross-cutting
change with irreversible decisions earns the full default (or suggest `--ultra`). When the size is
obvious, just pick; when it straddles lite/default, say so in one line and proceed with the safer
(default) tier — a wrong cheap pass costs more to clean up than it saved.

`/looping --auto --lite <goal>` = cheapest unattended pass · `/looping --careful --ultra <goal>` = maximum scrutiny.

## Track polymorphism (engine per stage)

Same frame, same gates, same `.loop/` state, same 3-iteration caps. Only the per-stage **engine**
differs. Author the Workflow from the matching template family in `references/workflow-templates.md`
(`code` family vs `content` family). The `content`-engine cells below describe generic docs mechanics
— in another repo, substitute its equivalents (see Portability).

| Stage | `code` engine | `content` engine |
|-------|---------------|------------------|
| Research | codebase-mapper · test/build/lint scout · Context7 deps | docs-mapper (which file holds which claim/statement this goal touches) · consistency scout (where the same term/decision appears across files) · style/structure scout (`writing-style` terms to avoid, structure to match) · optional `deep-research` |
| Plan | wave plan; task `verify` = a test/lint command | wave plan; task `verify` = a content acceptance check (internal references resolve, terminology consistent, no contradiction, no placeholder per `no-placeholders`, markdown valid) |
| Validate | adversarial `plan-checker` (file-disjointness, deps, testability, rollback) | same checker **plus** a consistency lens (does the plan keep terminology/decisions aligned across all touched files?) and an anti-bias lens (`anti-bias`: steelman keeping the current wording before overriding it) |
| Gate | `EnterPlanMode` | `EnterPlanMode` (identical) |
| Execute | `parallel()` + `isolation:'worktree'` per task; integrator merges branches | `parallel()` of content agents on the feature branch, **file-disjoint, NO worktrees** (markdown = no build/merge-back). Each edits its files, keeps terminology + references consistent, commits atomically |
| Verify | Bash `build + test + lint`; falsify "done" | docs-integrity check (internal links/references resolve, terminology consistent, markdown valid, no draft markers/placeholders per `no-placeholders`, style per `writing-style`); falsify "done" = does any edit contradict another document it did not address, or leave a stranded reference? |
| Review (main loop) | `/code-review high --fix`; `/run` + `/verify` | docs-consistency + style/placeholder pass (internal links resolve, no contradictions, `no-placeholders`, `writing-style`), plus any repo review skill; no `/run` |
| Release | `SUMMARY.md`; repo merge path | identical |

`--ultra` deltas apply per track: code → `/code-review ultra` + `/security-review`; content →
a cross-AI lens on the plan (if available) + a mandatory adversarial docs-consistency falsification pass.
Worktree note: content execute is **simpler** than code — disjoint markdown files need no worktree
isolation and no integrator (the fiddly merge-back step disappears). Only fall back to worktrees if a
content wave genuinely must edit the *same* file in parallel (rare; usually replan to disjoint it).

## The loop, stage by stage

Full annotated Workflow script templates (real Workflow-tool API) live in
**`references/workflow-templates.md`** — read it before authoring the Workflow. Here is what each
stage does and the principles that keep it correct.

**1. Research** *(Workflow #1, `parallel()` of read-only agents — NO worktree).*
Fan out 2–4 scoped researchers: a codebase-mapper (arch/modules/entrypoints), a test/build/lint
conventions scout, and — only if the goal needs external libs/APIs — a docs agent using Context7
(`mcp__plugin_context7_context7__resolve-library-id` / `query-docs`) + `WebSearch`. Read-only tools,
no mutation, so no worktree. Schema output `{findings[], risks[], openQuestions[]}` →
`.loop/<slug>/research.md`.

**2. Synthesize + plan** *(Workflow #1, single planner agent, `effort: 'high'`).*
The planner consumes the research and emits a **schema-validated wave plan**:
`{waves:[{tasks:[{id, files[], deps, verify}]}], risks, rollback}`. Waves are ordered; tasks
*within* a wave MUST be file-disjoint so they can run in parallel safely. → `.loop/<slug>/plan.md`.
Use a capable model (opus-class — usually just inherit the session model; do not downgrade the planner).

**3. Validate-plan** *(Workflow #1, adversarial loop, max 3 iterations).*
A separate `plan-checker` agent adversarially classifies BLOCKER/WARN and checks: wave
file-disjointness (`waveSafety`), missing deps, untestable tasks, rollback present. Loop
plan→check until `verdict == "pass"` or 3 iterations; on `revise`, feed blockers back into the
planner. `--ultra` adds a cross-AI second lens (if available). Workflow #1 returns the validated plan.

**GATE (main loop):** unless `--auto`, call `EnterPlanMode` with a tight render of the plan (waves,
files touched, risks, rollback). The user approves (`ExitPlanMode`) or sends corrections → re-run
Workflow #1's plan step with the feedback. `--careful` also gates after stage 1.

**4. Execute in waves** *(Workflow #2, sequential waves — a `for`-loop — each a `parallel()`).*
Waves run **in order** (wave N+1 depends on N; do not use `pipeline()`, which would drop the ordering
barrier). Within a wave, tasks run as a `parallel()` of executor agents; each touches ONLY its
planned files, commits atomically, and on a blocker emits `{blocked, reason}` instead of improvising.
**Replan-on-blocker:** a hard conflict or any `{blocked}` halts the wave → return the blocker so the
main loop re-enters planning with the delta.
- *code track:* **one git worktree per agent** (`isolation: 'worktree'`) — mandatory for concurrent
  file mutation — and an **integrator** agent merges the per-agent branches between waves (the one
  genuinely fiddly part; see the template's integrator notes).
- *content track:* **no worktrees, no integrator** — agents write disjoint markdown directly on the
  feature branch (keeping terminology + internal references consistent, atomic commits). The
  whole merge-back step disappears.

**5. Verify.** Inside Workflow #2, a goal-backward `verifier` agent tries to **falsify "done"**,
returning `{pass, failures[]}`; on failure → a corrective `parallel()` wave back through stage 4
(max 3). **The first corrective pass fixes directly; if a failure *persists* after that, escalate
from blind-fix to root-cause** — do NOT re-run the same fix three times. Run a **systematic-debugging**
pass (reproduce → isolate → hypothesize → test one variable → fix; the superpowers skill if present,
else a hypothesis-driven debug agent — see "Recommended capabilities"). Blind retry
loops are the single biggest waste in a build loop. The engine differs by track:
- *code track:* run the suite via Bash (build + test + lint, discovered per-repo). Then in the **main
  loop** run `/run` + `/verify` for real-app behavior and **`/code-review`** (`high --fix`, or
  `ultra` + `/security-review` under `--ultra`) on the diff.
- *content track:* docs-integrity (internal links/references resolve, terminology consistent,
  markdown valid, no draft markers/placeholders per `no-placeholders`, style per `writing-style`);
  falsification = "does any edit contradict another document it did not address, or leave a stranded
  reference?". Then in the **main loop** run a docs-consistency + style/placeholder pass (plus any
  repo review skill) for depth.

Findings that need changes → another corrective Workflow #2 run scoped to the gaps.

**6. Release-prep (main loop).** Write `.loop/<slug>/SUMMARY.md` (what shipped, verify/review
verdicts). Then **extract learnings** (one cheap `sonnet` pass over `goal.md` + `plan.md` + the verify
results): distil **Decisions** (choices made + why), **Lessons** (what surprised us / would change next
time), and **Gotchas** (a trap a future run should avoid), and *append* a dated block to a repo-wide
**`.loop/LEARNINGS.md`** — searchable across runs, so the next `/looping` starts smarter than the last.
Keep it terse (a handful of bullets); skip a section that has nothing real. Ensure the feature branch
is clean and green. **STOP at merge-ready** — print `Merge-ready on feature/<slug>.` plus the repo's
merge command (here: `/local-pr`). Never merge the default branch yourself.

(This is the lightweight heir to GSD's `extract-learnings` — durable, greppable cross-run memory with
no `.planning/` index. On entry, a research scout may skim `.loop/LEARNINGS.md` for relevant priors.)

## `.loop/<slug>/` state layer

Flat markdown only. The schema-typed agent outputs *are* the state — no STATE.md tables, no
`ROADMAP.md`, no `.planning/`, no SDK. Git-tracked on the feature branch so the plan survives
context resets.

```
.loop/
├── LEARNINGS.md       # repo-wide, append-only: Decisions/Lessons/Gotchas per run (cross-run memory)
└── <slug>/
    ├── goal.md            # FLOOR (always): verbatim goal + flags + locked decisions
    ├── run.workflow.js    # FLOOR (always): the authored Workflow script(s) — the engine, re-runnable
    ├── research.md        # stage 1 output           (write-on-produce)
    ├── plan.md            # stage 2 validated plan    (+ stage 3 verdicts appended on replan)
    └── SUMMARY.md         # stage 6 merge-ready note   (write-on-finish)
```

Floor is **2 files** (`goal.md`, `run.workflow.js`); everything else is write-on-demand. A `verify.md`
is written **only if** stage 5 actually loops (a green first pass leaves no litter). Keep it tiny —
this dir is state, not documentation.

## OpenSpec

`/looping` does **not** depend on OpenSpec (it is a separate CLI with a hard Node-20 dependency and an
`openspec/` tree — adopting it as the backbone would reintroduce exactly the GSD-style ballast this
skill escapes; our schema-validated `.loop/` files + `plan-checker` already buy the one real benefit,
a durable machine-checkable plan). **Escape hatch, documentation only — no skeleton branch:** if the
*target repo already uses OpenSpec* (an `openspec/` dir exists), release-prep may run
`openspec archive` to fold the change into living specs instead of writing specs into `SUMMARY.md`.
Adopt-when-present, never auto-installed, never required.

## Guardrails / STOP conditions

- **Branch first, never the default branch.** Respect any repo hooks (`.githooks/`, `.git/hooks`).
  Merge only via the repo's merge path (here: `/local-pr`).
- **Stop at merge-ready.** `/looping` never merges, even with `--auto`.
- **Cap every feedback loop** (validate, verify, review-correct) at 3 iterations. On a *repeated*
  blocker, halt and surface it to the user with the concrete reason — do not improvise around it.
- **No blind retries.** A failure that survives **one** corrective pass switches to root-cause /
  `systematic-debugging` (stage 5), not the same fix a second and third time. Re-running an identical
  fix is the loop's most expensive failure mode.
- **Read-only research, scoped execution.** Research agents get read-only tools; only execute-wave
  agents mutate, each only on its planned files (code: inside worktrees; content: disjoint files on
  the feature branch).
- **Honor the repo's language + style rules** (discovered in pre-flight from `CLAUDE.md` /
  `.claude/rules/`): `code-language`, `writing-style`, `conventional-commits`, `git-workflow`. Commit
  prefixes `feat|fix|refactor|docs|chore|test`; Conventional Commits; first line ≤72 chars; never a
  local home path or a company-specific reference in a committed file.
- **Content track honors the repo's doc conventions** (discovered, not assumed): structure,
  terminology, and the style guide — plus a non-negotiable **consistency + anti-bias discipline**:
  keep terminology and decisions aligned across every touched document; never leave a draft marker or
  placeholder in delivered content (`no-placeholders`); steelman the existing wording before
  overriding it and flag thin evidence honestly (`anti-bias`); follow `writing-style`. The validate +
  verify stages enforce these, not just the executor.
- **Release-grade content** (anything external or published — `release-quality`): the delivered
  document is **standalone** — NO draft markers, TODO/placeholder text, or meta-boilerplate in the
  body. For such reworks: **execute with Opus** (not the Sonnet default — Sonnet reproducibly injects
  slop and placeholder text), effort high; anchor to the last clean version as baseline instead of
  regenerating; provide any shared block (e.g. a diagram or table reused across files) **verbatim** so
  it is byte-identical across documents; and add an adversarial verify that greps for the forbidden
  patterns.

## Ecosystem hooks (which tool per stage)

The mechanism per stage (the **engine per track** is in "Track polymorphism" above; this is the
concrete tool/primitive). Where two entries appear, it is *code* / *content*.

| Stage | Primary (lean default) | `--ultra` add-on |
|-------|------------------------|------------------|
| Research | inline `agent()` ×3 (Read/Grep/Glob); *code:* Context7 + `WebSearch` for ext libs; *content:* docs-mapper + consistency + style/structure scouts | `deep-research`; a cross-AI lens on forks (if available) |
| Plan | native planner `agent()` (a wave-plan *prompt shape*, no `.planning/` coupling) | — |
| Validate | inline adversarial `agent()`; *content:* + anti-bias / cross-file consistency lens | cross-AI convergence (if available) |
| Gate | `EnterPlanMode` / `ExitPlanMode` (main loop) | — |
| Execute | *code:* `parallel()` + `isolation:'worktree'` + integrator; *content:* `parallel()` of content agents, disjoint files, no worktree | wider fan-out |
| Verify | *code:* Bash test/lint + `/run` + `/verify`; *content:* docs-integrity (links/references, terminology, `no-placeholders`, `writing-style`) | mandatory skeptic; deeper pass |
| Review | *code:* `/code-review high --fix`; *content:* docs-consistency + style/placeholder pass (main loop) | *code:* `/code-review ultra` + `/security-review`; *content:* adversarial docs-consistency falsification |
| Release | native `agent()` → SUMMARY; the repo's **merge path** is the only merge route | optional `openspec archive` |

Deliberately excluded as ballast: the `gsd:*` milestone/roadmap/workstream suite and `gsd-sdk` —
`/looping` is their drop-in successor without the machinery.

## Recommended capabilities (superpowers integration — recommend, not bind)

`/looping` runs fully on **native primitives** (Workflow, `agent()`, `/code-review`, `/verify`,
`/run`, `EnterPlanMode`, `WebSearch`). It needs no plugin. But it gets *stronger* when capability
skills are installed — most usefully the **[superpowers](https://github.com/obra/superpowers) bundle**.
The design rule (see "Portability"): **adopt-when-present, never hard-require.** Notably, most
superpowers patterns are things looping already does natively — so the bundle mostly *sharpens* the
prompts, with two genuine gaps it *fills*.

| Loop capability | looping native | superpowers enhancer (adopt if present) | fallback |
|-----------------|----------------|------------------------------------------|----------|
| Parallel agent fan-out | Workflow `parallel()` | `dispatching-parallel-agents` | native (no gap) |
| Worktree isolation | `isolation:'worktree'` + integrator | `using-git-worktrees` | native (no gap) |
| Plan authoring | planner agent + schema | `writing-plans` | native (no gap) |
| Verify before done | goal-backward verifier | `verification-before-completion` | native (no gap) |
| Code review | `/code-review` (native) | `requesting-code-review` / `receiving-code-review` | in-Workflow review agent |
| Branch finish | release-prep + repo merge path | `finishing-a-development-branch` | native (no gap) |
| **Root-cause debugging** | ⚠️ **gap** — only blind corrective waves | **`systematic-debugging`** ← biggest add | built-in hypothesis-driven debug agent (stage 5 escalation) |
| **Test-driven execute** (code) | execute-then-verify | **`test-driven-development`** | execute-then-verify |
| Pre-loop ideation | — (out of loop scope) | `brainstorming` | decide first, then `/looping` |

**The two real adds:**
1. **`systematic-debugging`** — looping is a *build* loop, not a *debug* loop. When verify fails for a
   non-obvious reason, blind retries waste tokens. Stage 5 now **escalates to root-cause** after one
   failed corrective pass: use `systematic-debugging` if installed, else the
   built-in hypothesis-driven debug agent (reproduce → isolate → one-variable test → fix).
2. **`test-driven-development`** — on the code track, an optional execute mode: the planner emits a
   failing test per task first, the executor makes it pass. Turn it on when correctness matters more
   than speed (it costs an extra wave). Off by default.

Everything else the bundle offers, looping already embodies. So: **install superpowers if you want the
debugging + TDD lift and sharper prompts; skip it and looping still runs the full pipeline.** That is
the GSD-replacement bargain — the capabilities, never the lock-in.
