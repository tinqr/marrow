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
