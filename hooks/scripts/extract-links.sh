#!/bin/bash
# Extract all wiki links from .md files in a project directory
# Usage: extract-links.sh <project-dir>
# Output: filename|[[link1]], [[link2]], ...

PROJECT_DIR="$1"

if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo "Usage: extract-links.sh <project-dir>" >&2
  exit 1
fi

for f in "$PROJECT_DIR"/*.md; do
  [ -f "$f" ] || continue
  links=$(grep -oh '\[\[[^]]*\]\]' "$f" | sort -u | tr '\n' ', ' | sed 's/, $//')
  basename=$(basename "$f")
  if [ -n "$links" ]; then
    echo "$basename|$links"
  else
    echo "$basename|"
  fi
done
