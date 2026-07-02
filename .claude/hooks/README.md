# .claude/hooks/

Claude Code hooks for the operator. They run on session/tool events — see the Trigger column. Configuration: `.claude/settings.json` -> `hooks`.

## Active Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| `branch-guard.sh` | SessionStart, UserPromptSubmit | Reminds you that main is protected — create a feature branch when needed |

## Notes

- Hooks are run by the harness, not by Claude itself.
- On hook errors: do NOT bypass with `--no-verify`. Find the root cause.
- Conventional commits are mandatory (see `.claude/rules/conventional-commits.md`).
