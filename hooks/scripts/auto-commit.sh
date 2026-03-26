#!/usr/bin/env bash
# auto-commit.sh — Auto-commit vault changes after writes (async PostToolUse hook)
# Single source of truth for vault auto-commits. 10-minute debounce.

set -euo pipefail

VAULT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Guard: only run inside a vault
if [ ! -f "$VAULT_ROOT/.marrow" ]; then
  exit 0
fi

cd "$VAULT_ROOT"

# Guard: only run if git is initialized
if [ ! -d ".git" ]; then
  exit 0
fi

# Debounce: skip if last auto-commit was less than 10 minutes ago
LAST_COMMIT_TIME=$(git log -1 --format="%ct" --grep="marrow: auto-save" 2>/dev/null)
LAST_COMMIT_TIME="${LAST_COMMIT_TIME:-0}"
NOW=$(date +%s)
ELAPSED=$(( NOW - LAST_COMMIT_TIME ))
if [ "$ELAPSED" -lt 600 ]; then
  exit 0
fi

# Stage vault content directories only
git add notes/ 2>/dev/null || true
git add inbox/ 2>/dev/null || true
git add self/ 2>/dev/null || true
git add ops/ 2>/dev/null || true
git add templates/ 2>/dev/null || true
git add CLAUDE.md .marrow .gitignore marrow.yaml 2>/dev/null || true

# Check if anything is staged
if git diff --staged --quiet; then
  exit 0
fi

# Commit with clean message
CHANGED_COUNT=$(git diff --staged --name-only | wc -l | tr -d ' ')

git commit -m "marrow: auto-save ${CHANGED_COUNT} file(s)" -q 2>/dev/null || true

exit 0
