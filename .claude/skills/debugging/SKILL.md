---
name: debugging
description: >
  Systematic debugging for any stack (backend + services + frontend).
  Enforces root-cause-first methodology, hypothesis validation, and targeted
  diagnostics before any fix is attempted. Use when: ANY unexpected behavior — wrong
  outputs, mock fallbacks, missing logs, stale data, container issues, workflow
  failures, broken streams, connection errors despite a working API. Use ESPECIALLY
  when: a previous fix did not work, the debug session is going in circles, or >2
  fixes were attempted without root-cause clarity. Prevents the #1 anti-pattern:
  guessing and fixing without understanding.
---

# Systematic Debugging

## Why this skill exists

Born out of real sessions where we lost hours to:
- Assuming the wrong root cause without verification
- Removing diagnostic logs too early
- Random fixes instead of research
- Never verifying WHO actually executes the code
- Stacking 5+ fixes on top of each other instead of questioning the architecture

10 minutes of research + 1 targeted diagnostic query would have found the root cause immediately. This skill prevents these mistakes — through a strict phase model.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Haven't finished Phase 1? You may not propose any fixes. Symptom fixes are FAILURE.

**To violate the letter of this process is to violate the spirit of debugging.**

## The Iron Rules

1. **Research before you touch code.** 10 min reading docs beats 2 hrs of trial-and-error.
2. **Logs go IN, never come OUT** during debugging. Add instrumentation and LEAVE it.
3. **One hypothesis, one test.** Never change multiple things at once.
4. **Verify WHO executes, not just WHAT executes.** In distributed systems the wrong process can handle your request.
5. **Challenge "obvious" explanations.** If your hypothesis requires exotic behavior from well-tested infrastructure (container runtime, database, HTTP framework, SDK) — you're probably wrong.
6. **After 3 failed fixes: STOP and question architecture.** A pattern indicating an architectural problem outweighs further fix attempts.

## When to Use

Use for ANY technical issue:
- Test failures
- Bugs in production / dev / local
- Unexpected behavior
- Performance problems
- Build/deploy failures
- Integration issues
- Streams that break / browser errors despite a working API
- Race conditions / flaky tests

**Use ESPECIALLY when:**
- Under time pressure (emergencies make guessing tempting — but systematic is faster)
- "Just one quick fix" seems obvious
- You've already tried several fixes
- A previous fix didn't work
- You don't fully understand the issue

**Don't skip when:**
- The issue seems simple (simple bugs have root causes too)
- You're in a hurry (rushing guarantees rework)
- The user wants it fixed NOW (systematic is faster than thrashing)

## The Six Phases

You MUST complete each phase before moving to the next.

### Phase 0: Stop and Think (before any touch)

When a bug appears — resist the urge to fix it immediately. Instead:

1. **Describe the bug in one sentence.** If you can't, you haven't understood it.
2. **What SHOULD happen?** Trace the expected flow: Request → Server → Worker → Handler → Response.
3. **What ACTUALLY happens?** Be precise. "Connection error" is vague. "Client error state with message='X' on response read despite HTTP 200 from the endpoint" is precise.
4. **What changed recently?** `git log --oneline -10`, container restarts, config changes, new processes started.

### Phase 1: Instrument (visibility BEFORE investigation)

You can't debug what you can't see. Before ANY investigation:

#### Backend (Python)
```python
# Function / Handler-level
print(f"DEBUG handle_request(): provider={provider} model={model} key_len={len(key)}")

# Worker/Process startup
logger.info(f"Worker starting: WORKER_TAGS={os.environ.get('WORKER_TAGS')}")

# File-based logging (survives container restarts)
import logging
fh = logging.FileHandler("/tmp/worker.log", mode="a")
logging.getLogger().addHandler(fh)
```

#### Frontend (JavaScript / TypeScript)
```typescript
// Stream/Response-Layer Debug
console.error('DEBUG response error:', { error, stack: error?.stack });

// Transport-Layer
console.error('DEBUG transport send:', {
  url, status: response.status, headers: [...response.headers]
});

// Network-Tap
window.fetch = new Proxy(window.fetch, {
  apply(target, thisArg, args) {
    console.error('DEBUG fetch:', args[0], args[1]);
    return Reflect.apply(target, thisArg, args);
  },
});
```

**Never remove these logs during debugging.** They are your eyes. Removing them for "cleanup" and then having to re-add them wastes time and destroys continuity.

### Phase 2: Research (BEFORE hypotheses)

This is where most debugging goes wrong — jumping straight to "I think the problem is X" without checking whether X is even possible.

#### Check the docs first
Before you blame a framework (container runtime, database, SDK), verify whether your assumption is theoretically possible:
- Will `docker compose restart` build a new image? (No — same container, same image)
- Does the HTTP client really fail on this response type? (Check the docs)
- Can a reverse proxy buffer chunked-encoded streams? (Check the proxy docs)

#### Where to research
1. **Context7 MCP** — `resolve-library-id` + `query-docs` for SDK behavior
2. **MCP server for the cloud/docs in use** (e.g. Microsoft Learn MCP for Azure/Microsoft stack)
3. **Official docs** — straight from the library source
4. **GitHub Issues** — known bugs in the version
5. **The codebase itself** — `git log`, `git blame`, search for similar patterns

#### Document what you learn
Record findings BEFORE you continue. Prevents repeating the same research when the session spans multiple conversations.

### Phase 3: Pattern Analysis (find a working example)

Before you fix: compare against something that works.

1. **Find working examples**
   - Locate similar working code in the same codebase
   - What works that is similar to what's broken?
   - Example: it works on local — what's different on dev?

2. **Compare against references**
   - When you implement a pattern, read the reference implementation COMPLETELY
   - Don't skim — read every line
   - Understand the pattern fully before you apply it
   - Example: read the SDK docs completely, don't just copy a code snippet

3. **Identify differences**
   - What is different between working and broken?
   - List EVERY difference, no matter how small
   - Don't assume "that surely can't be relevant"
   - Example: local has `BASE_URL=http://localhost:8000`, dev has `BASE_URL=http://api_server:8000` — relevant?

4. **Understand dependencies**
   - What other components does it need?
   - Which settings, config, environment?
   - What assumptions does it make?

### Phase 4: Diagnose (targeted checks)

Run diagnostics in order. Each eliminates a category of causes.

#### Check 1: WHO executes?

In distributed systems the wrong process can execute your code. Invisible in local logs.

```bash
# Which container responds?
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# Which worker/process ran the job? (job history of the queue/API)
curl -s "$BASE/api/jobs?running=true" -H "Authorization: Bearer $TOKEN" | jq

# Which process hosts the dev server?
docker exec <service> ps aux | grep -E "node|python"

# Rogue local processes
ps aux | grep -E "<service-name>" | grep -v grep
```

#### Check 2: Code up to date?

```bash
# Container image hash
docker inspect <container> --format '{{.Image}}'

# Code mounted or built into the image?
docker inspect <container> --format '{{json .Mounts}}' | jq

# Dependency drift local vs dev
docker exec <container> cat /app/node_modules/<lib>/package.json | grep version
```

#### Check 3: Config correct?

```bash
# Env vars in the container
docker exec <container> env | grep -E "BASE_URL|API_KEY"

# Compare config drift between environments
diff <(docker exec <container-a> env | sort) <(docker exec <container-b> env | sort)
```

#### Check 4: Code in isolation?

Backend (direct call):
```bash
# Call the endpoint directly (bypasses frontend/proxy)
curl -s -X POST http://<host>:8000/api/endpoint -d '{"payload":"Test"}' --max-time 30

# Direct curl against the dev proxy
curl -s -X POST http://<host>:5173/api/endpoint -d '{"payload":"Test"}' --max-time 30
```

Frontend (browser):
```typescript
// Direct fetch in the browser (bypasses client wrapper/transport)
fetch('/api/endpoint', { method: 'POST', body: '...' }).then(r => r.json()).then(console.log)

// Stream reader test
const reader = (await fetch('/api/stream')).body.getReader();
while (true) { const { value, done } = await reader.read(); if (done) break; console.log(value); }
```

Does this work? → The problem is in the wrapper (transport, client layer), not in the API. Back to Phase 3.

#### Check 5: Logs where expected?

```bash
# Docker logs (truncated after restart)
docker compose logs <service> --tail 100

# File-based logs
docker exec <container> cat /tmp/worker.log

# Browser console (browser-automation MCP, e.g. Playwright/Chrome DevTools)

# Network layer (browser-automation MCP)
```

Backend logs missing but the workflow completed → the code ran elsewhere (Check 1).

### Phase 5: Hypothesize and Test

Only NOW — after instrumenting, research, pattern analysis, diagnostics — form a hypothesis.

#### State it precisely
- **Bad:** "I think the SDK caches something."
- **Good:** "I think the transport produces a ReadableStream<Chunk> but casts it to ReadableStream<never>; the consumer reads it via for-await-of and breaks because the TypeScript type cast doesn't match any runtime frame."

#### Test with the smallest possible change
- Hypothesis "wrong process": check event history identity
- Hypothesis "stale code": insert `raise RuntimeError("CANARY")`, see if it triggers
- Hypothesis "missing env var": log the var at the exact use point
- Hypothesis "type cast breaks stream": remove the cast, see what TypeScript / runtime says

#### If the hypothesis is wrong
Don't stack another fix on top. Back to Phase 4 and gather more evidence. **After 3 failed hypotheses: STOP — see Phase 6 Step 5.**

### Phase 6: Implementation

Fix the root cause, not the symptom:

1. **Create a failing test case**
   - Simplest possible reproduction
   - Automated test if possible
   - One-off script if there's no test framework
   - MUST exist BEFORE the fix
   - Skill: `superpowers:test-driven-development`

2. **Implement a single fix**
   - Address the identified root cause
   - ONE change at a time
   - No "while I'm here" improvements
   - No bundled refactoring

3. **Verify the fix**
   - Does the test pass now?
   - Are other tests not broken?
   - Is the issue really solved?

4. **Add defense-in-depth**
   - Validation at EVERY layer where data passes
   - Makes the bug structurally impossible
   - See `references/defense-in-depth.md`

5. **If the fix doesn't work — question the architecture**

   **Pattern indicating an architectural problem:**
   - Every fix reveals new shared state / coupling / a problem somewhere else
   - Fixes require "massive refactoring"
   - Every fix creates new symptoms elsewhere

   **STOP and question the fundamentals:**
   - Is the pattern fundamentally sound?
   - Are we holding onto it "out of pure inertia"?
   - Should we refactor the architecture vs fix symptoms?

   **Discuss with the user BEFORE you attempt fix #4.**

   This is NOT a failed hypothesis — this is a wrong architecture.

6. **Leave diagnostic logging in place**
   - Costs nothing, saves hours next time
   - Document root cause + why

## Red Flags — STOP and Follow Process

If you hear yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before the data flow has been traced
- **"One more fix attempt" (when already tried 2+)**
- **Each fix reveals new problem in different place**

**ALL of these mean: STOP. Back to Phase 1.**

## User Signals — You're doing it wrong

Watch for these redirections:
- **"Is that not happening?"** — You assumed without verifying
- **"Will it show us...?"** — You should have built in evidence-gathering
- **"Stop guessing"** — You're proposing fixes without understanding
- **"Ultrathink this"** — Question the fundamentals, not the symptoms
- **"We're stuck?"** (frustrated) — Your approach isn't working
- **"Before you go into debugging..."** — You wanted to fix directly, but should structure it

**If you see these: STOP. Back to Phase 1.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, I don't need a process" | Simple issues have root causes too. The process is fast for simple bugs. |
| "Emergency, no time for a process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Let me try this first, then investigate" | The first fix sets the pattern. Do it right immediately. |
| "I'll write the test after confirming the fix works" | Untested fixes don't hold. Test-first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Creates new bugs. |
| "The reference is too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding the root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question the pattern, don't keep fixing. |

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **0. Stop+Think** | Bug in 1 sentence, what should vs what happens, what changed | Clear bug statement |
| **1. Instrument** | Logs at entry points (NEVER remove during debug) | Visibility established |
| **2. Research** | Docs/Context7/Issues, assumption theoretically possible? | Hypothesis is plausible |
| **3. Pattern** | Working examples, diffs, dependencies | Differences identified |
| **4. Diagnose** | WHO/Code/Config/Isolation/Logs | Category eliminated |
| **5. Hypothesis** | ONE theory, test MINIMALLY | Confirmed or new hypothesis |
| **6. Implementation** | Test → Fix → Verify → Defense-in-Depth → Docs | Bug structurally impossible |

```
BUG APPEARS
    │
    ▼
[Phase 0] Bug describable in one sentence?
    │ No → gather more info
    │ Yes ↓
[Phase 1] Logging at entry points (NEVER remove during debug)
    │
    ▼
[Phase 2] Research: assumption theoretically possible?
    │ Context7/Docs/Issues
    │ Record findings
    │
    ▼
[Phase 3] Pattern Analysis: working example + differences
    │
    ▼
[Phase 4] Targeted diagnostics:
    │ 1. WHO executes? (container/worker identity)
    │ 2. Code up to date? (rebuild vs restart)
    │ 3. Config correct? (env vars in the container)
    │ 4. Code in isolation? (direct call)
    │ 5. Logs where expected? (file vs docker log)
    │
    ▼
[Phase 5] ONE hypothesis, ONE test
    │ 3x failed? → STOP, question the architecture
    │
    ▼
[Phase 6] Test-first fix → defense-in-depth → docs
```

## When Process Reveals "No Root Cause"

When systematic investigation shows: the issue really is environmental, timing-dependent, external:

1. You've completed the process
2. Document what you investigated
3. Implement appropriate handling (retry, timeout, error message)
4. Add monitoring/logging for future investigation

**But:** 95% of "no root cause" cases are incomplete investigation.

## Supporting Techniques

Detailed in `references/`:

- **`references/root-cause-tracing.md`** — Trace bugs backward through the call stack to the original trigger
- **`references/defense-in-depth.md`** — Validation at multiple layers after the root-cause fix
- **`references/condition-based-waiting.md`** — Replace arbitrary timeouts with condition polling

**Related skills:**
- `superpowers:test-driven-development` — Create a failing test case (Phase 6 Step 1)
- `superpowers:verification-before-completion` — Fix verification before claiming "done"

## Anti-patterns (from real experience)

| What we did wrong | What we should have done |
|-------------------|--------------------------|
| Assumed "framework caches results" without checking | 10 min docs → impossible. Force a different hypothesis. |
| Removed debug logs after every test | Left them permanently — they're infrastructure, not clutter |
| Expected `docker compose restart` to load new code | `docker compose up -d --build` — restart only reloads env |
| Blamed the framework for exotic behavior | Check WHO actually executes the code (identity/container) |
| Interpreted a volume nuke as "cache clear" | Realized it was only a force-rebuild |
| 5+ random fixes before research | Research-first would have found the answer in 10 min |
| Never checked for rogue local processes | `ps aux \| grep <name>` would have found the culprit instantly |
| Accepted `as ReadableStream<never>` type cast as a "TypeScript trick" | Treat the cast as a smell → stream type mismatch as hypothesis |
| Ignored lost volume mount after container redeploy | `docker inspect --format '{{json .Mounts}}'` as a standard check |

## Real-World Impact

From real sessions:
- Systematic approach: 15-30 min to fix
- Random fixes: 2-3 hrs of thrashing
- First-time fix rate: 95% vs 40%
- New bugs introduced: nearly zero vs frequent
