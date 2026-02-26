---
description: Connect an external project folder to Marrow
allowed-tools: Read, Write, Bash, Edit
argument-hint: "[project-name] — Marrow project to connect to"
---

# Joint

Connect an external project folder to Marrow. A joint is where two bones meet — your project folder and Marrow's knowledge.

## Preflight

Determine the Marrow root. Check common locations in order:
1. If `./CLAUDE.md` contains `<!-- marrow:root:v0.5.2 -->`, the current directory IS the Marrow root.
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
2. Read `MARROW_ROOT/index.md` for the knowledge map

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
2. Read `MARROW_ROOT/index.md` for the knowledge map

When finishing work:
1. Use `/checkpoint` to save progress (if Marrow plugin is installed)
2. Or manually append a session log entry to `MARROW_ROOT/PROJECT_NAME/CLAUDE.md`
```

Replace `MARROW_ROOT` and `PROJECT_NAME` with actual values in all generated content.

## Step 5: Confirm

Print: **"Connected! `FOLDER_PATH` now points to `MARROW_ROOT/PROJECT_NAME/` for full context."**
