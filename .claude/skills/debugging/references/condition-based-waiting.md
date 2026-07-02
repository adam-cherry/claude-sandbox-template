# Condition-Based Waiting

## Overview

Flaky tests often guess at timing with arbitrary delays. That creates race conditions where tests pass on fast machines but fail under load or in CI.

**Core principle:** Wait for the actual condition you want, not for a guess at how long it takes.

## When to Use

**Use when:**
- Tests have arbitrary delays (`setTimeout`, `sleep`, `time.sleep()`)
- Tests are flaky (pass sometimes, fail under load)
- Tests time out when run in parallel
- Waiting for async operations that should complete

**Don't use when:**
- You're testing actual timing behavior (debounce, throttle intervals)
- Always document WHY when using an arbitrary timeout

## Core Pattern

### TypeScript / Frontend

```typescript
// BEFORE: Guessing at timing
await new Promise(r => setTimeout(r, 50));
const result = getResult();
expect(result).toBeDefined();

// AFTER: Waiting for a condition
await waitFor(() => getResult() !== undefined);
const result = getResult();
expect(result).toBeDefined();
```

### Python / Backend

```python
# BEFORE: arbitrary sleep
import time
time.sleep(2)
result = fetch_result()
assert result is not None

# AFTER: condition-based polling
import time
def wait_for(condition, timeout=5.0, poll_interval=0.05):
    start = time.monotonic()
    while time.monotonic() - start < timeout:
        result = condition()
        if result:
            return result
        time.sleep(poll_interval)
    raise TimeoutError(f'Condition not met after {timeout}s')

result = wait_for(lambda: fetch_result())
assert result is not None
```

## Quick Patterns

| Scenario | Pattern |
|----------|---------|
| Wait for event | `waitFor(() => events.find(e => e.type === 'DONE'))` |
| Wait for state | `waitFor(() => machine.state === 'ready')` |
| Wait for count | `waitFor(() => items.length >= 5)` |
| Wait for file | `waitFor(() => fs.existsSync(path))` |
| Wait for HTTP | `waitFor(async () => (await fetch(url)).status === 200)` |
| Wait for container | `waitFor(() => execSync('docker ps').includes('healthy'))` |
| Complex condition | `waitFor(() => obj.ready && obj.value > 10)` |

## Implementation (TypeScript)

```typescript
async function waitFor<T>(
  condition: () => T | undefined | null | false | Promise<T | undefined | null | false>,
  description: string,
  timeoutMs = 5000,
): Promise<T> {
  const startTime = Date.now();
  while (true) {
    const result = await condition();
    if (result) return result as T;
    if (Date.now() - startTime > timeoutMs) {
      throw new Error(`Timeout waiting for ${description} after ${timeoutMs}ms`);
    }
    await new Promise(r => setTimeout(r, 10));
  }
}
```

## Practical Patterns

### Pattern: Wait for job completion (queue / background worker)

```python
import time
import requests

def wait_for_job(job_id: str, base_url: str, token: str, timeout: float = 30.0):
    start = time.monotonic()
    while time.monotonic() - start < timeout:
        r = requests.get(
            f'{base_url}/api/jobs/{job_id}',
            headers={'Authorization': f'Bearer {token}'},
        )
        r.raise_for_status()
        data = r.json()
        if data.get('status') == 'completed':
            return data
        time.sleep(0.5)
    raise TimeoutError(f'job {job_id} not completed after {timeout}s')
```

**Anti-pattern:** `time.sleep(10)` and then assuming the job is done.

### Pattern: Wait for Docker container health

```bash
# BEFORE
sleep 30 && docker exec container curl http://localhost:8086/health

# AFTER
until docker exec container curl -fs http://localhost:8086/health 2>/dev/null; do
  sleep 1
done
```

With a timeout cap:
```bash
timeout 60 bash -c 'until docker exec container curl -fs http://localhost:8086/health 2>/dev/null; do sleep 1; done'
```

### Pattern: Wait for frontend hydration (Playwright)

```typescript
// BEFORE
await page.goto(url);
await page.waitForTimeout(2000);  // Hoping React has mounted
await page.click('#chat-input');

// AFTER
await page.goto(url);
await page.waitForSelector('#chat-input:not([disabled])', { state: 'attached' });
await page.click('#chat-input');
```

### Pattern: Wait for stream completion

```typescript
// In tests for streaming responses
async function waitForStreamComplete(messages: Message[], timeoutMs = 10_000) {
  return waitFor(
    () => {
      const last = messages[messages.length - 1];
      return last?.role === 'assistant' && last?.parts?.every(p =>
        p.type !== 'text' || p.state === 'complete'
      );
    },
    'assistant stream to complete',
    timeoutMs,
  );
}
```

## Common Mistakes

**WRONG: Polling too fast**
```typescript
setTimeout(check, 1)  // CPU waste
```
**RIGHT:** Poll every 10ms (TypeScript) or 50ms (Python).

**WRONG: No timeout**
```typescript
while (!ready) {} // Loops forever if the condition is never met
```
**RIGHT:** Always include a timeout with a clear error message.

**WRONG: Stale data**
```typescript
const data = obj.value;
while (data < 10) { /* obj.value updated, but data stays stale */ }
```
**RIGHT:** Call the getter inside the loop, don't cache it.

**WRONG: Polling without backoff on network**
```python
while True:
    if requests.get(url).ok: break  # Hammers the server on failure
```
**RIGHT:** Exponential backoff for network calls.

## When Arbitrary Timeout IS Correct

```typescript
// Tool ticks every 100ms — need 2 ticks for partial output
await waitForEvent(manager, 'TOOL_STARTED');  // First: condition-wait
await new Promise(r => setTimeout(r, 200));    // Then: timed behavior
// 200ms = 2 ticks at 100ms — documented and justified
```

**Requirements:**
1. First wait for the triggering condition
2. Based on known timing (not guessing)
3. A comment explains WHY

## Anti-pattern: Deploy + fixed sleep

```bash
# WRONG: in Makefile / CI
deploy-service
sleep 30  # "wait for the deployment to go through"
curl -X POST $URL/api/endpoint ...
```

**RIGHT:**
```bash
deploy-service
# Poll the API until the service is reachable/updated
until curl -fs "$URL/health" 2>/dev/null; do
  sleep 1
done
curl -X POST $URL/api/endpoint ...
```
