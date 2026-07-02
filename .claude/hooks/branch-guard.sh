#!/bin/sh
# UserPromptSubmit Hook: Check if user is on a feature branch

branch=$(git branch --show-current 2>/dev/null)
if [ -z "$branch" ]; then
  exit 0
fi

if echo "$branch" | grep -q '^feature/'; then
  echo "Branch: $branch"
else
  dirty=$(git status --porcelain 2>/dev/null)
  if [ -n "$dirty" ]; then
    echo "WARNING: You are on '$branch' with uncommitted changes."
    echo "Create a feature branch: git checkout -b feature/<description>"
  else
    echo "NOTE: You are on '$branch'. Create a feature branch before you start:"
    echo "  git checkout -b feature/<description>"
  fi
fi
