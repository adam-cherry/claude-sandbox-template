# Directive: Secrets Guardrails

Binding for everything that works with tokens, API keys, passwords, or credentials.

## Golden Rule

**Secrets never belong in Git.** Values live in a secret manager (or locally in a
gitignored `.env`). Only the **structure** is committed (`.env.example` with placeholders).

## Source of Truth

| What | Where |
|-----|-----|
| Secret **values** | Secret manager (e.g. Vault, 1Password, Bitwarden, cloud KeyVault) or local `.env` |
| Secret **structure** (which keys exist) | `.env.example` in the repo — always keep current |
| Local `.env` | A derivation — never the source, never copied between machines |

## Rules

- `.env` is **always** in `.gitignore` — check before every commit.
- `.env.example` carries **all** keys with placeholder values (never real values) and a
  short comment per key. Add to it immediately for every new env var.
- Never write secret values into scripts, docs, commit messages, logs, or tool output.
- On a leaked secret: **rotate** it, don't just delete it from history.
- Access values in code via `os.environ` / `process.env` / the secret manager's SDK —
  never hardcoded.

## Forbidden

- Real values in `.env.example`
- Committing `.env`
- Writing credentials "temporarily" into a note, doc, or chat message
- Copying a secret from a gitignored file into a tracked file
