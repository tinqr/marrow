---
name: review
description: Triage accumulated observations. Classifies each finding, detects patterns across them, and generates proposals for system changes. Triggers on "/review", "review observations", "triage findings".
---

# /review

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse immediately:
- If target is empty: run full review (triage + pattern detection + proposals) on all pending observations
- If target is "triage": run triage only (classify and act, no pattern detection)
- If target is "patterns": skip triage, analyze existing evidence for patterns
- If target is a specific observation filename: triage that single item interactively

**START NOW.** Reference below defines the workflow.

---

## Philosophy

**The system is not sacred. Evidence beats intuition.**

Every rule in CLAUDE.md, every workflow in a skill, every assumption baked into the architecture was a hypothesis at some point. Observation notes in `ops/observations/` capture friction from actual use. /review triages these individually (some become notes, some become methodology updates, some get archived), then looks for patterns in the remaining evidence and proposes changes when patterns emerge.

Without this loop, the system ossifies -- it accumulates friction that never gets addressed and methodology learnings that never get elevated to system-level changes. /review is the immune system that prevents calcification.

---

## Phase 1: Triage

### 1a. Gather Pending Evidence

```bash
OBS_PENDING=$(grep -rl '^status: pending' ops/observations/ 2>/dev/null)
OBS_COUNT=$(echo "$OBS_PENDING" | grep -c . 2>/dev/null || echo 0)
```

Read each pending item fully. These are small atomic notes -- load all of them. Understanding the full content is required for accurate triage. If zero pending items, report clean state and exit early.

Also read `ops/methodology/` to understand existing methodology notes -- this prevents creating duplicates and informs whether new observations should extend existing methodology rather than create new notes.

### 1b. Classify Each Item

Assign exactly one disposition per observation:

| Disposition | Meaning | When to Apply | Action |
|-------------|---------|---------------|--------|
| PROMOTE | Reusable insight worth keeping as a permanent note | General principle across sessions. Would work as a note with a proposition title. Crystallized insight, not operational guidance. | Create note in notes/, set observation `status: promoted`, add `promoted_to: [[title]]` |
| IMPLEMENT | Operational guidance that should change the system | "System should do X differently." Points to a concrete improvement in CLAUDE.md, template, or skill. | Update the specific file, set `status: implemented`, add `implemented_in: [filepath]` |
| METHODOLOGY | Friction pattern that should inform agent behavior | Behavioral learning. Not a domain insight (PROMOTE) or a system change (IMPLEMENT) -- a methodology learning about HOW to operate. | Create or update methodology note in `ops/methodology/`, set `status: implemented`, add `implemented_in: ops/methodology/[file]` |
| ARCHIVE | Session-specific, no longer relevant | One-session-specific with no lasting value. Already addressed by later work. Superseded by newer evidence. | Set `status: archived` |
| KEEP PENDING | Not enough evidence yet | Might matter but need more data. Part of a pattern that has not fully emerged. Single data point that could go either way. | No change -- leave `status: pending` |

**Triage heuristics:**

- Observation describes a general principle that works across sessions -> PROMOTE
- Observation says "the system should do X differently" with a specific file/section -> IMPLEMENT
- Observation describes agent behavior that should change (how to process, when to check, what to avoid) -> METHODOLOGY
- Observation was about one specific session with no lasting value -> ARCHIVE
- Observation might matter but only appeared once -> KEEP PENDING

### 1c. Present Triage Table

Present the full triage to the user before executing any changes:

```
--=={ review -- Triage }==--

  Evidence: [N] observations

  PROMOTE ([count])
    [filename] -- [title] -> proposed note title
    [filename] -- [title] -> proposed note title

  IMPLEMENT ([count])
    [filename] -- [title] -> change [specific file/section]
    [filename] -- [title] -> change [specific file/section]

  METHODOLOGY ([count])
    [filename] -- [title] -> create/update ops/methodology/[name].md
    [filename] -- [title] -> extends existing ops/methodology/[name].md

  ARCHIVE ([count])
    [filename] -- [title] -- [reason for archiving]

  KEEP PENDING ([count])
    [filename] -- [title] -- [why more evidence needed]
```

Ask the user: "Review the triage above. Approve all, or list items to reclassify (e.g., 'keep obs-003 pending, promote obs-007 instead')."

**Wait for user confirmation before proceeding to 1d.** Do not execute triage without approval.

### 1d. Execute Triage

After user confirmation, apply all dispositions in order:

**For PROMOTE items:**
1. Create note with prose-as-title in notes/
2. Follow standard note schema: YAML frontmatter (description, type, area, created, topics), body developing the insight, Topics footer
3. The observation content becomes the seed for the note body -- but develop it fully, do not just copy the observation
4. Update the observation: set `status: promoted`, add `promoted_to: [[note title]]`

**For IMPLEMENT items:**
1. Make the specific change to the identified file/section
2. Show the change to the user (before/after) and get confirmation if the change is non-trivial
3. Update the observation: set `status: implemented`, add `implemented_in: [filepath]`

**For METHODOLOGY items:** (see Phase 2 below)

**For ARCHIVE items:**
1. Update observation status: `status: archived`
2. Move archived observations to `archive/observations/` (create directory if needed)

**For KEEP PENDING items:**
1. No changes -- leave in place

**Observation cleanup:** After all dispositions are applied, move any observation with `status: promoted`, `status: implemented`, or `status: archived` out of `ops/observations/` and into `archive/observations/`. This keeps the active observations folder clean for future /review runs.

---

## Phase 2: Methodology Updates

For items triaged as METHODOLOGY, create or update notes in `ops/methodology/`.

### Creating New Methodology Notes

```markdown
---
description: [what this methodology note teaches -- specific enough to be actionable]
type: methodology
category: [processing | capture | connection | maintenance | voice | behavior | quality]
source: review
created: YYYY-MM-DD
status: active
evidence: ["obs-filename-1", "obs-filename-2"]
---

# [prose-as-title describing the learned behavior]

[Body developing the methodology learning:
- What the agent should do
- What the agent should avoid
- Why this matters (what went wrong without this)
- When this applies (scope/context)]

---

Related: [[methodology]]
```

### Extending Existing Methodology Notes

If a methodology note with similar content already exists:
1. Do NOT create a duplicate
2. Instead, add the new evidence to the existing note
3. Update the evidence array in frontmatter
4. Strengthen or nuance the existing guidance based on the new observation
5. Update the observation: set `status: implemented`, add `implemented_in: ops/methodology/[existing-file]`

### Update Methodology Index

After creating or updating methodology notes, update `ops/methodology/methodology.md`:
- Add new notes to the appropriate category section
- Update context phrases for modified notes

---

## Phase 3: Pattern Detection

Analyze remaining pending evidence (post-triage) plus promoted/implemented history for systemic patterns. This is where individual data points become actionable signals.

### Evidence Sources

1. **Still-pending observations** -- items with `status: pending` after triage
2. **Recently promoted/implemented items** -- may share themes with pending items
3. **Methodology notes** -- patterns in `ops/methodology/` by category

### Pattern Types

| Pattern Type | Signal | Threshold | What It Means |
|-------------|--------|-----------|---------------|
| Recurring themes | 3+ observations about the same area | Systemic issue requiring structural response | Something is fundamentally misaligned in that area |
| Friction accumulation | Multiple observations about the same workflow step | Workflow needs redesign | A specific process is consistently painful |
| Methodology convergence | Multiple /remember captures in ops/methodology/ pointing at the same behavioral pattern | Methodology note needs elevation to CLAUDE.md | A methodology learning has been validated enough to become a system-level rule |

### Detection Method

1. **Group by category field:** Sort observations by their `category` (methodology, process-gap, friction, surprise, quality). 3+ items in the same category = potential pattern.

2. **Group by referenced indexes or system areas:** Extract wiki links and file references from observation bodies. 3+ observations referencing the same area = recurring theme.

3. **Check friction frequency for acceleration:** Are friction observations about the same step appearing more frequently? An accelerating pattern is a stronger signal than steady-state friction.

4. **Compare methodology notes against CLAUDE.md:** If `ops/methodology/` has 3+ notes in the same category that are not reflected in CLAUDE.md, the methodology has converged enough for elevation.

### Pattern Quality Check

**Do not fabricate patterns from insufficient evidence.** A single observation is a data point, not a pattern. Two observations are a coincidence. Three observations are a pattern worth investigating.

For each candidate pattern, assess:
- **Evidence count:** How many observations support this?
- **Time span:** Over how many sessions did these accumulate?
- **Specificity:** Can you point to a specific system area or assumption?
- **Impact:** What breaks or degrades because of this?

Only report patterns that pass all four checks.

### Pattern Report

```
--=={ review -- Patterns }==--

  Patterns detected: [N]

  1. [Pattern type]: [description]
     Evidence: [filenames, one per line]
     Area: [system area affected]
     Impact: [what breaks or degrades]
     Confidence: [high | medium -- never low, since low means not enough evidence]

  2. [Pattern type]: [description]
     ...

  No patterns found in: [areas with < 3 data points]
```

If no patterns are detected, report this clearly. Pattern detection requires sufficient evidence -- an empty result after triage is a sign the system is healthy, not that review failed.

---

## Phase 4: Proposal Generation

For each detected pattern, generate one specific, actionable proposal.

### Proposal Structure

```
  Proposal [N]: [title -- what would change]

  Evidence:
    - [filename] -- [one-line summary of this observation's contribution]
    - [filename] -- [one-line summary]
    - [filename] -- [one-line summary]

  Pattern: [which pattern type from Phase 3]

  Current assumption:
    [Quote the specific section of CLAUDE.md, skill, or template
     that embodies the assumption being challenged.
     Include the file path and section heading.]

  Proposed change:
    [Specific file and section. What changes, what stays.
     Before/after if possible. Concrete enough that someone
     could implement this without additional context.]

  What would improve:
    [Concrete expected benefit -- not "things would be better"
     but "reduces processing time for inbox items because..."
     or "prevents the duplicate creation issue observed in obs-003, obs-007"]

  What could go wrong:
    [Risk assessment -- what might break? What second-order effects?
     What assumptions does this proposal itself make?]

  Reversible: [yes | no | partially -- explain if partially]

  Scope: [claude-md | skill | template | methodology]
```

### Proposal Quality Gates

Every proposal MUST have:

1. **Specific file references** -- not "update CLAUDE.md" but "update CLAUDE.md, section 'Processing', paragraph 3"
2. **Evidence backing** -- at least 2 observations supporting the change. No intuition-only proposals.
3. **Risk awareness** -- what could go wrong. Proposals without risk assessment are overconfident.
4. **Proportionality** -- the scope of the proposed change should match the weight of evidence.
5. **Reversibility assessment** -- can this be undone if it makes things worse?

### Proposal Scope Rules

| Evidence Strength | Maximum Proposal Scope |
|-------------------|----------------------|
| 2 observations, same area | Methodology note update |
| 3+ observations, clear pattern | Skill or template change |
| 5+ observations, strong signal | CLAUDE.md section change |

Do not propose CLAUDE.md changes based on thin evidence. The threshold scales with the blast radius.

---

## Phase 5: Present for Approval

**NEVER auto-implement proposals.** Changes to system assumptions require human judgment. This is the invariant that makes review safe -- it can analyze aggressively because it cannot act unilaterally.

### Summary Output

```
--=={ review -- Complete }==--

  Triaged: [N] observations

    Promoted to notes:    [count]
    Methodology updates:  [count]
    Implemented:          [count]
    Archived:             [count]
    Kept pending:         [count]

  Patterns detected: [count]

    1. [Pattern type]: [brief description]
       Evidence: [count] items
       Proposal: [one-line summary]

    2. [Pattern type]: [brief description]
       Evidence: [count] items
       Proposal: [one-line summary]

  Awaiting approval for [count] proposals.
```

### User Approval Interaction

Ask the user: "Which proposals should I implement? (all / none / list numbers, e.g. '1, 3'). You can also ask me to modify a proposal before deciding."

**Handle each response:**

| Response | Action |
|----------|--------|
| "all" | Implement all proposals |
| "none" | Skip all. Optionally ask why to capture reasoning as a new observation. |
| "1, 3" | Implement listed proposals only |
| "modify 2" | Ask what should change, revise proposal, re-present for approval |
| Question about a proposal | Answer, then re-ask for approval |

### On Approval: Implementation

For each approved proposal:

1. **Draft the actual changes** -- write the literal new content, not descriptions of what to change
2. **Show before/after** for non-trivial changes
3. **Apply the changes** to the target files
4. **Log to ops/changelog.md** (create if missing):

```markdown
## YYYY-MM-DD: [change title]

**Source:** /review -- [pattern type]
**Evidence:** [observation filenames]
**Change:** [what was modified, which files]
**Risk:** [risk assessment from proposal]
```

5. **Update feeding observations:** Add `resolved_by: [changelog reference]` to each observation that contributed to the approved proposal

### On Rejection

- Do not re-propose the same change without new evidence
- Optionally ask why the proposal was rejected -- capture the reasoning as a new observation if the user's rationale reveals something about the system's design philosophy
- Mark the proposal as "considered and deferred" -- do not keep re-surfacing it

---

## Post-Review Actions

### Promoted Notes Need Connections

If any observations were promoted to notes:

```
  [count] notes were promoted from observations.
  Run /connect on promoted notes to find connections.
  Promoted: [list of note titles]
```

### Session Log

After review completes, capture the session itself. Create or append to `ops/review-log.md`:

```markdown
## YYYY-MM-DD HH:MM

**Evidence reviewed:** [N] observations
**Triage:** [count] promoted, [count] methodology, [count] implemented, [count] archived, [count] pending
**Patterns:** [count] detected
**Proposals:** [count] generated, [count] approved, [count] rejected, [count] deferred
**Changes applied:** [list of files modified]
```

This creates an evolution history. Future /review runs can consult the log to understand how the system has evolved and what patterns have driven changes.

---

## Edge Cases

### No ops/observations/ Directory

If it does not exist:
1. Report the structural gap
2. Recommend creating it: "The operational learning loop requires `ops/observations/`. Create this directory to begin capturing system friction."
3. Do not attempt to run review without evidence sources

### Nothing Pending

Report clean state:
```
--=={ review -- Clean State }==--

  No pending observations.
  The system has no accumulated friction to process.

  Continue capturing observations during normal work.
  Run /review again when signals accumulate.
```

### < 5 Total Items

Run triage normally but note that pattern detection requires more data:
```
  Note: [N] items is below the threshold for reliable pattern detection.
  Triage completed. Pattern analysis will be more reliable after more
  observations accumulate. This is expected early in the system lifecycle.
```

### Single Item Triage

When target is a specific filename:
1. Read only that item
2. Present single-item triage recommendation
3. Execute on approval
4. Skip pattern detection (single items do not make patterns)

### Conflicting Proposals

If two proposals would contradict each other (e.g., one suggests adding complexity, another suggests simplifying the same area):
1. Present both with explicit conflict flagging
2. Ask the user to choose one or synthesize
3. Do not implement both -- conflicting changes compound confusion

### Large Evidence Backlog (20+ items)

If the evidence pool is very large:
1. Triage in batches of 10
2. Present each batch for approval before continuing
3. This prevents overwhelming the user with a 30-item triage table
4. Run pattern detection after all batches are triaged

---

## Critical Constraints

**Never:**
- Auto-implement system changes -- proposals require human approval, always
- Dismiss evidence because it is inconvenient
- Preserve assumptions out of tradition -- evidence beats habit
- Re-propose rejected changes without new evidence

**Always:**
- Trace proposals to specific evidence with file references
- Acknowledge uncertainty -- "I think" vs "it is" based on evidence strength
- Propose tests for new approaches -- how will you know if the change worked?
- Respect that the human makes final decisions on system changes
- Log changes to ops/changelog.md for evolution tracking
- Move processed observations to archive/observations/ after triage
- Log review sessions to ops/review-log.md

## The Meta-Layer

Review is the system's immune system. It detects when assumptions have become infections -- beliefs that made sense once but now cause harm. Healthy systems challenge themselves. Unhealthy systems calcify around untested assumptions.

The methodology learning loop closes here:
```
Work happens -> friction captured as observations
  -> /remember captures immediate corrections
  -> observations accumulate
  -> /review triages + detects patterns + proposes changes
  -> human approves changes
  -> system evolves
  -> less friction -> fewer observations -> healthy system
```

Run /review. Let evidence win.
