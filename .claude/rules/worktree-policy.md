# Directive: Worktree Policy

## Mental Model (Simple)

A feature branch is home. When multiple agents work **at the same time**,
each gets its own **worktree** (a private repo copy in its own folder) — so
no one disturbs anyone else and nothing breaks. Afterwards everything is written back into the
**one** feature branch and committed there.

## When Worktrees

- **2+ agents mutating files at the same time** → a worktree per agent (otherwise they collide in the same working dir / git index).
- Ideally on **disjoint** files. If two touch the same file, worktrees don't help — then plan the task so the files are disjoint.
- In code workflows this is the normal case (workflow `isolation: 'worktree'`); an integrator merges the ephemeral `worktree-agent-*` branches back into the feature branch.

## When NO Worktrees

- **Single agent** — nothing to isolate.
- **Read-only fan-out** (research, explore, search) — no mutation, no collision.
- **Docs/Markdown** (wiki) — no build/merge-back; multiple agents write disjoint files directly in the feature branch. Cheaper than worktrees.

## Cleanup

Automatic: `isolation: 'worktree'` (the agent/workflow tool) creates and removes the
worktree itself. Manual only in exceptional cases:

```bash
git worktree list
git worktree remove .claude/worktrees/<name> --force
git branch -D worktree-agent-<id>
```

## Anti-patterns

- A worktree for a single or read-only agent.
- Worktrees for Markdown/docs (unnecessary overhead).
- Setting two agents on the same file instead of planning them disjoint.
- Manual edits on the feature branch while worktree agents are running.
