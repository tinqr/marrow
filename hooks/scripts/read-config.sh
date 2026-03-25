#!/bin/bash
# Marrow -- Config Reader
# Reads values from .marrow guard file (flat YAML).
# Usage: read-config.sh <key> [default]

KEY="$1"
DEFAULT="${2:-true}"

[ -z "$KEY" ] && echo "$DEFAULT" && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CONFIG_FILE="$PROJECT_DIR/.marrow"

[ ! -f "$CONFIG_FILE" ] && echo "$DEFAULT" && exit 0

VALUE=$(grep -E "^${KEY}:" "$CONFIG_FILE" 2>/dev/null | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed "s/^[\"']//;s/[\"']$//" | sed 's/[[:space:]]*$//')

if [ -z "$VALUE" ]; then
  echo "$DEFAULT"
else
  echo "$VALUE"
fi
