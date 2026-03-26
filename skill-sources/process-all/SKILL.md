---
name: process-all
description: Batch process the inbox with fresh context per source. Spawns an isolated subagent for each inbox item to prevent context contamination. Supports dry run mode. Triggers on "/process-all", "process inbox", "batch process".
---

# /process-all

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse arguments:
- N (optional): number of inbox items to process (default: all pending)
- --dry-run: show what would execute without running

**START NOW.** Process inbox items.

---

## MANDATORY CONSTRAINT: SUBAGENT SPAWNING IS NOT OPTIONAL

**You MUST use the Task tool to spawn a subagent for EVERY inbox item. No exceptions.**

This is not a suggestion. This is not an optimization you can skip for "simple" items. The entire architecture depends on fresh context isolation per source. Executing items inline in the lead session:
- Contaminates context (later items run on degraded attention)
- Skips the handoff protocol (learnings are not captured)
- Violates the process-all pattern (one source per context window)

**If you catch yourself about to process an item directly instead of spawning a subagent, STOP.** Call the Task tool. Every time. For every item. Including "simple" items.

The lead session's ONLY job is: scan inbox, spawn subagent, evaluate return, report progress, repeat.

---

## Step 1: Scan Inbox

```bash
ls -1 inbox/ 2>/dev/null | grep -v '.gitkeep'
```

Count items. If inbox is empty, report: "Inbox is empty. Nothing to process."

Read each inbox item briefly (first 10 lines) to understand what it is -- a raw note, a source, a half-formed idea.

## Step 2: Build Processing List

Order items by modification time (oldest first -- FIFO). Apply limit if N was specified.

## Step 3: Present Inbox and Confirm

Show the user what will be processed:

```
--=={ process-all }==--

Inbox: X items

Items to process:
1. [filename] -- [brief description of content]
2. [filename] -- [brief description of content]
...

Estimated: ~[N] subagent spawns
```

**If --dry-run:** Show the list above and STOP (do not process).

**Otherwise:** Ask the user: "Process these [N] items? (yes / select numbers / no)"

Wait for confirmation before proceeding to Step 4. Do not process without approval.

---

## Step 4: Process Loop

For each inbox item:

### 4a. Select Next Item

Pick the next item from the processing list. Read its full content.

Report:
```
=== Processing item [i]/[N]: [filename] ===
```

### 4b. Build Subagent Prompt

Construct a prompt for the subagent. Every prompt MUST include:
- The full content of the inbox item (or a path to it)
- Instruction to run /process on this source
- Instruction to output a handoff block when done

```
You are processing an inbox item for a knowledge vault.

Source file: inbox/[FILENAME]
Content:
---
[FULL CONTENT OF THE INBOX ITEM]
---

Run /process on this source. Follow the vault's note design rules:
- Extract insights as individual notes (one idea per note, title as proposition)
- YAML frontmatter with description, type, area, created, topics
- Find connections to existing notes, add wiki links
- Update relevant indexes

After processing, output a PROCESS-ALL HANDOFF block:

=== PROCESS-ALL HANDOFF: [filename] ===
Notes Created:
- [list of note titles and paths]

Notes Modified:
- [list of modified notes with what changed]

Indexes Updated:
- [list of indexes updated]

Learnings:
- [Friction]: [description] | NONE
- [Surprise]: [description] | NONE
- [Connection]: [interesting cross-domain link found] | NONE
=== END HANDOFF ===
```

### 4c. Spawn Subagent (MANDATORY -- NEVER SKIP)

Call the Task tool with the constructed prompt:

```
Task(
  prompt = [the constructed prompt from 4b],
  description = "process: [short description]" (5 words max)
)
```

**REPEAT: You MUST call the Task tool here.** Do NOT execute the prompt yourself. Do NOT "optimize" by running the task inline. The Task tool call is the ONLY acceptable action at this step.

Wait for the subagent to complete and capture its return value.

### 4d. Evaluate Return

When the subagent returns:

1. **Look for PROCESS-ALL HANDOFF block** -- search for `=== PROCESS-ALL HANDOFF` and `=== END HANDOFF ===` markers
2. **If handoff found:** Parse the Notes Created, Notes Modified, Indexes Updated, and Learnings sections
3. **If handoff missing:** Log a warning but continue -- the work was still completed
4. **Capture learnings:** If Learnings section has non-NONE entries, note them for the final report

### 4e. Clean Up Inbox Item

After successful processing, move the source out of inbox:

```bash
mv inbox/[FILENAME] archive/[FILENAME]
```

If the archive/ directory doesn't exist, create it first.

### 4f. Handle Errors

If a subagent fails or crashes:
1. Log the error: "ERROR: [filename] -- [error description]"
2. Do NOT move the item to archive/ (it was not successfully processed)
3. Add to the failure list for the final report
4. Continue with the next item -- do not abort the entire batch

### 4g. Report Progress

```
=== Item [filename] complete ([i]/[N]) ===
Notes created: [count]
```

If learnings were captured, show a brief summary.

---

## Step 5: Final Report

After all items are processed:

```
--=={ process-all }==--

Processed: [count]/[total] inbox items

Subagents spawned: [count] (MUST equal items attempted)

Notes created: [total count]
  [list of all note titles]

Notes modified: [total count]
  [list of modified notes]

Indexes updated: [total count]
  [list of indexes]

Failures: [count]
  [list of failed items with error descriptions, or "None"]

Learnings captured:
  [list any friction, surprises, connections, or "None"]

Inbox: [remaining count] items
Archive: [count] items moved to archive/

Next steps:
  [if failures]: Review failed items in inbox/, fix issues, re-run /process-all
  [if more inbox items]: Run /process-all to continue
  [if inbox empty]: Inbox clear. All sources processed.
  [if disconnected notes]: Run /connect on newly created notes
```

**Verification:** The "Subagents spawned" count MUST equal "Items processed." If it does not, the lead executed items inline -- this is a process violation. Report it as an error.

---

## Error Recovery

**Subagent crash mid-processing:** The inbox item is still in inbox/ (not yet moved to archive/). Re-running /process-all picks it up automatically.

**Empty inbox:** Report "Inbox is empty. Nothing to process." and stop.

**Malformed inbox item:** If an item cannot be parsed (binary file, empty file, etc.), skip it and report: "Skipped [filename] -- could not parse content."

---

## Quality Gates

### Gate 1: Subagent Spawned
Every item MUST be processed via Task tool. If the lead detects it executed a task inline, log this as an error and flag it in the final report.

### Gate 2: Handoff Present
Every subagent SHOULD return a PROCESS-ALL HANDOFF block. If missing: log warning, continue.

### Gate 3: Notes Created
For each item: if zero notes extracted, log as an observation. Some inbox items may be too vague to extract insights from -- that is acceptable but should be reported.

### Gate 4: Inbox Item Archived
After successful processing, the inbox item MUST be moved to archive/. If it remains in inbox/, it will be reprocessed on the next run.

---

## Critical Constraints

**Never:**
- Execute items inline in the lead session (USE THE TASK TOOL)
- Process more than one source per subagent (context contamination)
- Delete inbox items (move to archive/ instead)
- Skip the handoff block (subagents must report what they did)
- Process items that are not in inbox/

**Always:**
- Spawn a subagent via Task tool for EVERY item (the lead ONLY orchestrates)
- Move processed items to archive/
- Log learnings from handoff blocks
- Report failures clearly for human review
- Verify subagent count equals item count in final report
