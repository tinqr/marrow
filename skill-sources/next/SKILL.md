---
name: next
description: Surface the most valuable next action by combining task stack, inbox pressure, vault health, and goals. Recommends one specific action with rationale. Triggers on "/next", "what should I do", "what's next".
user-invocable: true
context: fork
model: sonnet
allowed-tools: Read, Grep, Glob, Bash
---

## EXECUTE NOW

**INVARIANT: /next recommends, it does not execute.** Present one recommendation with rationale. The user decides what to do. This prevents cognitive outsourcing where the system makes all work decisions and the user becomes a rubber stamp.

**Execute these steps IN ORDER:**

---

### Step 1: Check Active Session

Read `ops/sessions/current.json`. If it exists and has active work (notes being edited, a task in progress, a feature being designed or built), **recommend continuing that work before suggesting anything new.**

Active session work overrides everything except the task stack. The user chose to work on something -- resuming that context is almost always more valuable than switching to a new recommendation.

If current.json shows no active work, or does not exist, proceed to Step 2.

---

### Step 2: Read Maintenance Thresholds

Read `marrow.yaml` for configured thresholds. If it does not exist, use defaults:
- `inbox_warning`: 5
- `observations_warning`: 10
- `stale_feature_days`: 14
- `stale_index_days`: 30

---

### Step 3: Evaluate Maintenance Conditions

Before collecting general state, check conditions that have configured thresholds. This ensures maintenance signals are current before the recommendation engine runs.

| Condition | How to Check | Threshold (from marrow.yaml or default) |
|-----------|-------------|----------------------------------------|
| inbox_pressure | Count `*.md` in `inbox/` | inbox_warning (default: 5) |
| observations | Count `status: pending` in `ops/observations/` | observations_warning (default: 10) |
| stale_features | Feature notes in `notes/*/` not modified in N days, still marked active | stale_feature_days (default: 14) |
| stale_indexes | Area/project indexes not modified in N days, area still active | stale_index_days (default: 30) |
| orphan_notes | Notes with zero incoming `[[links]]` | any (> 0) |
| dangling_links | `[[links]]` pointing to non-existent files | any (> 0) |

Record each condition's current value. Conditions that exceed their threshold become session-priority recommendations in Step 6 (priority level 1.5).

---

### Step 4: Collect Vault State

Gather all signals. Run independent checks in parallel where possible. Record each signal even if the check returns zero -- absence of signal is itself informative.

| Signal | How to Check | What to Record |
|--------|--------------|----------------|
| **Task stack** | Read `ops/tasks.md` -- active priorities and open items | Top items, open count, area tags, any deadlines |
| **Inbox pressure** | Count `*.md` files in `inbox/`, find oldest by mtime | Count, age of oldest item in days |
| **Note count** | Count `*.md` in `notes/` (recursive) | Total notes for context |
| **Orphan notes** | For each note, grep for `[[filename]]` across all files -- zero hits = orphan | Count, first 5 names |
| **Dangling links** | Extract all `[[links]]` from notes/, verify each target file exists | Count, first 5 targets |
| **Stale notes** | Notes not modified in 30+ days with < 2 incoming links | Count, most-connected stale note |
| **Goals** | Read `self/goals.md` -- current priorities, active threads | Priority list, active directions |
| **Observations** | Count files with `status: pending` in `ops/observations/` | Count |
| **Active session** | Read `ops/sessions/current.json` -- active work context | Active task, last session date |
| **Recent /next** | Read `ops/next-log.md` (if exists) -- last 3 recommendations | Previous suggestions to avoid repetition |

**Adaptation rules:**
- Skip checks silently for directories that do not exist -- do not report missing directories
- A missing directory means that feature is not active, which is valid state

**Signal collection commands:**

```bash
# Inbox pressure
INBOX_COUNT=$(find inbox/ -name "*.md" -maxdepth 2 2>/dev/null | wc -l | tr -d ' ')
OLDEST_INBOX=$(find inbox/ -name "*.md" -maxdepth 2 -exec stat -f "%m %N" {} \; 2>/dev/null | sort -n | head -1)

# Note count
NOTE_COUNT=$(find notes/ -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

# Pending observations
OBS_COUNT=$(grep -rl '^status: pending' ops/observations/ 2>/dev/null | wc -l | tr -d ' ')
```

---

### Step 5: Classify by Consequence Speed

Evaluate every signal against consequence speed -- how fast does inaction degrade the system?

| Speed | Signals | Threshold | Why This Priority |
|-------|---------|-----------|-------------------|
| **Session** | Inbox > threshold, orphan notes (any), dangling links (any), 10+ pending observations, stale feature notes (active but untouched > stale_feature_days) | Immediate -- these degrade work quality right now | Orphans are invisible to traversal. Dangling links confuse navigation. Inbox pressure means lost ideas. Stale features mean lost context. |
| **Multi-session** | Stale notes > 10, inbox items aging > 7 days, stale indexes (> stale_index_days) | Soon -- these compound over days | Stale notes represent decaying knowledge. Aging inbox means capture is outpacing processing. |
| **Slow** | Index oversized (>20 notes), link density below 2.0 average, low note count relative to time | Background -- annoying but not blocking | These are maintenance tasks. Important for long-term health but not urgent. |

**Signal interaction rules:**
- Task stack items ALWAYS override automated recommendations (user-set priorities beat system-detected urgency)
- Multiple session-priority signals: pick the one with highest impact (most items affected)
- If inbox pressure AND other issues: recommend processing inbox first (processing needs input before it can generate connections)

---

### Step 6: Generate Recommendation

Select the SINGLE most valuable action. The recommendation must be specific enough to execute immediately -- a concrete command invocation, not a vague suggestion.

**Priority cascade:**

#### 0. Active Session Continuation

If Step 1 found active work in `ops/sessions/current.json`, recommend resuming it. State what was in progress and the next step from the session state.

#### 1. Task Stack First

If `ops/tasks.md` has open items, recommend from the task stack. User-set priorities override all automated recommendations because:
- The user has context the system does not
- Ignoring explicit priorities erodes trust
- Task stack items represent deliberate decisions, not automated detection

Format: Recommend the specific task with context about why it was in the stack.

#### 1.5. Maintenance Conditions (from Step 3)

If no task stack items, check the maintenance conditions evaluated in Step 3. If any condition exceeds its configured threshold, it becomes a session-priority recommendation:

| Condition | Recommendation | Impact |
|-----------|---------------|--------|
| orphan_notes | `/connect` or specific fix | "{N} notes invisible to traversal" |
| dangling_links | Fix broken links | "{N} broken links confusing navigation" |
| inbox_pressure | `/process [specific file]` | "{N} items aging in inbox" |
| stale_features | `/revisit [[feature note]]` | "Feature note not updated in {N} days but still active" |
| observations | Review observations | "{N} unprocessed observations accumulating" |

Pick the highest-impact condition. If multiple conditions fire, prioritize by the order above (structural health before content processing).

#### 2. Session-Priority Signals

If no task stack items and no maintenance conditions, pick the highest-impact session-priority signal:

| Signal | Recommendation | Rationale Template |
|--------|---------------|-------------------|
| Dangling links / orphans | `/connect` or specific fix command | "You have [N] orphan notes invisible to traversal. Connecting them increases graph density and retrieval quality." |
| 10+ observations | `/review` | "[N] pending observations have accumulated. Processing this backlog evolves the system." |
| Inbox > threshold | `/process [specific file]` | "Your inbox has [N] items (oldest: [age]). [File X] has the highest connection potential based on [reason]." |

**When recommending inbox processing:** Choose the specific inbox item that aligns best with current goals or has the most connection potential to existing notes. Recommend a concrete file, not "process some inbox."

#### 3. Multi-Session Signals

If no session-priority items:

| Signal | Recommendation | Rationale Template |
|--------|---------------|-------------------|
| Stale notes > 10 | `/revisit [specific note]` | "[N] notes haven't been touched since [date]. [Note X] has the most connections and would benefit most from updating." |
| Research gaps | `/process [file aligned with goals]` | "Your goals mention [topic] but your graph has few notes there. [Inbox item] addresses this gap." |

**When recommending revisiting:** Choose the most-connected stale note (highest link density + oldest modification). Revisiting high-connectivity notes has the highest ripple effect.

#### 4. Slow Signals

If nothing pressing:

| Signal | Recommendation | Rationale Template |
|--------|---------------|-------------------|
| Index oversized | Restructuring suggestion | "[Index X] has [N] notes. Splitting into sub-indexes improves navigation and reduces cognitive load." |
| Low link density | `/revisit` on lowest-density note | "Your graph has an average link density of [N]. Revisiting sparse notes increases traversal paths." |

#### 5. Everything Clean

If all signals are healthy:

```
next

  All signals healthy.
  Inbox: 0 | Orphans: 0 | Dangling: 0

  No urgent work detected.

  Suggested: Explore a new direction from goals.md
  or revisit older notes to deepen the graph.
```

**Rationale is always mandatory.** Every recommendation must explain:
1. WHY this action over alternatives
2. What DEGRADES if this action is deferred
3. How it connects to goals (if applicable)

---

### Step 7: Deduplicate

Read `ops/next-log.md` (if it exists). Check the last 3 entries.

**Deduplication rules:**
- If the same recommendation appeared in the last 2 entries, select the next-best action instead
- This prevents the system from getting stuck recommending the same thing repeatedly when the user has chosen not to act on it
- If the same recommendation is genuinely the highest priority (e.g., inbox pressure keeps growing), add an explicit note: "This was recommended previously. The signal has grown stronger since then ([before] -> [now])."

---

### Step 8: Output

```
next

  State:
    Inbox: [count] items (oldest: [age])
    Orphans: [count] | Dangling: [count]
    Observations: [count]
    [any other decision-relevant signals]

  Recommended: [specific command/action]

  Rationale: [2-3 sentences -- why this action,
  how it connects to goals, what degrades if deferred]

  After that: [second priority, if relevant]
```

**Command specificity is mandatory.** Recommendations must be concrete invocations:

| Good | Bad |
|------|-----|
| `/process inbox/article-on-spaced-repetition.md` | "process some inbox items" |
| `/revisit [[note title here]]` | "update some old notes" |
| `/review` | "review your observations" |

**State display rules:**
- Show only 2-4 decision-relevant signals -- not all checks
- Zero-count signals that are healthy can be omitted (don't show "Orphans: 0" unless contrasting with a problem)
- Non-zero signals at session or multi-session priority should always be shown

---

### Step 9: Log the Recommendation

Append to `ops/next-log.md` (create if missing):

```markdown
## YYYY-MM-DD HH:MM

**State:** Inbox: [N] | Notes: [N] | Orphans: [N] | Dangling: [N] | Obs: [N]
**Recommended:** [action]
**Rationale:** [one sentence]
**Priority:** session | multi-session | slow
```

**Why log?** The log serves three purposes:
1. Deduplication -- prevents recommending the same action repeatedly
2. Evolution tracking -- shows what signals have been persistent vs transient
3. Persistent recommendations that go unacted-on may reveal misalignment between what the system detects and what the user values

---

## Edge Cases

### Empty Vault (0-5 notes)

Recommend capturing or processing content. Maintenance is premature with < 5 notes -- the graph does not have enough nodes for meaningful analysis.

```
next

  State:
    Notes: [N] -- early stage vault

  Recommended: Capture or /process content
  Rationale: Your graph has [N] notes. At this stage, adding
  content matters more than maintaining structure. Health checks,
  revisiting, and review become valuable after ~10 notes.
```

### Everything Clean

Say so explicitly. Recommend exploratory work aligned with goals, or revisiting older notes:

```
  No urgent work detected. Consider:
  - Exploring a research direction from goals.md
  - Revisiting older notes to deepen connections
  - Reviewing and updating goals.md itself
```

### No Goals File

Recommend creating `self/goals.md` first. Without priorities, recommendations lack grounding.

```
  Recommended: Create self/goals.md
  Rationale: Without goals, /next can only recommend based on
  automated detection. Goals let the system align recommendations
  with what actually matters to you.
```

### Multiple Session-Priority Signals

When several signals are at session priority simultaneously, pick the one that unblocks the most downstream work:
- Dangling links block graph traversal -- fix first
- Observation threshold -- review prevents methodology drift
- Inbox pressure -- processing prevents idea loss

If genuinely equal priority, pick the one the user has not been recommended recently (check next-log.md).

---

## Anti-Patterns

These are patterns that /next must avoid:

| Anti-Pattern | Why It Is Wrong | What to Do Instead |
|-------------|----------------|-------------------|
| Recommending everything | Overwhelms the user, defeats the purpose of "single most valuable action" | Pick ONE. Mention a second only as "after that" |
| Vague recommendations | "Process inbox" gives no actionable starting point | Name the specific file, note, or command |
| Ignoring task stack | User-set priorities exist for a reason | Always check ops/tasks.md first |
| Repeating the same rec | If the user did not act on it, recommending it again is nagging | Deduplicate via next-log.md |
| Recommending maintenance too early | A 5-note vault does not need health checks | Scale recommendations to vault maturity |
| Cognitive outsourcing | Making all decisions for the user | Recommend and explain -- never execute |
