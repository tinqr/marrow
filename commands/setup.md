---
description: Set up your Marrow knowledge store
allowed-tools: Read, Write, Bash, Edit
argument-hint: "[path] — where to create Marrow (default: ~/marrow/)"
---

# Setup

Create a new Marrow knowledge store. Follow these steps exactly.

## Step 1: Location

If `$ARGUMENTS` is provided and non-empty, use it as the Marrow root path.
Otherwise, ask: **"Where should I create your Marrow? (default: ~/marrow/)"**

Expand `~` to the full home directory path. Store as `MARROW_ROOT`.

If the directory already exists and contains a CLAUDE.md with `<!-- marrow:root:`, tell the user: **"Marrow already exists there! Use `/recall` to load a project."**

## Step 2: Get to know the user

Ask: **"What's your name?"**

Store as `USER_NAME`.

Ask: **"What do you do? For example: 'product designer building Flutter apps' or 'backend engineer at a startup'"**

Store as `USER_ROLE`.

Ask: **"Anything else I should know about how you work? (or just hit enter to skip)"**

If they provide something, store as `USER_CONTEXT`. If they skip, set `USER_CONTEXT` to empty.

## Step 3: First project

Ask: **"Let's create your first project. What's it called?"**

Normalize to kebab-case. Store as `PROJECT_NAME`.

Ask: **"Tell me about PROJECT_NAME — what are you working on?"**

Store as `PROJECT_DESCRIPTION` (1-3 sentences).

## Step 4: Create directory structure

```bash
mkdir -p MARROW_ROOT/.marrow
mkdir -p MARROW_ROOT/.claude/commands
mkdir -p MARROW_ROOT/PROJECT_NAME
mkdir -p MARROW_ROOT/scripts
```

## Step 5: Generate commands

Write these 5 command files to `MARROW_ROOT/.claude/commands/`. These become `/checkpoint`, `/recall`, etc. — the daily-use commands with no prefix.

Write `MARROW_ROOT/.claude/commands/checkpoint.md`:

````
---
description: Save your session progress
allowed-tools: Read, Write, Edit, Bash, Grep
argument-hint: "[project-name] — project to checkpoint (or infer from context)"
---

# Checkpoint

Save your session's progress. This is how context survives between sessions.

## Preflight

Check that `./CLAUDE.md` contains `<!-- marrow:root:v0.5.1 -->`. If not, tell the user: **"This isn't a Marrow directory. You can set one up with `/marrow:setup`."**

## Step 1: Identify the project

**If `$ARGUMENTS` is provided:** Use it as the project name.

**If no argument:** Infer from conversation context — which project was the user working on? If ambiguous, ask.

Verify `./PROJECT_NAME/CLAUDE.md` exists.

## Step 2: Write session log entry

Get the current time:
```bash
date +"%Y-%m-%d %H:%M"
```

Review the conversation to understand what happened this session. Compose a session log entry:

```
### YYYY-MM-DD HH:MM [Claude Code]
**What changed:**
- <bullet per meaningful change>

**Decisions:**
- <bullet per decision, with brief rationale>

**Next:** <one sentence — what should happen next>
```

Append this entry to `./PROJECT_NAME/CLAUDE.md` at the end of the `## Session Log` section.

## Step 3: Archive overflow

Count the `### ` entries under `## Session Log` in the project's CLAUDE.md.

If count > 10: move the oldest entry to the bottom of `./PROJECT_NAME/session-archive.md`. Repeat until exactly 10 entries remain.

## Step 4: Maintain notes

Track how many notes were touched. For any notes created or modified during this session:

1. Read each note, find all outgoing `[[wiki links]]`
2. For each link target, check if a matching `.md` file exists in the project directory
3. If the target exists but doesn't link back, add a `## Backlinks` section (or append to existing) with a wiki link back

Store the count of notes processed as `NOTES_COUNT`.

## Step 5: Update projects.md

Read `./projects.md`. Find the `### Activity` section under `## PROJECT_NAME`.

Append a new activity entry at the top of the activity list:

```
- YYYY-MM-DD HH:MM [Claude Code] <one-line summary>. Next: <next step>
```

If > 5 activity entries, remove the oldest until exactly 5 remain.

## Step 6: Write timestamp

```bash
date +%s > .marrow/last-checkpoint
```

## Step 7: Confirm

If `NOTES_COUNT` > 0:
**"Checkpointed PROJECT_NAME. Session logged, NOTES_COUNT notes indexed."**

If `NOTES_COUNT` is 0:
**"Checkpointed PROJECT_NAME. Session logged."**
````

Write `MARROW_ROOT/.claude/commands/recall.md`:

````
---
description: Load a project's full context
allowed-tools: Read, Grep, Glob, Bash
argument-hint: "[project-name] — project to recall (or omit to see all)"
---

# Recall

Load and summarize a project's current state.

## Preflight

Check that `./CLAUDE.md` contains `<!-- marrow:root:v0.5.1 -->`. If not, tell the user: **"This isn't a Marrow directory. You can set one up with `/marrow:setup`."**

## Step 1: Identify the project

**If `$ARGUMENTS` is provided:** Use it as the project name. Verify `./PROJECT_NAME/CLAUDE.md` exists.

**If no argument but conversation context makes the project obvious:** Use that project.

**If ambiguous:** Read `./projects.md` and summarize all projects with their status and last activity. Ask: **"Which project should I load?"**

## Step 2: Read project context

1. Read `./PROJECT_NAME/CLAUDE.md` — get description, active tasks, and session log
2. Read `./PROJECT_NAME/index.md` — get the knowledge map

## Step 3: Check staleness

Look at the most recent session log entry's date. If it's 7+ days ago and the project is active, note it:

**"Heads up — last checkpoint was [N] days ago. Some context might be stale."**

## Step 4: Summarize

Present a clear summary:

1. **Project:** name and description
2. **Active tasks:** from the Active Tasks section
3. **Last session:** date, agent, what changed, decisions
4. **Next step:** from the last session log's "Next:" field
5. **Knowledge:** list of notes from index.md with brief descriptions
6. **Staleness note** if applicable

End with: **"Ready to work on PROJECT_NAME."**
````

Write `MARROW_ROOT/.claude/commands/new-project.md`:

````
---
description: Add a new project to your Marrow knowledge store
allowed-tools: Read, Write, Bash, Edit
argument-hint: "[project-name] — optional project name"
---

# New Project

Add a new project to this Marrow.

## Preflight

Check that `./CLAUDE.md` contains `<!-- marrow:root:v0.5.1 -->`. If not, tell the user this isn't a Marrow directory. You can set one up with `/marrow:setup`.

## Step 1: Project name

If `$ARGUMENTS` is provided and non-empty, use it as the project name.
Otherwise, ask: **"What's the project called?"**

Normalize to kebab-case (lowercase, hyphens, no spaces). Store as `PROJECT_NAME`.

Check if `./PROJECT_NAME/` already exists. If it does, tell the user the project already exists and stop.

## Step 2: Project description

Ask: **"Tell me about PROJECT_NAME — what are you building?"**

Store as `PROJECT_DESCRIPTION` (1-3 sentences).

## Step 3: Create project files

Create the directory:
```bash
mkdir -p ./PROJECT_NAME
```

Write `./PROJECT_NAME/CLAUDE.md`:
```
<!-- marrow:project:PROJECT_NAME:v0.5.1 -->
# PROJECT_NAME

PROJECT_DESCRIPTION

## Active Tasks

(none yet)

## Session Log
```

Write `./PROJECT_NAME/index.md`:
```
---
description: Knowledge index for PROJECT_NAME
type: index
---

# PROJECT_NAME — Index

(No notes yet. Notes will appear here as they're created.)
```

Write `./PROJECT_NAME/session-archive.md`:
```
# Session Archive

Archived session log entries, oldest first.
```

## Step 4: Update projects.md

Append a new project section to `./projects.md`:

```
## PROJECT_NAME
Status: active

### Activity
```

## Step 5: Confirm

Print: **"Project 'PROJECT_NAME' created! Use `/recall PROJECT_NAME` to start working on it."**
````

Write `MARROW_ROOT/.claude/commands/joint.md`:

````
---
description: Connect an external project folder to Marrow
allowed-tools: Read, Write, Bash, Edit
argument-hint: "[project-name] — Marrow project to connect to"
---

# Joint

Connect an external project folder to Marrow. A joint is where two bones meet — your project folder and Marrow's knowledge.

## Preflight

Determine the Marrow root. Check common locations in order:
1. If `./CLAUDE.md` contains `<!-- marrow:root:v0.5.1 -->`, the current directory IS the Marrow root.
2. If `~/marrow/CLAUDE.md` contains the marker, use `~/marrow/`.
3. Otherwise, tell the user this isn't a Marrow directory. You can set one up with `/marrow:setup`.

Store as `MARROW_ROOT`.

Determine the external project folder path. This is the current working directory if it's NOT the Marrow root. If the user is in the Marrow root, ask: **"What's the path to the project folder you want to connect?"**

Store as `FOLDER_PATH`.

## Step 1: Identify the Marrow project

If `$ARGUMENTS` is provided, use it as the project name.
Otherwise, list projects from `MARROW_ROOT/projects.md` and ask which one to connect.

Store as `PROJECT_NAME`. Verify `MARROW_ROOT/PROJECT_NAME/CLAUDE.md` exists.

## Step 2: Update project CLAUDE.md in Marrow

Read `MARROW_ROOT/PROJECT_NAME/CLAUDE.md`. If it doesn't already have a `Path:` field, add one after the project description:

```
Path: FOLDER_PATH
```

## Step 3: Update projects.md

Read `MARROW_ROOT/projects.md`. Under the `## PROJECT_NAME` section, if there's no `Path:` line, add one after the `Status:` line:

```
Path: FOLDER_PATH
```

## Step 4: Create or update CLAUDE.md in the external project folder

Check if `FOLDER_PATH/CLAUDE.md` exists.

**If it does NOT exist:** Create `FOLDER_PATH/CLAUDE.md` with:

```
<!-- marrow:joint:PROJECT_NAME -->
# PROJECT_NAME

(Add project architecture and conventions here)

---

## Marrow

This project's knowledge store is at `MARROW_ROOT/PROJECT_NAME/`.

When starting work on this project:
1. Read `MARROW_ROOT/PROJECT_NAME/CLAUDE.md` for session history and context
2. Read `MARROW_ROOT/PROJECT_NAME/index.md` for the knowledge map

When finishing work:
1. Use `/checkpoint` to save progress (if Marrow plugin is installed)
2. Or manually append a session log entry to `MARROW_ROOT/PROJECT_NAME/CLAUDE.md`
```

**If it DOES exist:** Append the Marrow pointer section at the end of the existing CLAUDE.md. Do NOT overwrite existing content:

```

<!-- marrow:joint:PROJECT_NAME -->

---

## Marrow

This project's knowledge store is at `MARROW_ROOT/PROJECT_NAME/`.

When starting work on this project:
1. Read `MARROW_ROOT/PROJECT_NAME/CLAUDE.md` for session history and context
2. Read `MARROW_ROOT/PROJECT_NAME/index.md` for the knowledge map

When finishing work:
1. Use `/checkpoint` to save progress (if Marrow plugin is installed)
2. Or manually append a session log entry to `MARROW_ROOT/PROJECT_NAME/CLAUDE.md`
```

Replace `MARROW_ROOT` and `PROJECT_NAME` with actual values in all generated content.

## Step 5: Confirm

Print: **"Connected! `FOLDER_PATH` now points to `MARROW_ROOT/PROJECT_NAME/` for full context."**
````

Write `MARROW_ROOT/.claude/commands/reindex.md`:

````
---
description: Rebuild project index and fix wiki link gaps across all notes
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
argument-hint: "[project-name] — project to reindex (or infer from context)"
---

# Reindex

Full project index rebuild and wiki link maintenance. Run this when the knowledge base needs tidying — not every session.

## Preflight

Check that `./CLAUDE.md` contains `<!-- marrow:root:v0.5.1 -->`. If not, tell the user this isn't a Marrow directory. You can set one up with `/marrow:setup`.

## Step 1: Identify the project

**If `$ARGUMENTS` is provided:** Use it as the project name.
**If no argument:** Infer from context or ask.

Verify `./PROJECT_NAME/` directory exists.

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
````

## Step 6: Generate root CLAUDE.md

Write to `MARROW_ROOT/CLAUDE.md` with the following content. Replace `USER_NAME`, `USER_ROLE`, and `USER_CONTEXT` with actual values. If `USER_CONTEXT` is empty, omit it (don't leave a trailing period).

```
<!-- marrow:root:v0.5.1 -->
# Marrow

Your context, across sessions, across tools.

## About You

USER_NAME is USER_ROLE. USER_CONTEXT

## How I Work

I'm your knowledge assistant. I maintain context across your coding sessions so you never lose the thread between conversations.

What I do:
- Keep a session log for each project — what changed, what was decided, what's next
- Connect notes with wiki links so knowledge compounds over time
- Remind you to save your progress before a session ends
- Give you full context when you come back to a project days or weeks later

## Projects

Your projects live in `projects.md`. Each project has its own folder with:
- `CLAUDE.md` — project description, active tasks, and session log
- `index.md` — knowledge map of all notes and their connections
- `session-archive.md` — older session log entries

To see all projects, read `projects.md`. To load a specific project, use `/recall <project>`.

## Commands

| Command | What it does |
|---------|-------------|
| `/recall` | Load a project's full context (infers which project from context) |
| `/checkpoint` | Save your session progress |
| `/new-project` | Add a new project |
| `/joint` | Connect an external project folder to Marrow |
| `/reindex` | Rebuild indexes and fix broken links (all projects if none specified) |

## Session Log Format

When checkpointing, append to the project's CLAUDE.md under `## Session Log`:

### YYYY-MM-DD HH:MM [Agent]
**What changed:**
- <bullet per meaningful change>

**Decisions:**
- <bullet per decision, with brief rationale>

**Next:** <one sentence — what should happen next>

Get time with: `date +"%Y-%m-%d %H:%M"`. Agent tag examples: [Claude Code], [Cursor], [Windsurf].

Rolling 10-entry window. Overflow to `<project>/session-archive.md` (oldest first).

## Notes

Create notes at `<project>/note-name.md` (kebab-case). Frontmatter:

---
description: Why this matters
type: note
created: YYYY-MM-DD
topics: []
---

Connect notes with `[[wiki links]]`. Backlinks are maintained automatically at checkpoint.
```

## Step 7: Generate projects.md

Write to `MARROW_ROOT/projects.md`:

```
# Projects

## PROJECT_NAME
Status: active

### Activity
```

## Step 8: Generate project files

Write `MARROW_ROOT/PROJECT_NAME/CLAUDE.md`:

```
<!-- marrow:project:PROJECT_NAME:v0.5.1 -->
# PROJECT_NAME

PROJECT_DESCRIPTION

## Active Tasks

(none yet)

## Session Log
```

Write `MARROW_ROOT/PROJECT_NAME/index.md`:

```
---
description: Knowledge index for PROJECT_NAME
type: index
---

# PROJECT_NAME — Index

(No notes yet. Notes will appear here as they're created.)
```

Write `MARROW_ROOT/PROJECT_NAME/session-archive.md`:

```
# Session Archive

Archived session log entries, oldest first.
```

## Step 9: Write extract-links.sh helper

Write to `MARROW_ROOT/scripts/extract-links.sh`:

```bash
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
```

Then: `chmod +x MARROW_ROOT/scripts/extract-links.sh`

## Step 10: Confirm

Show the created directory structure.

Print:

**"You're all set! Marrow is ready at `MARROW_ROOT` with your first project, PROJECT_NAME.**

**To get started:** `cd MARROW_ROOT && claude`

**Your commands:**
- `/recall PROJECT_NAME` — load your project's context
- `/checkpoint` — save your progress
- `/new-project` — add another project"
