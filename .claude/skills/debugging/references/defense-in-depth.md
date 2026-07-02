# Defense-in-Depth Validation

## Overview

When you fix a bug caused by invalid data, validation at ONE place feels sufficient. But that single check can be bypassed by other code paths, refactoring, or mocks.

**Core principle:** Validate at EVERY layer where data passes. Make the bug structurally impossible.

## Why Multiple Layers

- Single validation: "We fixed the bug"
- Multiple layers: "We made the bug impossible"

Different layers catch different cases:
- Entry validation catches most bugs
- Business logic catches edge cases
- Environment guards prevent context-specific dangers
- Debug logging helps when other layers fail

## The Four Layers

### Layer 1: Entry-Point Validation
**Purpose:** Reject obviously invalid input at the API boundary

#### Frontend (TypeScript)
```typescript
function sendChatMessage(message: string, sessionId: string) {
  if (!message || message.trim() === '') {
    throw new Error('message cannot be empty');
  }
  if (!sessionId || !/^[a-z0-9-]+$/.test(sessionId)) {
    throw new Error(`invalid sessionId: ${sessionId}`);
  }
  // ... proceed
}
```

#### Backend (Python / Pydantic)
```python
from pydantic import BaseModel, Field, field_validator

class ChatInput(BaseModel):
    session_id: str = Field(..., min_length=1, max_length=64)
    messages: list[Message] = Field(..., min_length=1)

    @field_validator('session_id')
    def validate_session_id(cls, v: str) -> str:
        if not v.replace('-', '').isalnum():
            raise ValueError(f'invalid session_id: {v}')
        return v
```

### Layer 2: Business-Logic Validation
**Purpose:** Ensure the data makes sense for this operation

```python
def process_order(order: Order, config: OrderConfig) -> OrderResult:
    if not config.line_items:
        raise ValueError('order requires at least one line item')
    if order.currency != config.expected_currency:
        raise ValueError(
            f'currency mismatch: order={order.currency} config={config.expected_currency}'
        )
    # ... proceed
```

### Layer 3: Environment-Guards
**Purpose:** Prevent dangerous operations in specific contexts

```python
def write_secret(secret_name: str, value: str) -> None:
    # In tests, never write to the real secret store
    if os.environ.get('PYTEST_CURRENT_TEST'):
        raise RuntimeError(
            f'Refusing secret write in pytest: {secret_name}. Mock the client instead.'
        )
    # In dev/prd, never write secrets with a "test" prefix
    if secret_name.startswith('test-'):
        raise ValueError(f'test-prefixed secrets are forbidden in {os.environ.get("ENV")}')
    # ... proceed
```

```typescript
// Frontend: never hardcoded URLs in production
function buildApiUrl(path: string) {
  const baseUrl = import.meta.env.VITE_API_BASE_URL;
  if (import.meta.env.PROD && baseUrl?.includes('localhost')) {
    throw new Error('localhost URL in production build — env not configured');
  }
  return new URL(path, baseUrl).toString();
}
```

### Layer 4: Debug-Instrumentation
**Purpose:** Capture context for forensics

```python
def call_llm(messages: list[Message], provider: str) -> str:
    logger.info(
        'About to call LLM: provider=%s msg_count=%d total_chars=%d',
        provider, len(messages), sum(len(m.content) for m in messages),
    )
    try:
        return _call(messages, provider)
    except Exception as e:
        logger.error(
            'LLM call failed: provider=%s error=%s\n%s',
            provider, e, traceback.format_exc(),
        )
        raise
```

## Applying the Pattern

When you find a bug:

1. **Trace data flow** — Where does the bad value originate? Where is it used?
2. **Map all checkpoints** — List every point where data passes
3. **Add validation at each layer** — Entry, Business, Environment, Debug
4. **Test each layer** — Try to bypass Layer 1, verify Layer 2 catches it

## Example: Four Layers in Practice

### Bug: Worker reads an empty API key

**Data flow:**
1. Deployment injects an env var from the secret store
2. Worker starts, reads the key on startup
3. Store returns an empty string (token was rotated but written empty)
4. HTTP client raises 401

**Four layers:**
- **Layer 1** Entry-point: `if not api_key: raise RuntimeError('API_KEY empty')`
- **Layer 2** Health check: a daily job checks token validity
- **Layer 3** Provisioning: `precondition` that `length(value) > 20`
- **Layer 4** Alerting on 401 errors with a token-source hint

**Result:** The bug had 4 chances to be caught before the user felt it.

## Key Insight

All four layers were necessary. During testing, each layer caught bugs the others missed:
- Different code paths bypass entry validation
- Mocks bypass business-logic checks
- Edge cases on different platforms need environment guards
- Debug logging identifies structural misuse

**Don't stop at one validation point.** Add checks at each layer.

## Anti-pattern: Symptom-layer stacking

```python
# WRONG: validation where the bug appeared
def render_response(reply: str) -> str:
    if not reply:
        return 'Connection error.'  # Hides the root cause
    return reply
```

This only hides that no reply arrived. Instead:

```python
# RIGHT: validation along the data flow
def call_service(...) -> str:
    reply = client.request(...)
    if not reply.items:
        raise RuntimeError(f'service returned no items: {reply}')
    if not reply.items[0].content:
        raise RuntimeError(f'service returned empty content: {reply}')
    return reply.items[0].content

# Plus frontend Layer 1:
function handleResponse(reply: string) {
  if (!reply) {
    // Still show it, but track/report
    captureException(new Error('Empty reply from service'));
    return showError('Reply was empty.');
  }
  return showReply(reply);
}
```

This way you know WHERE in the stack the empty reply comes from — not just THAT it arrived.
