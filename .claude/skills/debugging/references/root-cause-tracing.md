# Root Cause Tracing

## Overview

Bugs often manifest deep in the call stack (git init in the wrong directory, a file in the wrong location, a DB opened with the wrong path). Your instinct says: fix it where the error appears. That's symptom treatment.

**Core principle:** Trace backward through the call chain to the original trigger, then fix at the source.

## When to Use

**Use when:**
- Error deep in execution (not at the entry point)
- Stack trace shows a long call chain
- Unclear where invalid data comes from
- Looking for which test/code triggers the problem

**Typical examples:**
- "Client error in the UI" — where does the stream error really originate?
- "Import fails in the worker" — who imported the lib?
- "Secret read fails with 401" — at which layer does the auth material arrive?

## The Tracing Process

### 1. Observe the Symptom
```
Error: "Connection error" in the UI render
```

### 2. Find Immediate Cause
**Which code directly causes it?**
```typescript
// ChatView.tsx line 919
{Boolean(error) && <p>Connection error. Please try again.</p>}
```

### 3. Ask: Who set error?
```
Client error state
  ← set by the stream consumer
  ← on a TypeError while reading from the stream
  ← the stream comes from Transport.sendMessages()
```

### 4. Keep Tracing Up
**What was actually delivered?**
- Transport returned `createStream(...)` but cast as `ReadableStream<never>`
- The consumer expects typed frames but gets something incompatible
- The cast obscures the TypeScript mismatch

### 5. Find Original Trigger
**Where did the type cast originate?**
```typescript
// Transport.ts
return createStream({...}) as ReadableStream<never>;
//                         ^^^^^^^^^^^^^^^^^^^^^^^^
// This is the lie that calms the compiler but breaks at runtime
```

## Adding Stack Traces

If you can't trace manually, add instrumentation:

### Frontend (TypeScript)
```typescript
// Before the problematic operation
function sendMessages(...) {
  const stack = new Error().stack;
  console.error('DEBUG sendMessages:', { args, stack });
  // ...
}
```

### Backend (Python)
```python
import traceback

def main(...):
    print(f"DEBUG main called from:\n{''.join(traceback.format_stack())}")
    # ...
```

**Critical:** Use `console.error()` in tests (not logger — it can be suppressed)

## Trace Patterns

### Pattern: "Worker does the wrong thing"
```
Symptom: reply is "Mock" instead of real output
  ↓ Who triggered the worker?
Job history (queue/API): job 12345 ran on worker abc-1
  ↓ Which image ran abc-1?
docker inspect: registry/worker:1.2.3-abcdef
  ↓ Was the volume mounted?
docker inspect --format '{{json .Mounts}}': /data missing!
  ↓ When was the mount lost?
git log --oneline -- docker-compose.yml: no change
  ↓ When was the last restart?
docker inspect --format '{{.State.StartedAt}}': 3min ago after redeploy
ROOT CAUSE: the redeploy drops bind mounts
```

### Pattern: "Stream breaks in the browser"
```
Symptom: client error despite HTTP 200
  ↓ What comes from the server?
curl + tcpdump: JSON body, Content-Type: application/json
  ↓ What does the client expect?
SDK docs: a stream of typed frames
  ↓ What does the transport send?
Lookup Transport.ts: createStream({execute:...})
  ↓ Is the type cast being abused?
`as ReadableStream<never>` ← LIE
ROOT CAUSE: stream type mismatch obscured by a type assertion
```

## Real Example: Volume-Mount Loss

**Symptom:** Worker raised `RuntimeError: Config not found at /data/flow.json`

**Trace chain:**
1. Handler raised RuntimeError
2. Path `/data/flow.json` existed host-side
3. `docker inspect` showed: bind mount missing in the running container
4. Compose file defined the mount correctly
5. Last container op: a redeploy
6. Checking other containers: same image, same hash, no mount

**Root cause:** The redeploy changes the container spec without a `compose-up --build` equivalent — mounts are lost.

**Fix at source:** `compose-stop` + `compose-start` instead of redeploy.

**Defense in depth additionally:**
- Layer 1: Handler throws an explicit RuntimeError with a path hint
- Layer 2: Healthcheck in the container verifies `/data` is reachable
- Layer 3: Documentation (gotcha: a redeploy can lose mounts)
- Layer 4: Recovery pattern documented

## Key Principle

**NEVER fix only where the error appears.** Trace back to the original trigger.

```
Bug appears
  ↓
Found immediate cause
  ↓
Can trace one level up? ── No → Fix at symptom (last resort)
  ↓ Yes
Trace backwards
  ↓
Is this the source? ── No → Trace backwards (recursive)
  ↓ Yes
Fix at source
  ↓
Add validation at each layer (defense-in-depth)
  ↓
Bug structurally impossible
```

## Stack Trace Tips

**In tests:** `console.error()` not logger — logger can be suppressed
**Before operation:** Log BEFORE the dangerous operation, not after failure
**Include context:** Directory, cwd, env vars, timestamps
**Capture stack:** `new Error().stack` shows the complete call chain

## Useful Tools

| Tool | Purpose |
|----------|-------|
| `git log --oneline -20` | Recent changes |
| `git blame <file> -L<line>` | Who changed this line |
| `docker inspect <container>` | Container state, mounts, env |
| Job/queue CLI or API | Which worker ran the job |
| Browser-automation MCP (network) | Browser network trace |
| Browser-automation MCP (console) | Browser console output |
| Context7 `query-docs` | Verify library behavior |
