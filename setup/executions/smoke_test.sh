#!/usr/bin/env bash
#
# Smoke Test — checks whether the agentic framework is set up correctly.
# Run: bash setup/executions/smoke_test.sh
#
set -u
fail=0

check_file() { [ -f "$1" ] && echo "  ok   $1" || { echo "  MISS $1"; fail=1; }; }
check_dir()  { [ -d "$1" ] && echo "  ok   $1" || { echo "  MISS $1"; fail=1; }; }

echo "=== Claude Workspace ==="
check_dir  ".claude/skills"
check_dir  ".claude/rules"
check_file ".claude/settings.json"
check_file ".claude/config/project.md"

echo "=== Core Skills ==="
for skill in looping local-pr break-glass debugging new-spike recommend where release-tag; do
  check_dir ".claude/skills/$skill"
done

echo "=== Core Rules ==="
for rule in conventional-commits git-workflow mcp-policy skill-quality skill-ecosystem worktree-policy secrets-guardrails; do
  check_file ".claude/rules/$rule.md"
done

echo "=== Git Workflow ==="
check_file ".githooks/pre-commit"
check_file ".claude/hooks/branch-guard.sh"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  hp=$(git config core.hooksPath 2>/dev/null)
  [ "$hp" = ".githooks" ] && echo "  ok   core.hooksPath=.githooks" || echo "  WARN core.hooksPath not set (git config core.hooksPath .githooks)"
else
  echo "  WARN no git repo (git init pending)"
fi

echo "=== Setup Meta ==="
check_dir  "setup/blueprints"
check_file "setup/blueprints/agentic_project_structure.md"
check_dir  "setup/genes"
check_file ".env.example"

echo "=== Python (optional) ==="
python3 setup/executions/hello_world.py 2>/dev/null && echo "  ok   python3 hello_world" || echo "  WARN python3 not available"

echo ""
[ "$fail" -eq 0 ] && echo "SMOKE TEST: PASS" || echo "SMOKE TEST: FAIL (missing files above)"
exit $fail
