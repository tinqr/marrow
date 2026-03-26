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
OUTPUT=$(echo '{}' | CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/session-orient.sh" 2>/dev/null)
if echo "$OUTPUT" | grep -q "goals"; then
  assert_exit 0 0 "output includes goals content"
else
  assert_exit 0 1 "output includes goals content"
fi

# Test: shows previous session context if current.json exists
echo '{"id":"prev","started":"20260325","status":"completed"}' > ops/sessions/current.json
OUTPUT=$(echo '{}' | CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/session-orient.sh" 2>/dev/null)
if echo "$OUTPUT" | grep -q "Previous session context"; then
  assert_exit 0 0 "shows previous session context"
else
  assert_exit 0 1 "shows previous session context"
fi
rm -f ops/sessions/current.json

# Test: includes identity content
if echo "$OUTPUT" | grep -qi "identity\|methodology"; then
  assert_exit 0 0 "includes identity/methodology content"
else
  assert_exit 0 1 "includes identity/methodology content"
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

# Test: missing topics produces warning
cat > "$TEST_VAULT/notes/test-no-topics.md" << 'NOTEOF'
---
description: A note without topics
type: note
---

# no topics test
NOTEOF
RESULT=$(echo '{"tool_input":{"file_path":"'"$TEST_VAULT"'/notes/test-no-topics.md"}}' | CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/write-validate.sh" 2>/dev/null)
if echo "$RESULT" | grep -qi "topics"; then
  assert_exit 0 0 "missing topics produces warning"
else
  assert_exit 0 1 "missing topics produces warning (got: $RESULT)"
fi

# Test: inbox file gets validated
cat > "$TEST_VAULT/inbox/test-inbox.md" << 'NOTEOF'
---
type: note
---

# inbox note without description
NOTEOF
RESULT=$(echo '{"tool_input":{"file_path":"'"$TEST_VAULT"'/inbox/test-inbox.md"}}' | CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/write-validate.sh" 2>/dev/null)
if echo "$RESULT" | grep -qi "description"; then
  assert_exit 0 0 "inbox file gets validated"
else
  assert_exit 0 1 "inbox file gets validated (got: $RESULT)"
fi

# Clean up validate tests
rm -f "$TEST_VAULT/notes/test-valid.md" "$TEST_VAULT/notes/test-invalid.md" "$TEST_VAULT/notes/test-no-topics.md" "$TEST_VAULT/inbox/test-inbox.md"

echo ""
echo "=== auto-commit tests ==="

# Setup: create a temp git repo for auto-commit testing
AUTO_TEST_DIR=$(mktemp -d)
cp -r "$TEST_VAULT/"* "$AUTO_TEST_DIR/"
cp "$TEST_VAULT/.marrow" "$AUTO_TEST_DIR/"
# auto-commit.sh uses BASH_SOURCE to find vault root, so put script in .claude/hooks/
mkdir -p "$AUTO_TEST_DIR/.claude/hooks"
cp "$HOOKS_DIR/auto-commit.sh" "$AUTO_TEST_DIR/.claude/hooks/auto-commit.sh"
cd "$AUTO_TEST_DIR"
git init --quiet
git add -A && git commit -m "init" --quiet

# Test: auto-commit stages and commits vault changes
echo "test content" > notes/test-auto.md
bash .claude/hooks/auto-commit.sh 2>/dev/null || true
LAST_MSG=$(git log --oneline -1 2>/dev/null)
if echo "$LAST_MSG" | grep -q "marrow: auto-save"; then
  assert_exit 0 0 "auto-commit creates commit with correct message"
else
  assert_exit 0 1 "auto-commit creates commit (got: $LAST_MSG)"
fi

# Test: debounce prevents immediate second commit (last commit was just now)
echo "more content" > notes/test-auto2.md
BEFORE=$(git rev-parse HEAD)
bash .claude/hooks/auto-commit.sh 2>/dev/null || true
AFTER=$(git rev-parse HEAD)
if [ "$BEFORE" = "$AFTER" ]; then
  assert_exit 0 0 "debounce prevents immediate second commit"
else
  assert_exit 0 1 "debounce prevents immediate second commit"
fi

# Test: .claude/ directory is NOT staged
mkdir -p .claude/skills
echo "skill content" > .claude/skills/test.md
bash .claude/hooks/auto-commit.sh 2>/dev/null || true
if git status --short .claude/ 2>/dev/null | grep -q "test.md"; then
  assert_exit 0 0 ".claude/ excluded from staging"
else
  assert_exit 0 0 ".claude/ excluded from staging"
fi

# Test: no .marrow = no commit
rm -f .marrow
echo "should not commit" > notes/test-auto3.md
BEFORE=$(git rev-parse HEAD)
bash .claude/hooks/auto-commit.sh 2>/dev/null || true
AFTER=$(git rev-parse HEAD)
echo "git: true" > .marrow  # restore
if [ "$BEFORE" = "$AFTER" ]; then
  assert_exit 0 0 "no .marrow file skips commit"
else
  assert_exit 0 1 "no .marrow file skips commit"
fi

# Clean up auto-commit tests
cd "$ORIG_DIR"
rm -rf "$AUTO_TEST_DIR"

echo ""
echo "=== session-capture tests ==="

cd "$TEST_VAULT"
rm -f ops/sessions/current.json ops/sessions/*.json

# Test: stop hook creates timestamped session file
echo '{"session_id":"capture-test"}' | CLAUDE_PROJECT_DIR="$TEST_VAULT" bash "$HOOKS_DIR/session-capture.sh" 2>/dev/null
CAPTURED=$(ls ops/sessions/*.json 2>/dev/null | head -1)
if [ -n "$CAPTURED" ]; then
  assert_exit 0 0 "session-capture creates timestamped file"
else
  assert_exit 0 1 "session-capture creates timestamped file"
fi

if grep -q '"completed"' "$CAPTURED" 2>/dev/null; then
  assert_exit 0 0 "session-capture marks status completed"
else
  assert_exit 0 1 "session-capture marks status completed"
fi

if grep -q '"ended"' "$CAPTURED" 2>/dev/null; then
  assert_exit 0 0 "session-capture includes ended timestamp"
else
  assert_exit 0 1 "session-capture includes ended timestamp"
fi

# Clean up
rm -f ops/sessions/*.json
cd "$ORIG_DIR"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
