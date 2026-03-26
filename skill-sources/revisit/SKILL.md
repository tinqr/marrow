---
name: revisit
description: Update old notes with new connections. Revisit existing notes that predate newer related content, add connections, sharpen claims, consider splits. Triggers on "/revisit", "/revisit [note]", "update old notes", "backward connections", "revisit notes".
user-invocable: true
context: fork
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse immediately:
- If target contains `[[note name]]` or note name: revisit that specific note
- If target is empty: find notes that most need revisiting (oldest, sparsest, most outdated)
- If target is "recent" or "--since Nd": revisit notes not touched in N days
- If target is "sparse": find notes with fewest connections

**Execute these steps:**

1. **Read the target note fully** -- understand its current claim, connections, and age
2. **Ask the revisit question:** "If I wrote this note today, with everything I now know, what would be different?"
3. **Search for newer related notes** -- use index browsing and keyword search to find notes created AFTER the target that should connect
4. **Evaluate what needs changing:**
   - Add connections to newer notes that did not exist when this was written
   - Sharpen the claim if understanding has evolved
   - Consider splitting if the note now covers what should be separate ideas
   - Challenge the claim if new evidence contradicts it
   - Check if a newer note supersedes this one (same claim, said better)
   - Flag stale references (outdated tools, reversed decisions, temporal claims)
   - Rewrite prose if understanding is deeper now
5. **Make the changes** -- edit the note with new connections (inline links with context), improved prose, sharper claim if needed
6. **Update indexes** -- if the note's topic membership changed, update relevant indexes
7. **Report** -- structured summary of what changed and why

**START NOW.** Reference below explains methodology -- use to guide, not as output.

---

# Revisit

Revisit old notes with everything you know today. Notes are living documents -- they grow, get rewritten, split apart, sharpen their claims. This is the backward pass that keeps the network alive.

## Philosophy

**Notes are living documents, not finished artifacts.**

A note written last month was written with last month's understanding. Since then:
- New notes exist that relate to it
- Understanding of the topic deepened
- The claim might need sharpening or challenging
- What was one idea might now be three
- Connections that were not obvious then are obvious now

Revisiting is not just "add backward links." It is completely reconsidering the note based on current knowledge. Ask: **"If I wrote this note today, what would be different?"**

> "The note you wrote yesterday is a hypothesis. Today's knowledge is the test."

## What Revisiting Can Do

| Action | When to Do It |
|--------|---------------|
| **Add connections** | Newer notes exist that should link here |
| **Rewrite content** | Understanding evolved, prose should reflect it |
| **Sharpen the claim** | Title is too vague to be useful |
| **Split the note** | Multiple claims bundled together |
| **Challenge the claim** | New evidence contradicts the original |
| **Mark as superseded** | A newer note says the same thing better |
| **Flag stale references** | Information the note cites has become outdated |
| **Improve the description** | Better framing emerged |
| **Update examples** | Better illustrations exist now |

Revisiting is NOT just adding backward links. It is a full reconsideration.

## Invocation Patterns

### /revisit [[note]]

Fully reconsider a specific note against current knowledge.

### /revisit (no argument)

Scan for candidates needing revisiting, present ranked list.

### /revisit --sparse

Process notes flagged as sparse (fewest connections).

### /revisit --since Nd

Revisit all notes not updated in N days.

**How to find candidates:**
```bash
# Find notes not modified in 30 days
find notes/ -name "*.md" -mtime +30 -type f
```

---

## Workflow

### Phase 1: Understand the Note as It Exists

Read the target note completely. Understand:
- What claim does it make?
- What reasoning supports the claim?
- What connections does it have?
- When was it written/last modified?
- What was the context when it was created?

### Phase 2: Gather Current Knowledge

Use dual discovery -- index exploration AND keyword search.

**Path 1: Index Exploration** -- curated navigation

From the note's Topics footer, identify which indexes it belongs to:
- Read the relevant indexes
- What synthesis exists that might affect this note?
- What newer notes should this note reference?

**Path 2: Keyword Search** -- find what indexes might miss

Search for the note's core concepts across the vault:

```bash
# Search for related content
grep -rl 'key concept from note' notes/ --include="*.md"
```

**Also check backlinks** -- what notes already reference this one? Do they suggest the target should cite back?

```bash
grep -rl '\[\[target note title\]\]' notes/ --include="*.md"
```

**Key question:** What do I know today that I did not know when this note was written?

### Phase 3: Evaluate the Claim

**Does the original claim still hold?**

| Finding | Action |
|---------|--------|
| Claim holds, evidence strengthened | Add supporting connections |
| Claim holds but framing is weak | Rewrite for clarity |
| Claim is too vague | Sharpen to be more specific |
| Claim is too broad | Split into focused notes |
| Claim is partially wrong | Revise with nuance |
| Claim is contradicted | Flag tension, propose revision |
| Claim is superseded | A newer note says this better -- mark as superseded |
| References are outdated | Information the note cites or assumes has changed |

**Supersede detection:** If during Phase 2 you discover a newer note that makes the same claim more precisely, with better evidence, or in sharper language, this note may be superseded. Do not silently delete -- mark the old note with a superseded-by link:

```markdown
> **Superseded by [[newer note title]]** -- the newer note covers this ground with [reason it's better].
```

The superseded note remains in the vault (it may still have unique connections) but its claim is no longer the canonical version.

**Staleness detection:** Check whether the note references information that has become outdated:
- Tools, libraries, or APIs that have changed significantly
- Decisions that were later reversed (check for contradicting newer notes)
- Temporal claims ("currently", "as of") that may no longer hold
- Links to external resources that may have moved or changed

Flag stale references explicitly in the proposal. Do not silently update -- the user may have context about whether the reference is still valid.

**The Sharpening Test:**

Read the title. Ask: could someone disagree with this specific claim?
- If yes, the claim is sharp enough
- If no, it is too vague and needs sharpening

Example:
- Vague: "context matters" (who would disagree?)
- Sharp: "explicit context beats automatic memory" (arguable position)

**The Split Test:**

Does this note make multiple claims that could stand alone?
- If the note connects to 5+ topics across different domains, it probably needs splitting
- If you would want to link to part of it but not all, it is a split candidate

### Phase 4: Evaluate Connections

**Backward connections (what this note should reference):**

For each newer note, ask:
- Does it extend this note's argument?
- Does it provide evidence or examples?
- Does it share mechanisms?
- Does it create tension worth acknowledging?
- Would referencing it strengthen the reasoning?

**Forward connections (what should reference this note):**

Check newer notes that SHOULD link here but do not:
- Do they make arguments that rely on this claim?
- Would following this link provide useful context?

**Traversal Check (apply to all connections):**

Ask: **"If an agent follows this link during traversal, what decision or understanding does it enable?"**

Connections exist to serve navigation. Adding a link because content is "related" without operational value creates noise. Every backward or forward connection should answer:
- Does this help understand WHY something works?
- Does this help decide HOW to implement something?
- Does this surface a tension worth considering?

Reject connections that are merely "interesting" without utility.

**Articulation requirement:**

Every new connection must articulate WHY:
- "extends this by adding the temporal dimension"
- "provides evidence that supports this claim"
- "contradicts this -- needs resolution"

Never: "related" or "see also"

### Phase 5: Apply Changes

**Present the revisit proposal first, then apply after approval.**

**Revisit proposal format:**

```markdown
## Revisit Proposal: [[target note]]

**Last modified:** YYYY-MM-DD
**Current knowledge evaluated:** N newer notes, M backlinks

### Claim Assessment

[Does the claim hold? Need sharpening? Splitting? Revision?]

### Proposed Changes

**1. [change type]: [description]**

Current:
> [existing text]

Proposed:
> [new text]

Rationale: [why this change]

**2. [change type]: [description]**
...

### Connections to Add

- [[newer note A]] -- [relationship]: [specific reason]
- [[newer note B]] -- [relationship]: [specific reason]

### Connections to Verify (other notes should link here)

- [[note X]] might benefit from referencing this because...

### Not Changing

- [What was considered but rejected, and why]

---

Apply these changes? (yes/no/modify)
```

**When applying changes:**

1. Make changes atomically
2. Preserve existing valid content
3. Maintain prose flow -- new links should read naturally inline
4. Verify all link targets exist
5. Update description if claim changed

---

## The Five Revisit Actions

### 1. Add Connections

The simplest action. Newer notes exist that should be referenced.

**Inline connections (preferred):**
```markdown
# before
The constraint shifts from capture to curation.

# after
The constraint shifts from capture to curation, and since [[throughput matters more than accumulation]], the question becomes who does the selecting.
```

**Footer connections:**
```yaml
relevant_notes:
  - "[[newer note]] -- extends this by adding temporal dimension"
```

### 2. Rewrite Content

Understanding evolved. The prose should reflect current thinking, not historical thinking.

**When to rewrite:**
- Reasoning is clearer now
- Better examples exist
- Phrasing was awkward
- Important nuance was missing

**How to rewrite:**
- Preserve the core claim (unless challenging it)
- Improve the path to the conclusion
- Incorporate new connections as prose
- Maintain the note's voice

### 3. Sharpen the Claim

Vague claims cannot be built on. Sharpen means making the claim more specific and arguable.

**Sharpening patterns:**

| Vague | Sharp |
|-------|-------|
| "X is important" | "X matters because Y, which enables Z" |
| "consider doing X" | "X works when [condition] because [mechanism]" |
| "there are tradeoffs" | "[specific tradeoff]: gaining X costs Y" |

**When sharpening, also update:**
- Title (if claim changed)
- Description (must match new claim)
- Body (reasoning must support sharpened claim)

### 4. Split the Note

One note became multiple ideas over time. Splitting creates focused, composable pieces.

**Split indicators:**
- Connects to 5+ topics across different domains
- Makes multiple distinct claims
- You would want to link to part but not all
- Different sections could be referenced independently

**Split process:**

1. Identify the distinct claims
2. Create new notes for each claim
3. Each new note gets:
   - Focused title (the claim)
   - Own description
   - Relevant subset of content
   - Appropriate connections
4. Original note either:
   - Becomes a synthesis linking to the splits
   - Gets archived if splits fully replace it
   - Retains one claim and links to others

**When NOT to split:**
- Note is genuinely about one thing that touches many areas
- Connections are all variations of the same relationship
- Splitting would create notes too thin to stand alone

### 5. Challenge the Claim

New evidence contradicts the original. Do not silently "fix" -- acknowledge the evolution.

**Challenge patterns:**

```markdown
# if partially wrong
The original insight was [X]. However, [[newer evidence]] suggests [Y]. The refined claim is [Z].

# if tension exists
This argues [X]. But [[contradicting note]] argues [Y]. The tension remains unresolved -- possibly [X] applies in context A while [Y] applies in context B.

# if significantly wrong
This note originally claimed [X]. Based on [[evidence]], the claim is revised: [new claim].
```

**Always log challenges:** When a claim is challenged or revised, this is a significant event. Note it in the discoveries section of ops/tasks.md.

---

## Quality Gates

### Gate 1: Articulation Test

Every change must be articulable. "I am adding this because..." with a specific reason.

### Gate 2: Improvement Test

After changes, is the note better? More useful? More connected? More accurate?

If you cannot confidently say yes, do not make the change.

### Gate 3: Coherence Test

After changes, does the note still cohere as a single focused piece? Or did you accidentally make it broader?

### Gate 4: Network Test

Do the changes improve the network? More traversal paths? Better paths?

### Gate 5: When NOT to Change

- The note is accurate, well-connected, and recent -- leave it alone
- The "improvement" would just be cosmetic rewording -- do not churn
- The note is a historical record -- these evolve through status changes, not rewrites

---

## Output Format

```markdown
## Revisit Complete: [[target note]]

### Changes Applied

| Type | Description |
|------|-------------|
| connection | added [[note A]] inline, [[note B]] to footer |
| rewrite | clarified reasoning in paragraph 2 |
| sharpen | title unchanged, description updated |

### Claim Status

[unchanged | sharpened | split | challenged | superseded]

### Network Effect

- Outgoing links: 3 -> 5
- This note now bridges [[domain A]] and [[domain B]]

### Cascade Recommendations

- [[related note]] might benefit from revisiting (similar vintage)
- Index [[topic]] should be updated to reflect changes

### Observations

[Patterns noticed, insights for future]
```

---

## What Success Looks Like

Successful revisiting:
- Note reflects current understanding, not historical understanding
- Claim is sharp enough to disagree with
- Connections exist to relevant newer content
- Note participates actively in the network
- Someone reading it today gets the best version

The test: **if this note were written today with everything you know, would it be meaningfully different?** If yes and you did not change it, revisiting failed.

---

## Critical Constraints

**Never:**
- Silently change claims without acknowledging evolution
- Split notes into pieces too thin to stand alone
- Add connections without articulating why
- Rewrite voice/style (preserve the note's character)
- Make changes without approval in interactive mode
- Create wiki links to non-existent files

**Always:**
- Present proposals before editing
- Explain rationale for each change
- Preserve what is still valid
- Log significant claim changes
- Verify link targets exist

---

## The Network Lives Through Evolution

Notes written yesterday do not know about today. Notes written with old understanding do not reflect new understanding. Without revisiting, the vault becomes a graveyard of outdated thinking that happens to be organized.

Revisiting is how knowledge stays alive. Not just connecting, but questioning, sharpening, splitting, rewriting. Every note is a hypothesis. Every revisit is a test.

The network compounds through evolution, not just accumulation.
