---
name: break-glass
description: "Emergency direct commit on main. Bypasses pre-commit hook. Admin only."
user_invocable: true
trigger: "When user explicitly asks for break-glass, emergency commit, or hotfix on main."
allowed_tools:
  - Bash(git:*)
  - Read
---

# Break Glass — Direct Commit on Main

Emergency mechanism. Deliberately bypasses the pre-commit hook.

## Steps

1. Ask the user explicitly: "Break Glass: Direct commit on main. Are you sure?"
2. Only on confirmation: `git commit --no-verify -m "<message>"`
3. Do NOT push automatically
