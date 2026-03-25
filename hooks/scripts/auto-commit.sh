#!/bin/bash
# Marrow -- Auto-Commit Hook
# Commits vault changes after writes. Async PostToolUse hook.
# Selective staging -- only vault content, not .claude/.

set -e

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
"$GUARD_DIR/vaultguard.sh" || exit 0

# Check git config
READ_CONFIG="$GUARD_DIR/read-config.sh"
if [ "$(bash "$READ_CONFIG" "git" "true")" != "true" ]; then
  exit 0
fi

# Must be inside a git repo
git rev-parse --is-inside-work-tree &>/dev/null || exit 0

# Debounce
LOCKFILE="${CLAUDE_PROJECT_DIR:-.}/.marrow-commit-lock"
DEBOUNCE=$(grep "auto_commit_debounce_seconds" marrow.yaml 2>/dev/null | head -1 | sed 's/[^0-9]//g')
DEBOUNCE="${DEBOUNCE:-300}"

if [ -f "$LOCKFILE" ]; then
  # macOS stat -f %m, Linux stat -c %Y
  LOCK_MTIME=$(stat -f %m "$LOCKFILE" 2>/dev/null || stat -c %Y "$LOCKFILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  ELAPSED=$(( NOW - LOCK_MTIME ))
  if [ "$ELAPSED" -lt "$DEBOUNCE" ]; then
    exit 0
  fi
fi

# Selective staging -- vault content only
for path in notes/ inbox/ self/ ops/ templates/ CLAUDE.md marrow.yaml .marrow; do
  [ -e "$path" ] && git add "$path" 2>/dev/null || true
done

# Check for staged changes
if git diff --cached --quiet 2>/dev/null; then
  exit 0
fi

# Commit
FILE_COUNT=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
git commit -m "marrow: auto-save $FILE_COUNT file(s)" 2>/dev/null || true

# Update lockfile
touch "$LOCKFILE"

exit 0
