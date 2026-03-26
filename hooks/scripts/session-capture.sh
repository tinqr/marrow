#!/bin/bash
# Marrow -- Session Capture Hook (Stop)
# Best-effort session persistence on session end.
# Belt-and-suspenders: orient hook also archives at next session start.

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

# Update current.json with ended timestamp if it matches this session
if [ -f ops/sessions/current.json ]; then
  if command -v jq &>/dev/null; then
    CURRENT_ID=$(jq -r '.id // empty' ops/sessions/current.json)
  else
    CURRENT_ID=$(grep -o '"id":"[^"]*"' ops/sessions/current.json | head -1 | sed 's/"id":"//;s/"//')
  fi

  if [ "$CURRENT_ID" = "$SESSION_ID" ]; then
    # Update status to completed with end time
    STARTED=$(grep -o '"started":"[^"]*"' ops/sessions/current.json | head -1 | sed 's/"started":"//;s/"//')
    cat > ops/sessions/current.json << EOF
{
  "id": "$SESSION_ID",
  "started": "${STARTED:-$TIMESTAMP}",
  "ended": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "completed"
}
EOF
  fi
fi

# Auto-commit if git enabled
if [ "$(bash "$READ_CONFIG" "git" "true")" = "true" ] && git rev-parse --is-inside-work-tree &>/dev/null; then
  git add ops/sessions/ 2>/dev/null
  git commit -m "session end: ${TIMESTAMP}" --quiet 2>/dev/null || true
fi

exit 0
