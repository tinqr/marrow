---
name: marrow:tasks
description: View and manage the task stack. Shows pending work, completed items, and discoveries. Triggers on "/tasks", "show tasks", "what's pending", "task list".
user-invocable: true
context: fork
model: sonnet
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
argument-hint: "[add|done|drop|reorder|status] [description|number] -- manage task stack"
---

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse the operation:
- No arguments or `status`: show task stack
- `status [area]`: show tasks filtered by area tag (e.g., `/tasks status design`)
- `add [area-tag] [description]`: add a task to the stack (e.g., `/tasks add [building] implement SMS parser`)
- `done [task-number]`: mark a task as completed
- `drop [task-number]`: remove a task without completing
- `reorder [number] [position]`: move a task to a different position
- `discoveries`: show only the Discoveries section

**START NOW.** Execute the requested operation.

---

## Philosophy

The task stack (`ops/tasks.md`) is your working memory. It tracks what YOU want to work on, ordered by priority. Position 1 is highest priority.

**Area tags:** Every task carries an area tag in square brackets -- `[design]`, `[building]`, `[learning]`, `[finance]`, or `[life]`. The tag determines what kind of output the task produces. `/tasks add` must include an area tag. `/tasks status` can filter by area.

---

## Operations

### /tasks (or /tasks status)

**Step 1: Read task stack**

Read `ops/tasks.md`. Parse into sections:
- **Active**: items marked `- [ ]`
- **Completed**: items marked `- [x]`
- **Discoveries**: items noted during work (plain text, no checkbox)

If `ops/tasks.md` does not exist: "No task stack found. Run `/tasks add [description]` to create one."

**Step 2: Present**

```
--=={ tasks }==--

  Task Stack (ops/tasks.md)
  =========================
  Active:
    1. [ ] {task description}
    2. [ ] {task description}
    3. [ ] {task description}

  Completed:
    - [x] {task description} (2026-02-10)
    - [x] {task description} (2026-02-08)

  Discoveries:
    - {discovery noted during work}

  Summary: {total active} tasks on stack
```

**Interpretation notes:**

| Condition | Note |
|-----------|------|
| Task stack empty | "No tasks on stack. Use `/tasks add [description]` to add one, or `/next` for suggestions." |
| Both empty | "All clear. Use `/next` to find what to work on." |

### /tasks add [description]

**Step 1: Read current ops/tasks.md**

If the file does not exist, create it with the standard structure:

```markdown
# Tasks

## Active

## Completed

## Discoveries
```

**Step 2: Add to Active section**

Append the new task as a checkbox item at the END of the Active section. The description MUST include an area tag:

```markdown
- [ ] [building] {description}
```

If the user omits the area tag, ask which area this task belongs to before adding.

**Step 3: Write updated file**

Use Edit tool to insert the new item at the end of the Active section, preserving existing content.

**Step 4: Report**

```
Added to task stack: {description}
Position: #{N} of {total}

Stack now has {total} active tasks.
```

### /tasks done [number]

**Step 1: Read current ops/tasks.md**

Parse the Active section to find the Nth task.

**Step 2: Validate**

If the number is out of range (< 1 or > number of active tasks):
```
Error: Task #{number} does not exist. Active tasks: 1-{max}.
```

**Step 3: Move to Completed**

1. Remove the item from Active section
2. Add to Completed section with today's date:
   ```markdown
   - [x] {description} ({YYYY-MM-DD})
   ```
3. Renumber remaining Active items (if display uses numbers)

**Step 4: Write updated file**

**Step 5: Report**

```
Completed: {description}

Remaining: {N} active tasks.
```

**Integration with /next:** If the completed task was the top-priority item, suggest: "Top task completed. Run `/next` for the next recommendation."

### /tasks drop [number]

**Step 1: Read current ops/tasks.md**

Parse the Active section to find the Nth task.

**Step 2: Validate**

Same range check as /tasks done.

**Step 3: Remove from Active**

Remove the item entirely. Do NOT move to Completed.

**Step 4: Write updated file**

**Step 5: Report**

```
Dropped: {description}

Remaining: {N} active tasks.
```

### /tasks reorder [number] [position]

**Step 1: Read current ops/tasks.md**

Parse all Active items.

**Step 2: Validate**

Both [number] (source) and [position] (destination) must be within range.

**Step 3: Reorder**

1. Remove the task from position [number]
2. Insert at position [position]
3. Renumber remaining items

**Step 4: Write updated file**

**Step 5: Report**

```
Moved: {description}
  From position #{number} to #{position}

Active stack:
  1. [ ] {task 1}
  2. [ ] {task 2}
  ...
```

### /tasks discoveries

Show only the Discoveries section from ops/tasks.md.

```
  Discoveries (process later):
    - {discovery 1}
    - {discovery 2}
    ...

  [If empty: "No discoveries captured. Discoveries are noted during work
   for processing in a future session."]
```

Discoveries accumulate during work (e.g., /process notes a connection opportunity, /connect notices a split candidate). They stay here until the user converts them to tasks or discards them.

---

## Task Stack Format

```markdown
# Tasks

## Active
- [ ] [building] First priority task
- [ ] [design] Second priority task
- [ ] [learning] Third priority task

## Completed
- [x] [building] Something finished (2026-02-10)
- [x] [design] Earlier task (2026-02-08)

## Discoveries
- Interesting connection between [[note A]] and [[note B]] found during /process
- Index [[topic]] might need splitting (40+ notes observed during /connect)
```

**Active** is ordered by priority. Position 1 is highest priority. Every task carries an area tag (`[design]`, `[building]`, `[learning]`, `[finance]`, `[life]`).

**Completed** is ordered by completion date (most recent first). Area tags are preserved for history.

**Discoveries** is unordered. Items accumulate during work -- skills like /process, /connect, and /revisit can note connection opportunities, split candidates, or interesting patterns here. The user converts them to Active tasks or discards them.

---

## Edge Cases

### No ops/tasks.md

Create it with empty sections on first `/tasks add`. For `/tasks status`, report: "No task stack found. Use `/tasks add [description]` to create one."

### Task Number Out of Range

Report the error with the valid range: "Task #{N} does not exist. Active tasks: 1-{max}."

### Empty Task Stack (Active section empty)

```
  Task Stack (ops/tasks.md)
  =========================
  Active:
    (empty)

  Use `/tasks add [description]` to add a task,
  or `/next` for automated suggestions.
```

### Concurrent Modification

If multiple agents modify ops/tasks.md simultaneously, last write wins. The file is small enough that conflicts are unlikely, but if detected, report: "Task stack may have been modified by another session. Please review."

### Discovery Promotion

When a user wants to convert a discovery to a task:
1. Show the discovery
2. Ask which area tag it belongs to
3. Ask for confirmation and priority position
4. Add to Active section with area tag
5. Remove from Discoveries section

This is a manual workflow -- discoveries do not auto-promote.
