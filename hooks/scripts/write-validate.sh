#!/bin/bash
# Marrow -- Note Validation Hook
# Validates notes have required frontmatter fields.
# PostToolUse Write hook. Non-blocking.

GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
if ! "$GUARD_DIR/vaultguard.sh"; then
  cat > /dev/null
  exit 0
fi

INPUT=$(cat)

if command -v jq &>/dev/null; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
else
  FILE=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"//')
fi

[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

case "$FILE" in
  */notes/*|*/inbox/*)
    WARNS=""
    if ! head -20 "$FILE" | grep -q "^description:"; then
      WARNS="${WARNS}Missing description field. "
    fi
    if ! head -20 "$FILE" | grep -q "^topics:"; then
      WARNS="${WARNS}Missing topics field. "
    fi
    if ! head -1 "$FILE" | grep -q "^---$"; then
      WARNS="${WARNS}Missing YAML frontmatter. "
    fi
    if [ -n "$WARNS" ]; then
      FILENAME=$(basename "$FILE" .md)
      echo "{\"additionalContext\": \"Schema warnings for $FILENAME: $WARNS\"}"
    fi
    ;;
esac

exit 0
