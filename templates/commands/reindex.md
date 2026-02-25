---
description: Rebuild project index and fix wiki link gaps across all notes
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
argument-hint: "[project-name] — project to reindex (or omit to reindex all)"
---

# Reindex

Full project index rebuild and wiki link maintenance. Run this when the knowledge base needs tidying — not every session.

## Preflight

Check that `./CLAUDE.md` contains `<!-- marrow:root:v0.5.1 -->`. If not, tell the user this isn't a Marrow directory. You can set one up with `/marrow:setup`.

## Step 1: Identify the project(s)

**If `$ARGUMENTS` is provided:** Use it as the project name. Verify `./PROJECT_NAME/` directory exists.

**If no argument:** Read `./projects.md` and collect all project names. Run Steps 2–6 for each project.

## Step 2: Extract all wiki links

Run the helper script:
```bash
bash ./scripts/extract-links.sh ./PROJECT_NAME/
```

If the script doesn't exist, run inline:
```bash
for f in ./PROJECT_NAME/*.md; do
  [ -f "$f" ] || continue
  links=$(grep -oh '\[\[[^]]*\]\]' "$f" | sort -u | tr '\n' ', ' | sed 's/, $//')
  echo "$(basename "$f")|$links"
done
```

Read the output. Each line: `filename|[[link1]], [[link2]], ...`

## Step 3: Identify gaps

From the link inventory:

1. **Missing backlinks:** Note A links to `[[B]]` but note B doesn't contain `[[A]]`
2. **Orphan notes:** Notes that no other note links to (no incoming links). Exclude `CLAUDE.md`, `index.md`, and `session-archive.md` from orphan detection.
3. **Dangling links:** `[[target]]` where no file matching `target.md` exists in the project directory

## Step 4: Fix missing backlinks

For each missing backlink:
- Open the target note
- If it has a `## Backlinks` section, append the link there
- If it doesn't, add a `## Backlinks` section at the end with the link

Format: `- [[source-note]] — links here`

## Step 5: Rebuild index.md

Write a fresh `./PROJECT_NAME/index.md`:

```
---
description: Knowledge index for PROJECT_NAME
type: index
---

# PROJECT_NAME — Index

- [[note-title-1]] — description from frontmatter
- [[note-title-2]] — description from frontmatter
...
```

List ALL notes (excluding CLAUDE.md, index.md, session-archive.md). For each note, read its frontmatter `description` field. If no description, use "(no description)".

Sort alphabetically by note title.

## Step 6: Report

Print a one-line summary: **"Reindexed PROJECT_NAME — N notes, N backlinks added."**

Then, only if there are issues:
- If there are orphan notes, warn: "Orphan notes (no incoming links): list. Consider linking these from other notes or removing them."
- If there are dangling links, warn: "Dangling links (no matching file): list. Consider creating these notes or removing the links."
