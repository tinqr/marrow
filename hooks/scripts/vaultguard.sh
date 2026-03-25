#!/bin/bash
# Marrow -- Vault Guard
# Checks if the current directory is a Marrow vault.
# Exit 0 = vault detected (safe to proceed)
# Exit 1 = not a vault (caller should exit)

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

if [ -f "$PROJECT_DIR/.marrow" ]; then
  exit 0
fi

exit 1
