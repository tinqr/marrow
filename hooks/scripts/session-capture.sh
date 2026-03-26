#!/bin/bash
# Marrow -- Session Capture Hook (Stop)
# Persists session state on session end.
# Runs as Stop hook. Receives session info as JSON on stdin.

GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
if ! "$GUARD_DIR/vaultguard.sh"; then
  cat > /dev/null  # drain stdin
  exit 0
fi

READ_CONFIG="$GUARD_DIR/read-config.sh"
if [ "$(bash "$READ_CONFIG" "session_capture" "true")" != "true" ]; then
  cat > /dev/null
  exit 0
fi

# Read JSON from stdin
INPUT=$(cat)

# Extract session ID
if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
else
  SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | head -1 | sed 's/"session_id":"//;s/"//')
fi

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
mkdir -p ops/sessions

# Save session end state as timestamped file
echo "{\"id\": \"$SESSION_ID\", \"ended\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\", \"status\": \"completed\"}" > "ops/sessions/${TIMESTAMP}.json"

# Auto-commit if git enabled
if [ "$(bash "$READ_CONFIG" "git" "true")" = "true" ] && git rev-parse --is-inside-work-tree &>/dev/null; then
  git add ops/sessions/ 2>/dev/null
  git commit -m "session end: ${TIMESTAMP}" --quiet 2>/dev/null || true
fi

exit 0
