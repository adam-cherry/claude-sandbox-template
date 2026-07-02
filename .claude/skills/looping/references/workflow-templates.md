# Workflow Templates (real Workflow-tool API)

These are the literal scripts `/looping` authors and runs. They use the **actual** Workflow-tool
hooks — `phase()`, `agent(prompt, opts)`, `parallel(thunks)`, `pipeline(items, ...stages)`, `log()`,
`budget` — and plain JS for control flow. There is **no** `loop_until` and **no** `EnterPlanMode`
inside a Workflow; gates live in the main loop *between* Workflow runs (see SKILL.md → "two-layer
architecture").

**Two template families, picked by the pre-flight track (SKILL.md → "Track polymorphism"):**
- **`code` family** — Workflow #1/#2 below. Worktree-isolated execute waves, `build/test/lint` verify.
- **`content` family** — the two scripts under "Content track templates" at the bottom. Disjoint
  markdown execute (no worktrees), docs-integrity verify (links/references, terminology, no placeholders).

The frame is identical; only research prompts, the task `verify` semantics, the execute isolation,
and the verify engine differ.

Save the script(s) the model authors to `.loop/<slug>/run.workflow.js` (the durable engine), then
launch via the `Workflow` tool. Pass run-specific values (slug, goal, flags) by interpolating them
into the script string or via the `args` global.

Reminder on the API that bites people:
- Script MUST start with `export const meta = { name, description, phases }` — a **pure literal**.
- `agent(prompt, {schema})` returns the validated object; without `schema` it returns the final text.
- `isolation: 'worktree'` gives an agent its own git worktree (use ONLY for parallel file mutation).
- Loops are plain `while`/`for` over `agent()` calls. Concurrency is capped (~10–16) automatically.
- The script's `return` value is delivered to the main loop in the completion notification.
- `Date.now()`/`Math.random()` are unavailable — vary by index, stamp time after the run.
- **Flat scalars via `args` are fine** (`slug`, `goal`, `ultra`, `lite` round-trip reliably). But
  **hardcode large/nested structures** (`waves`, `plan`) as `const`s in the saved
  `.loop/<slug>/*.workflow.js` — nested `args` objects do NOT round-trip (a stringified list reaches
  the script as one string and `.length`/`.map` throw). Lesson from a real run: the build workflow
  crashed on `args.waves` being undefined until the wave list was inlined.

## Tier helper (paste into every instantiated script)

This is how the effort/model matrix from SKILL.md becomes real. Set `tier` from the depth flag, then
spread `T.<stage>` into every `agent()` call. Omitting `model` inherits the session model (Opus) —
that is deliberate for plan/validate; everything else pins `sonnet` (never Haiku — too weak for
scoped edits per project preference).

```js
const tier = 'default'   // 'lite' | 'default' | 'ultra'  ← set from the parsed depth flag
const lite = tier === 'lite', ultra = tier === 'ultra'
const T = {
  research: { model: 'sonnet', effort: lite ? 'low' : 'medium' },
  plan:     { effort: lite ? 'medium' : 'high' },            // inherit Opus — core reasoning
  validate: { effort: lite ? 'medium' : 'high' },            // inherit Opus — adversarial depth
  execute:  { model: 'sonnet', effort: lite ? 'low' : 'medium' },
  integrate:{ model: 'sonnet', effort: 'low' },
  verify:   { model: 'sonnet', effort: lite ? 'low' : (ultra ? 'high' : 'medium') },
  write:    { model: 'sonnet', effort: 'low' },              // SUMMARY / brief writers
}
const SCOUTS = lite ? 2 : 3            // +1 risk-scout under ultra (push below)
const VALIDATE_ITERS = lite ? 1 : 3
// Usage: agent(prompt, { ...T.research, label, phase, schema })
```

---

## Workflow #1 — plan (`looping-plan/<slug>`)

Research → synthesize+plan → validate. Returns the validated plan. Writes `research.md` + `plan.md`.
No mutation, so no worktrees.

```js
export const meta = {
  name: 'looping-plan',
  description: 'Research, plan, and adversarially validate a wave plan for a coding goal',
  phases: [
    { title: 'Research', detail: 'parallel read-only scouts' },
    { title: 'Plan', detail: 'opus-class planner -> wave plan' },
    { title: 'Validate', detail: 'adversarial plan-checker loop' },
  ],
}

// args = { slug, goal, ultra: bool, careful: bool }
const { slug, goal, ultra, lite } = args   // depth tier from flags; lite/ultra falsy = balanced default
const READONLY = 'You have READ-ONLY tools (Read, Grep, Glob, and web/docs). Do NOT modify files.'

const RESEARCH_SCHEMA = {
  type: 'object',
  required: ['findings', 'risks', 'openQuestions'],
  properties: {
    findings: { type: 'array', items: { type: 'string' } },
    risks: { type: 'array', items: { type: 'string' } },
    openQuestions: { type: 'array', items: { type: 'string' } },
  },
}

phase('Research')
const scouts = [
  () => agent(`${READONLY}\nMap the codebase for this goal: architecture, modules, entrypoints, and the files most likely to change.\nGoal: ${goal}`, { label: 'research:map', phase: 'Research', model: 'sonnet', schema: RESEARCH_SCHEMA }),
  () => agent(`${READONLY}\nFind how this repo runs tests, builds, and lints (commands, config, CI). Report exact commands.\nGoal: ${goal}`, { label: 'research:conventions', phase: 'Research', model: 'sonnet', schema: RESEARCH_SCHEMA }),
  () => agent(`${READONLY}\nIf the goal needs external libraries/APIs, gather authoritative usage via Context7 (resolve-library-id, query-docs) and WebSearch. If none needed, say so briefly.\nGoal: ${goal}`, { label: 'research:deps', phase: 'Research', model: 'sonnet', schema: RESEARCH_SCHEMA }),
]
if (ultra) scouts.push(
  () => agent(`${READONLY}\nAdversarial risk scout: enumerate failure modes, edge cases, and blast radius for this goal.\nGoal: ${goal}`, { label: 'research:risk', phase: 'Research', model: 'sonnet', schema: RESEARCH_SCHEMA })
)
const research = (await parallel(scouts)).filter(Boolean)

// Merge findings into .loop/<slug>/research.md (an agent with Write does this once).
await agent(`Write a tight merged research brief to .loop/${slug}/research.md from this JSON. Keep it short, dedupe, lead with risks.\n${JSON.stringify(research)}`, { label: 'research:write', phase: 'Research' })

const PLAN_SCHEMA = {
  type: 'object',
  required: ['waves', 'risks', 'rollback'],
  properties: {
    waves: {
      type: 'array',
      items: {
        type: 'object', required: ['tasks'],
        properties: { tasks: { type: 'array', items: {
          type: 'object', required: ['id', 'files', 'deps', 'verify'],
          properties: {
            id: { type: 'string' },
            files: { type: 'array', items: { type: 'string' } },
            deps: { type: 'array', items: { type: 'string' } },
            verify: { type: 'string' },
          },
        } } },
      },
    },
    risks: { type: 'array', items: { type: 'string' } },
    rollback: { type: 'string' },
  },
}

phase('Plan')
let plan = await agent(
  `You are the planner. Read .loop/${slug}/goal.md and .loop/${slug}/research.md. Produce a wave plan.
RULES: waves are ordered; tasks WITHIN a wave MUST be file-disjoint (so they run in parallel safely).
Each task lists exact files, deps (task ids), and a concrete verify command/check. Include rollback.
Goal: ${goal}`,
  { label: 'plan:author', phase: 'Plan', effort: lite ? 'medium' : 'high', schema: PLAN_SCHEMA }
)

phase('Validate')
const CHECK_SCHEMA = {
  type: 'object', required: ['verdict', 'blockers', 'waveSafety'],
  properties: {
    verdict: { enum: ['pass', 'revise'] },
    blockers: { type: 'array', items: { type: 'string' } },
    waveSafety: { type: 'boolean' },
  },
}
let verdict = null
for (let i = 0; i < (lite ? 1 : 3); i++) {
  verdict = await agent(
    `Adversarially review this wave plan. Classify issues BLOCKER/WARN. Check: every wave's tasks are
file-disjoint (waveSafety), no missing deps, every task is testable, rollback present.${ultra ? ' Then seek a cross-AI second opinion before passing if such a tool is available.' : ''}
PLAN: ${JSON.stringify(plan)}`,
    { label: `validate:${i + 1}`, phase: 'Validate', effort: lite ? 'medium' : 'high', schema: CHECK_SCHEMA }
  )
  log(`validate iteration ${i + 1}: ${verdict.verdict} (${verdict.blockers.length} blockers)`)
  if (verdict.verdict === 'pass') break
  plan = await agent(
    `Revise the plan to clear these blockers (targeted changes, do not replan from scratch):\n${verdict.blockers.join('\n')}\nPLAN: ${JSON.stringify(plan)}`,
    { label: `replan:${i + 1}`, phase: 'Validate', effort: lite ? 'medium' : 'high', schema: PLAN_SCHEMA }
  )
}

await agent(`Write the final validated plan to .loop/${slug}/plan.md (human-readable: waves, files, deps, verify, risks, rollback).\n${JSON.stringify(plan)}`, { label: 'plan:write', phase: 'Validate' })

return { plan, verdict, researchCount: research.length }
```

**After Workflow #1 returns (main loop):** unless `--auto`, call `EnterPlanMode` with a tight render
of `plan` (waves, files touched, risks, rollback) for sign-off. `--careful` also gates right after Research.

---

## Workflow #2 — build (`looping-build/<slug>`)

Execute waves (worktree-isolated) → integrate → in-workflow verify. Mutates code on the feature
branch. Launch this only after the plan gate passes (or immediately under `--auto`).

```js
export const meta = {
  name: 'looping-build',
  description: 'Execute a validated wave plan in worktree-isolated parallel waves, then verify',
  phases: [
    { title: 'Execute', detail: 'parallel waves, one worktree per task' },
    { title: 'Verify', detail: 'goal-backward falsification + tests' },
  ],
}

// args = { slug, goal, plan, ultra }
const { slug, goal, plan, ultra, lite } = args   // depth tier from flags; lite/ultra falsy = balanced default

const EXEC_SCHEMA = {
  type: 'object', required: ['done', 'blocked'],
  properties: { done: { type: 'boolean' }, blocked: { type: 'boolean' }, reason: { type: 'string' } },
}

phase('Execute')
// Waves are SEQUENTIAL (wave N+1 depends on wave N) -> plain for-loop, NOT pipeline()
// (pipeline runs items with no ordering barrier and would run all waves at once). Tasks WITHIN a
// wave are file-disjoint, so they run in parallel(), each in its own worktree.
// NOTE on worktrees: isolation:'worktree' gives each agent a private tree on a per-agent branch.
// Those branches must be merged back into the feature branch by the integrator between waves — the
// one genuinely fiddly part. If your codebase makes worktree merge-back unreliable, fall back to a
// single executor per wave (drop isolation, run wave tasks sequentially on the feature branch);
// you lose intra-wave parallelism but keep correctness.
const waveResults = []
for (let waveIdx = 0; waveIdx < plan.waves.length; waveIdx++) {
  const wave = plan.waves[waveIdx]
  const built = (await parallel(wave.tasks.map(t => () =>
    agent(
      `Implement task ${t.id} for the goal: ${goal}.
Touch ONLY these files: ${t.files.join(', ')}. Make atomic commits on your worktree branch.
Verify locally: ${t.verify}. If you hit a blocker you cannot resolve within your files, STOP and
return {blocked:true, reason}. Do NOT improvise outside your file set.`,
      { label: `exec:w${waveIdx + 1}:${t.id}`, phase: 'Execute', isolation: 'worktree', model: 'sonnet', effort: lite ? 'low' : 'medium', schema: EXEC_SCHEMA }
    )
  ))).filter(Boolean)
  const blocked = built.find(r => r.blocked)
  if (blocked) { waveResults.push({ waveIdx, blocked: true, reason: blocked.reason }); break }
  // Integrator runs on the main feature-branch tree (no isolation) and merges the wave's per-agent
  // worktree branches. On a hard conflict it halts (replan-on-blocker).
  const merged = await agent(
    `Integrate wave ${waveIdx + 1}: merge the per-agent worktree branches for tasks
[${wave.tasks.map(t => t.id).join(', ')}] into the current feature branch (find them via
\`git branch --list 'worktree-agent-*'\` / \`git worktree list\`). Resolve only TRIVIAL conflicts.
On any hard conflict, STOP and return {blocked:true, reason}. Run a quick build/lint to confirm.`,
    { label: `integrate:w${waveIdx + 1}`, phase: 'Execute', schema: EXEC_SCHEMA }
  )
  waveResults.push({ waveIdx, blocked: !!(merged && merged.blocked), reason: merged && merged.reason })
  if (merged && merged.blocked) break
}
const hardBlock = waveResults.find(r => r.blocked)
if (hardBlock) return { blocked: true, reason: hardBlock.reason, atWave: hardBlock.waveIdx }

phase('Verify')
const VERIFY_SCHEMA = {
  type: 'object', required: ['pass', 'failures'],
  properties: { pass: { type: 'boolean' }, failures: { type: 'array', items: { type: 'string' } } },
}
let verify = null
for (let i = 0; i < (lite ? 1 : 3); i++) {
  verify = await agent(
    `Goal-backward verification (NOT task-checkbox counting). Run the repo's build + test + lint via
Bash. Then try to FALSIFY "done" for the goal: ${goal}. List concrete failures.${ultra ? ' Use multiple adversarial lenses (correctness, edge cases, regressions).' : ''}`,
    { label: `verify:${i + 1}`, phase: 'Verify', model: 'sonnet', effort: lite ? 'low' : (ultra ? 'high' : 'medium'), schema: VERIFY_SCHEMA }
  )
  log(`verify ${i + 1}: ${verify.pass ? 'PASS' : verify.failures.length + ' failures'}`)
  if (verify.pass) break
  // First corrective pass = direct fix. If failures PERSIST (i>=1), escalate to root-cause instead of
  // blind-retrying the same fix (the loop's most expensive failure mode). Use the systematic-debugging
  // skill if installed, else a hypothesis-driven debug prompt. effort bumps for the debug pass.
  const debugMode = i >= 1
  await parallel(verify.failures.map((f, k) => () =>
    agent(debugMode
      ? `This failure SURVIVED a direct fix — do NOT repeat it. Switch to ROOT-CAUSE: if the 'systematic-debugging' skill is available use it, else: reproduce the failure, isolate the cause, form ONE hypothesis, change ONE variable to test it, then fix. Commit atomically. Failure: ${f}`
      : `Fix this verification failure (atomic commit on the feature branch): ${f}`,
      // debug pass = reasoning, so inherit Opus @ high; plain fix stays on the Sonnet execute tier
      { label: `${debugMode ? 'debug' : 'fix'}:${i + 1}:${k + 1}`, phase: 'Verify', isolation: 'worktree', ...(debugMode ? { effort: lite ? 'medium' : 'high' } : { model: 'sonnet', effort: lite ? 'low' : 'medium' }), schema: EXEC_SCHEMA })
  ))
  if (verify.failures.length) {
    await agent(`Merge the corrective fix branches for round ${i + 1} into the feature branch; resolve trivial conflicts.`, { label: `integrate:fix${i + 1}`, phase: 'Verify' })
  }
}

return { built: waveResults, verify }
```

**After Workflow #2 returns (main loop):** if `blocked`, surface the reason and re-plan (re-run
Workflow #1 with the delta) — do not improvise. Otherwise run `/run` and `/verify` for real-app
behavior, then `/code-review high --fix` (or `/code-review ultra` + `/security-review` under
`--ultra`). Review findings needing code → a scoped corrective Workflow #2 run. Then release-prep.

---

## Degenerate template (triage-trivial: ≤1 file, no parallelism)

For a typo / one-liner / config tweak. Still a visible Workflow (honors "always a Workflow"), but a
single phase with one agent and no worktrees/waves/gate. The main loop runs the gate only under
`--careful`.

```js
export const meta = {
  name: 'looping-quick',
  description: 'Trivial single-file change with a quick verify',
  phases: [{ title: 'Do', detail: 'plan inline, edit, test' }],
}
// args = { slug, goal }
const { slug, goal } = args
phase('Do')
const result = await agent(
  `Small, self-contained change on the current feature branch. Goal: ${goal}.
Plan briefly inline, make the edit, commit atomically, then run the repo's tests/lint via Bash to
confirm. Return a one-paragraph summary of what changed and the test result.`,
  { label: 'quick', phase: 'Do', effort: 'medium' }
)
return { result }
```

The main loop still finishes with release-prep: write `SUMMARY.md` and print
`Merge-ready on feature/<slug>. Run /local-pr to land.`

---

## Token-cost note (honest tradeoff)

"Always a Workflow" means even small tasks spin up at least one agent — more tokens and wall-clock
than a direct edit. The triage gate keeps that cost proportional (one cheap single-agent Workflow for
trivia, the full two-Workflow loop only for real work). If a user explicitly wants a raw direct edit
with no loop, they would not invoke `/looping` — point them at a plain request.

---

# Content track templates

Same frame as the code family; the differences are: research scouts map the **docs** (not a
codebase), task `verify` is a **content acceptance check** (not a test command), execute uses a
**content agent on disjoint files with no worktrees** (markdown needs no merge-back), and verify runs
**docs-integrity** (internal links/references resolve, terminology consistent, no placeholders, style)
instead of build/test/lint. The schemas (`RESEARCH_SCHEMA`, `PLAN_SCHEMA`, `CHECK_SCHEMA`,
`EXEC_SCHEMA`, `VERIFY_SCHEMA`) are reused verbatim.

> **Worked example, adapt per repo:** the scout prompts below assume generic docs (README,
> architecture doc, CHANGELOG, spec files) and the template's own rules (`writing-style`,
> `no-placeholders`, `anti-bias`, `release-quality`). For another repo, rewrite the scout prompts to
> target *its* equivalents — its decision/spec records, style/terminology guide, doc structure — and
> use whatever review skills it provides (or the generic Workflow agent). The **structure** (discover →
> disjoint wave plan → integrity verify) is what ports; the specific file names do not.

## Content Workflow #1 — plan (`looping-plan/<slug>`, content)

```js
export const meta = {
  name: 'looping-plan-content',
  description: 'Research the docs, plan, and adversarially validate a content rollout',
  phases: [
    { title: 'Research', detail: 'parallel docs-map / consistency / style-structure scouts' },
    { title: 'Plan', detail: 'opus-class planner -> file-disjoint wave plan' },
    { title: 'Validate', detail: 'plan-checker + anti-bias + cross-file consistency lens' },
  ],
}

// args = { slug, goal, ultra: bool }
const { slug, goal, ultra, lite } = args   // depth tier from flags; lite/ultra falsy = balanced default
const READONLY = 'You have READ-ONLY tools (Read, Grep, Glob). Do NOT modify files. Cite exact file paths.'

const RESEARCH_SCHEMA = {
  type: 'object', required: ['findings', 'risks', 'openQuestions'],
  properties: {
    findings: { type: 'array', items: { type: 'string' } },
    risks: { type: 'array', items: { type: 'string' } },
    openQuestions: { type: 'array', items: { type: 'string' } },
  },
}

phase('Research')
const scouts = [
  // docs-mapper: which file holds which claim/statement that this goal touches
  () => agent(`${READONLY}\nMap the docs this goal touches: which file (README / architecture doc / CHANGELOG / spec) holds which statement. Report exact paths + the passage to change.\nGoal: ${goal}`, { label: 'research:docs-map', phase: 'Research', model: 'sonnet', schema: RESEARCH_SCHEMA }),
  // consistency: where the same term/decision appears across files, so a change stays aligned
  () => agent(`${READONLY}\nFind every place the terms, decisions, and cross-references this goal would change appear across the docs. Report each file+passage that would have to move together to stay consistent, and any internal link/reference that points at a passage being changed.\nGoal: ${goal}`, { label: 'research:consistency', phase: 'Research', model: 'sonnet', schema: RESEARCH_SCHEMA }),
  // style/structure: the rules and structure the edits must satisfy
  () => agent(`${READONLY}\nFrom .claude/rules/writing-style.md (terms/phrasing to avoid, active voice), .claude/rules/no-placeholders.md (no draft markers/TODO/placeholder text in delivered content) and the structure of the surrounding files, list the style rules, structure, and terminology this goal must satisfy.\nGoal: ${goal}`, { label: 'research:style-structure', phase: 'Research', model: 'sonnet', schema: RESEARCH_SCHEMA }),
]
if (ultra) scouts.push(
  () => agent(`${READONLY}\nAnti-bias risk scout (per .claude/rules/anti-bias.md): steelman KEEPING the current wording/decision unchanged. Where would this goal over-react to thin evidence or state an assumption as fact? Enumerate the strongest counter-arguments.\nGoal: ${goal}`, { label: 'research:anti-bias', phase: 'Research', model: 'sonnet', schema: RESEARCH_SCHEMA })
)
const research = (await parallel(scouts)).filter(Boolean)
await agent(`Write a tight merged research brief to .loop/${slug}/research.md from this JSON. Dedupe, lead with risks + consistency flags, list the exact files+passages to touch.\n${JSON.stringify(research)}`, { label: 'research:write', phase: 'Research' })

const PLAN_SCHEMA = {
  type: 'object', required: ['waves', 'risks', 'rollback'],
  properties: {
    waves: { type: 'array', items: {
      type: 'object', required: ['tasks'],
      properties: { tasks: { type: 'array', items: {
        type: 'object', required: ['id', 'files', 'deps', 'verify'],
        properties: {
          id: { type: 'string' },
          files: { type: 'array', items: { type: 'string' } },
          deps: { type: 'array', items: { type: 'string' } },
          verify: { type: 'string' }, // content acceptance check, NOT a test command
        },
      } } },
    } },
    risks: { type: 'array', items: { type: 'string' } },
    rollback: { type: 'string' },
  },
}

phase('Plan')
let plan = await agent(
  `You are the content planner. Read .loop/${slug}/goal.md and .loop/${slug}/research.md. Produce a file-disjoint wave plan.
RULES: waves ordered (foundation docs like CLAUDE.md / the central architecture doc first, then dependent pages like READMEs / CHANGELOG / specs); tasks WITHIN a wave MUST touch disjoint files. Each task: exact file paths, deps (task ids), and a concrete content acceptance \`verify\` (e.g. "internal reference resolves", "terminology matches the other touched files", "no contradiction with <doc>", "markdown valid", "no draft marker/placeholder per no-placeholders", "style per writing-style"). Include a rollback (which files revert).
Goal: ${goal}`,
  { label: 'plan:author', phase: 'Plan', effort: lite ? 'medium' : 'high', schema: PLAN_SCHEMA }
)

phase('Validate')
const CHECK_SCHEMA = {
  type: 'object', required: ['verdict', 'blockers', 'waveSafety'],
  properties: {
    verdict: { enum: ['pass', 'revise'] },
    blockers: { type: 'array', items: { type: 'string' } },
    waveSafety: { type: 'boolean' },
  },
}
let verdict = null
for (let i = 0; i < (lite ? 1 : 3); i++) {
  verdict = await agent(
    `Adversarially review this content wave plan. Classify issues BLOCKER/WARN. Check: every wave's tasks are file-disjoint (waveSafety); no missing deps; every task's verify is a real content check; rollback present. ANTI-BIAS LENS (.claude/rules/anti-bias.md): does any task override wording/a decision that the research flagged as thin-evidence WITHOUT steelmanning it first? PLACEHOLDER LENS (.claude/rules/no-placeholders.md): does the plan leave any draft marker/TODO/placeholder in delivered content? CONSISTENCY LENS: do the edits keep terminology + internal references consistent across all touched files, with no contradiction between documents?${ultra ? ' Then seek a cross-AI second opinion before passing if such a tool is available.' : ''}
PLAN: ${JSON.stringify(plan)}`,
    { label: `validate:${i + 1}`, phase: 'Validate', effort: lite ? 'medium' : 'high', schema: CHECK_SCHEMA }
  )
  log(`validate ${i + 1}: ${verdict.verdict} (${verdict.blockers.length} blockers)`)
  if (verdict.verdict === 'pass') break
  plan = await agent(
    `Revise the plan to clear these blockers (targeted, do not replan from scratch):\n${verdict.blockers.join('\n')}\nPLAN: ${JSON.stringify(plan)}`,
    { label: `replan:${i + 1}`, phase: 'Validate', effort: lite ? 'medium' : 'high', schema: PLAN_SCHEMA }
  )
}
await agent(`Write the final validated plan to .loop/${slug}/plan.md (human-readable: waves, files, deps, verify-checks, risks, rollback).\n${JSON.stringify(plan)}`, { label: 'plan:write', phase: 'Validate' })

return { plan, verdict, researchCount: research.length }
```

**After Content Workflow #1 returns (main loop):** unless `--auto`, `EnterPlanMode` with a tight
render of the plan (which statements change, which files, cross-reference/consistency impact, rollback) for sign-off.

## Content Workflow #2 — build (`looping-build/<slug>`, content)

```js
export const meta = {
  name: 'looping-build-content',
  description: 'Execute a validated content plan in disjoint waves, then docs-integrity verify',
  phases: [
    { title: 'Execute', detail: 'parallel content agents, disjoint files, no worktree' },
    { title: 'Verify', detail: 'docs-integrity + contradiction falsification' },
  ],
}

// args = { slug, goal, plan, ultra }
const { slug, goal, plan, ultra, lite } = args   // depth tier from flags; lite/ultra falsy = balanced default

const EXEC_SCHEMA = {
  type: 'object', required: ['done', 'blocked'],
  properties: { done: { type: 'boolean' }, blocked: { type: 'boolean' }, reason: { type: 'string' } },
}

phase('Execute')
// Sequential waves (foundation docs before dependent pages). Tasks within a wave are file-disjoint,
// so parallel() is safe WITHOUT worktrees — markdown has no build/merge-back. The content agent edits
// its files (consistent terminology + internal references + atomic commits) directly on the feature
// branch. No integrator needed.
const waveResults = []
for (let waveIdx = 0; waveIdx < plan.waves.length; waveIdx++) {
  const wave = plan.waves[waveIdx]
  const built = (await parallel(wave.tasks.map(t => () =>
    agent(
      `Implement content task ${t.id} for the goal: ${goal}.
Edit ONLY these files: ${t.files.join(', ')}. Follow the repo rules: active voice + avoided terms
(.claude/rules/writing-style.md); NO draft markers/TODO/placeholder text in delivered content
(.claude/rules/no-placeholders.md — never invent a fact to fill a gap; if something is genuinely
unknown, stop and surface it). Match the structure and terminology of the surrounding files, and keep
every internal link/reference resolving. Honor the repo's language rule (.claude/rules/code-language.md)
in committed files. Make atomic commits on the feature branch. Acceptance: ${t.verify}. If you hit a
blocker you cannot resolve within your files (e.g. a needed fact is missing, or the change would
contradict a document you were not asked to touch), STOP and return {blocked:true, reason}. Do NOT
improvise outside your files.`,
      { label: `exec:w${waveIdx + 1}:${t.id}`, phase: 'Execute', model: 'sonnet', effort: lite ? 'low' : 'medium', schema: EXEC_SCHEMA }
    )
  ))).filter(Boolean)
  const blocked = built.find(r => r.blocked)
  if (blocked) { waveResults.push({ waveIdx, blocked: true, reason: blocked.reason }); break }
  waveResults.push({ waveIdx, blocked: false })
}
const hardBlock = waveResults.find(r => r.blocked)
if (hardBlock) return { blocked: true, reason: hardBlock.reason, atWave: hardBlock.waveIdx }

phase('Verify')
const VERIFY_SCHEMA = {
  type: 'object', required: ['pass', 'failures'],
  properties: { pass: { type: 'boolean' }, failures: { type: 'array', items: { type: 'string' } } },
}
let verify = null
for (let i = 0; i < (lite ? 1 : 3); i++) {
  verify = await agent(
    `Goal-backward docs verification (NOT task-checkbox counting) for the goal: ${goal}.
Check across ALL touched files: (1) markdown valid; (2) every internal link/reference resolves;
(3) style scan clean (grep the avoided terms from writing-style, active voice); (4) NO draft
markers/TODO/placeholder text remains (no-placeholders); (5) FALSIFY "done": does any edit contradict
another document it did not explicitly address, use terminology inconsistent with the other touched
files, or leave a stranded reference? List concrete failures with file:line.${ultra ? ' Use multiple adversarial lenses (cross-file consistency, anti-bias over-reach, reference drift).' : ''}`,
    { label: `verify:${i + 1}`, phase: 'Verify', model: 'sonnet', effort: lite ? 'low' : (ultra ? 'high' : 'medium'), schema: VERIFY_SCHEMA }
  )
  log(`verify ${i + 1}: ${verify.pass ? 'PASS' : verify.failures.length + ' failures'}`)
  if (verify.pass) break
  await parallel(verify.failures.map((f, k) => () =>
    agent(`Fix this docs verification failure (atomic commit on the feature branch, honor the repo language rule in committed files): ${f}`,
      { label: `fix:${i + 1}:${k + 1}`, phase: 'Verify', model: 'sonnet', effort: lite ? 'low' : 'medium', schema: EXEC_SCHEMA })
  ))
}

return { built: waveResults, verify }
```

**After Content Workflow #2 returns (main loop):** if `blocked`, surface the reason and re-plan — do
not improvise. Otherwise run a docs-consistency + style/placeholder pass on the touched files (internal
links/references resolve, terminology consistent, no contradictions, `no-placeholders`, `writing-style`),
plus any repo review skill, for depth. Findings needing changes → a scoped corrective Content
Workflow #2 run. Then release-prep (`SUMMARY.md`, STOP, the repo's merge path).
