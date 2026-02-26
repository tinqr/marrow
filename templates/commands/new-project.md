---
description: Add a new project to your Marrow knowledge store
allowed-tools: Read, Write, Bash, Edit
argument-hint: "[project-name] — optional project name"
---

# New Project

Add a new project to this Marrow.

## Preflight

Check that `./CLAUDE.md` contains `<!-- marrow:root:v0.5.2 -->`. If not, tell the user this isn't a Marrow directory. You can set one up with `/marrow:setup`.

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
<!-- marrow:project:PROJECT_NAME:v0.5.2 -->
# PROJECT_NAME

PROJECT_DESCRIPTION

## Active Tasks

(none yet)

## Session Log
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

## Step 5: Add to global index

Read `./index.md`. Append a new section:

```
## PROJECT_NAME

(No notes yet.)
```

## Step 6: Confirm

Print: **"Project 'PROJECT_NAME' created! Use `/recall PROJECT_NAME` to start working on it."**
