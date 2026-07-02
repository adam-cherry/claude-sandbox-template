---
name: screen-input
description: "Extract structured bullets from raw notes (meeting transcripts, brain dumps) into Input/protocols/ with proper frontmatter."
user_invocable: true
trigger: "When user says '/screen-input', 'build a protocol from', 'bullet extraction', or pastes raw notes."
allowed_tools:
  - Read
  - Write
  - Edit
---

# Screen Input — raw notes -> structured protocol

Converts an unstructured source (meeting transcript, email dump, Slack export)
into a structured protocol under `Input/protocols/`.

## Flow

### 1. Capture the source
- User provides raw text or a path to a raw file
- Ask the user for date + topic if not derivable

### 2. Load the template
- `Input/templates/_PROTOCOL_TEMPLATE.md`

### 3. Structure it
- Extract participants (proper names, roles)
- Find decisions (markers: "Decision", "decided", "agreed", "OK")
- Find action items (markers: "TODO", "Action", "X does Y by Z")
- Mark open points / unclear spots as `[SOURCE MISSING: ...]`

### 4. Write the target file
- `Input/protocols/<YYYY-MM-DD>_<short-topic>.md`
- Fill in the frontmatter completely
- Hierarchy level: `high` (protocols are top-tier in the hierarchy)

### 5. Next steps
- Recommendation: create an AP with this protocol file as the source
- Optional: `/implement-ap` suggestion

## Forbidden

- Hallucinating participants or statements
- Inserting your own conclusions — only transcribe + structure
- Deleting the raw file without user OK
