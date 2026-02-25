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
