#!/bin/bash
# Marrow -- Session Orientation Hook
# Archives previous session, then injects vault context into conversation.

GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
"$GUARD_DIR/vaultguard.sh" || exit 0

INPUT=$(cat)
SESSION_ID=""
if command -v jq &>/dev/null; then
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
else
  SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | head -1 | sed 's/"session_id":"//;s/"//')
fi

READ_CONFIG="$GUARD_DIR/read-config.sh"

# -- Archive phase (silent) ---------------------------------------------------

if [ -n "$SESSION_ID" ] && [ "$(bash "$READ_CONFIG" "session_capture" "true")" = "true" ]; then
  TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
  mkdir -p ops/sessions

  if [ -f ops/sessions/current.json ]; then
    if command -v jq &>/dev/null; then
      PREV_ID=$(jq -r '.id // empty' ops/sessions/current.json)
    else
      PREV_ID=$(grep -o '"id":"[^"]*"' ops/sessions/current.json | head -1 | sed 's/"id":"//;s/"//')
    fi

    if [ -n "$PREV_ID" ] && [ "$PREV_ID" != "$SESSION_ID" ]; then
      PREV_TS=$(grep -o '"started":"[^"]*"' ops/sessions/current.json | head -1 | sed 's/"started":"//;s/"//')
      mv ops/sessions/current.json "ops/sessions/${PREV_TS:-$TIMESTAMP}.json"
    fi
  fi

  cat > ops/sessions/current.json << EOF
{
  "id": "$SESSION_ID",
  "started": "$TIMESTAMP",
  "status": "active"
}
EOF

  # Commit session state if git enabled
  if [ "$(bash "$READ_CONFIG" "git" "true")" = "true" ] && git rev-parse --is-inside-work-tree &>/dev/null; then
    git add ops/sessions/ 2>/dev/null
    git commit -m "session start: ${TIMESTAMP}" --quiet 2>/dev/null || true
  fi
fi

# -- Injection phase (stdout -> conversation) ----------------------------------

echo "## Workspace Structure"
echo ""
if command -v tree &>/dev/null; then
  tree -L 3 --charset ascii -I '.git|node_modules|.marrow-commit-lock' -P '*.md' .
else
  find . -name "*.md" -not -path "./.git/*" -maxdepth 3 | sort | while read -r file; do
    depth=$(echo "$file" | tr -cd '/' | wc -c)
    indent=$(printf '%*s' "$((depth * 2))" '')
    echo "${indent}$(basename "$file")"
  done
fi
echo ""
echo "---"
echo ""

# Previous session context
if [ -f ops/sessions/current.json ]; then
  echo "--- Previous session context ---"
  cat ops/sessions/current.json
  echo ""
fi

# Goals
if [ -f self/goals.md ]; then
  cat self/goals.md
  echo ""
fi

# Identity + methodology
[ -f self/identity.md ] && cat self/identity.md && echo ""
[ -f self/methodology.md ] && cat self/methodology.md && echo ""

# Recent methodology notes (top 5, description field only)
for f in $(ls -t ops/methodology/*.md 2>/dev/null | head -5); do
  DESC=$(grep "^description:" "$f" 2>/dev/null | head -1 | sed 's/^description:[[:space:]]*//')
  [ -n "$DESC" ] && echo "description: $DESC"
done

# Condition signals
INBOX_COUNT=$(ls -1 inbox/*.md 2>/dev/null | wc -l | tr -d ' ')
OBS_COUNT=$(ls -1 ops/observations/*.md 2>/dev/null | wc -l | tr -d ' ')
SESS_COUNT=$(ls -1 ops/sessions/*.json 2>/dev/null | grep -v current | wc -l | tr -d ' ')

INBOX_WARN=$(grep "inbox_warning" marrow.yaml 2>/dev/null | head -1 | sed 's/[^0-9]//g')
OBS_WARN=$(grep "observations_warning" marrow.yaml 2>/dev/null | head -1 | sed 's/[^0-9]//g')
SESS_WARN=$(grep "session_log_max" marrow.yaml 2>/dev/null | head -1 | sed 's/[^0-9]//g')

INBOX_WARN="${INBOX_WARN:-5}"
OBS_WARN="${OBS_WARN:-10}"
SESS_WARN="${SESS_WARN:-8}"

[ "$INBOX_COUNT" -ge "$INBOX_WARN" ] 2>/dev/null && echo "CONDITION: $INBOX_COUNT items in inbox. Consider /process."
[ "$OBS_COUNT" -ge "$OBS_WARN" ] 2>/dev/null && echo "CONDITION: $OBS_COUNT pending observations. Consider /review."
[ "$SESS_COUNT" -ge "$SESS_WARN" ] 2>/dev/null && echo "CONDITION: $SESS_COUNT archived sessions. Consider /remember --scan."

exit 0
