#!/bin/bash
# Marrow hook test runner
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/../hooks/scripts"
TEST_VAULT="$SCRIPT_DIR/test-vault"
PASS=0
FAIL=0

assert_exit() {
  local expected=$1 actual=$2 name=$3
  if [ "$expected" -eq "$actual" ]; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name (expected exit $expected, got $actual)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== vaultguard tests ==="

# Test: exits 0 in a vault
CLAUDE_PROJECT_DIR="$TEST_VAULT" "$HOOKS_DIR/vaultguard.sh" 2>/dev/null
assert_exit 0 $? "exits 0 in vault with .marrow"

# Test: exits 1 outside a vault
if CLAUDE_PROJECT_DIR="/tmp" "$HOOKS_DIR/vaultguard.sh" 2>/dev/null; then
  assert_exit 1 0 "exits 1 outside vault"
else
  assert_exit 1 1 "exits 1 outside vault"
fi

echo ""
echo "=== read-config tests ==="

# Test: reads existing key
RESULT=$(CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/read-config.sh" "git")
if [ "$RESULT" = "true" ]; then
  assert_exit 0 0 "reads git: true"
else
  assert_exit 0 1 "reads git: true (got: $RESULT)"
fi

# Test: returns default for missing key
RESULT=$(CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/read-config.sh" "nonexistent" "fallback")
if [ "$RESULT" = "fallback" ]; then
  assert_exit 0 0 "returns default for missing key"
else
  assert_exit 0 1 "returns default for missing key (got: $RESULT)"
fi

# Test: returns default when no config file
RESULT=$(CLAUDE_PROJECT_DIR="/tmp" bash "$HOOKS_DIR/read-config.sh" "git" "default_val")
if [ "$RESULT" = "default_val" ]; then
  assert_exit 0 0 "returns default when no .marrow file"
else
  assert_exit 0 1 "returns default when no .marrow file (got: $RESULT)"
fi

echo ""
echo "=== session-orient tests ==="

# Save and restore CWD
ORIG_DIR=$(pwd)
cd "$TEST_VAULT"

# Clean previous test state
rm -f ops/sessions/current.json ops/sessions/*.json

# Test: produces output with vault structure
OUTPUT=$(echo '{"session_id":"test-session-1"}' | CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/session-orient.sh" 2>/dev/null)
if echo "$OUTPUT" | grep -q "goals"; then
  assert_exit 0 0 "output includes goals content"
else
  assert_exit 0 1 "output includes goals content"
fi

# Test: creates current.json
if [ -f ops/sessions/current.json ]; then
  assert_exit 0 0 "creates current.json"
else
  assert_exit 0 1 "creates current.json"
fi

# Test: current.json has session ID
if grep -q "test-session-1" ops/sessions/current.json 2>/dev/null; then
  assert_exit 0 0 "current.json contains session ID"
else
  assert_exit 0 1 "current.json contains session ID"
fi

# Test: second session promotes previous
OUTPUT=$(echo '{"session_id":"test-session-2"}' | CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/session-orient.sh" 2>/dev/null)
ARCHIVED=$(ls ops/sessions/*.json 2>/dev/null | grep -v current | wc -l | tr -d ' ')
if [ "$ARCHIVED" -ge 1 ]; then
  assert_exit 0 0 "previous session archived on new session"
else
  assert_exit 0 1 "previous session archived on new session"
fi

# Test: condition signal fires when inbox exceeds threshold
for i in $(seq 1 6); do touch inbox/test-$i.md; done
OUTPUT=$(echo '{"session_id":"test-session-3"}' | CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/session-orient.sh" 2>/dev/null)
if echo "$OUTPUT" | grep -qi "inbox"; then
  assert_exit 0 0 "inbox warning fires at threshold"
else
  assert_exit 0 1 "inbox warning fires at threshold"
fi

# Clean up
rm -f ops/sessions/*.json inbox/test-*.md
cd "$ORIG_DIR"

echo ""
echo "=== write-validate tests ==="

# Test: valid note produces no warnings
cat > "$TEST_VAULT/notes/test-valid.md" << 'NOTEOF'
---
description: A valid test note
type: note
topics: [test]
---

# valid test note
NOTEOF
RESULT=$(echo '{"tool_input":{"file_path":"'"$TEST_VAULT"'/notes/test-valid.md"}}' | CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/write-validate.sh" 2>/dev/null)
if [ -z "$RESULT" ]; then
  assert_exit 0 0 "valid note produces no warnings"
else
  assert_exit 0 1 "valid note produces no warnings (got: $RESULT)"
fi

# Test: missing description produces warning
cat > "$TEST_VAULT/notes/test-invalid.md" << 'NOTEOF'
---
type: note
topics: [test]
---

# missing description
NOTEOF
RESULT=$(echo '{"tool_input":{"file_path":"'"$TEST_VAULT"'/notes/test-invalid.md"}}' | CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/write-validate.sh" 2>/dev/null)
if echo "$RESULT" | grep -qi "description"; then
  assert_exit 0 0 "missing description produces warning"
else
  assert_exit 0 1 "missing description produces warning (got: $RESULT)"
fi

# Test: file outside notes/ is skipped
RESULT=$(echo '{"tool_input":{"file_path":"'"$TEST_VAULT"'/README.md"}}' | CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/write-validate.sh" 2>/dev/null)
if [ -z "$RESULT" ]; then
  assert_exit 0 0 "file outside notes/ skipped"
else
  assert_exit 0 1 "file outside notes/ skipped (got: $RESULT)"
fi

# Clean up
rm -f "$TEST_VAULT/notes/test-valid.md" "$TEST_VAULT/notes/test-invalid.md"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
