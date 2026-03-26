---
name: connect
description: Find connections between notes and update indexes. Use after /process creates notes, when exploring connections, or when a topic needs synthesis. Triggers on "/connect", "/connect [note]", "find connections", "update indexes", "connect these notes".
user-invocable: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
context: fork
---

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse immediately:
- If target contains `[[note name]]` or note name: find connections for that note
- If target is empty: check for recently created notes or ask which note
- If target is "recent" or "new": find connections for all notes created today

**Execute these steps:**

1. Read the target note fully -- understand its claim and context
2. **Throughout discovery:** Capture which indexes you read, which queries you ran, which candidates you evaluated. This becomes the Discovery Trace -- proving methodology was followed, not reconstructed.
3. Run Phase 0 (index freshness check)
4. Use dual discovery in parallel:
   - Browse relevant index(es) for related notes
   - Run keyword search for conceptually related notes
5. Evaluate each candidate: does a genuine connection exist? Can you articulate WHY?
6. Add inline wiki-links where connections pass the articulation test
7. Update relevant index(es) with this note
8. Report what was connected and why

**START NOW.** Reference below explains methodology -- use to guide, not as output.

---

# Connect

Find connections, weave the knowledge graph, update indexes. This is the forward-connection phase of the processing pipeline.

## Philosophy

**The network IS the knowledge.**

Individual notes are less valuable than their relationships. A note with fifteen incoming links is an intersection of fifteen lines of thought. Connections create compound value as the vault grows.

This is not keyword matching. This is semantic judgment -- understanding what notes MEAN to determine how they relate. A note about "friction in systems" might deeply connect to "verification approaches" even though they share no words. You are building a traversable knowledge graph, not tagging documents.

**Quality over speed. Explicit over vague.**

Every connection must pass the articulation test: can you say WHY these notes connect? "Related" is not a relationship. "Extends X by adding Y" or "contradicts X because Z" is a relationship.

Bad connections pollute the graph. They create noise that makes real connections harder to find. When uncertain, do not connect.

## Invocation Patterns

### /connect (no argument)

Check for recent additions:
1. Look for notes modified in the last session
2. If none obvious, ask user what notes to connect

### /connect [note]

Focus on connecting a specific note:
1. Read the target note
2. Discover related content
3. Add connections and update indexes

### /connect [topic area]

Synthesize an area:
1. Read the relevant index
2. Identify notes that should connect
3. Weave connections, update synthesis

## Workflow

### Phase 0: Verify Index Freshness

Before searching, make sure you know what notes exist:

1. Count actual note files:
   ```bash
   find notes/ -name "*.md" -not -name "*.md~" | wc -l
   ```
2. Skim area indexes to know what is already catalogued

Run this check before proceeding. If indexes look stale, note it and continue.

### Phase 1: Understand What You Are Connecting

Before searching for connections, deeply understand the source material.

For each note you are connecting:
1. Read the full note, not just title and description
2. Identify the core claim and supporting reasoning
3. Note key concepts, mechanisms, implications
4. Ask: what questions does this answer? What questions does it raise?

**What you are looking for:**
- The central argument (what is being claimed?)
- The mechanism (why/how does this work?)
- The implications (what follows from this?)
- The scope (when does this apply? When not?)
- The tensions (what might contradict this?)

### Phase 2: Discovery (Find Candidates)

Use dual discovery: index exploration AND keyword search in parallel. These are complementary, not sequential.

**Capture discovery trace as you go.** Note which indexes you read, which queries you ran, which candidates you evaluated. This becomes the Discovery Trace section in output.

**Primary discovery (run in parallel):**

**Path 1: Index Exploration** -- curated navigation

If you know the topic (check the note's Topics footer), start with the index:

- Read the relevant index(es)
- Follow curated links in Core Ideas -- these are human/agent-curated connections
- Note what is already connected to similar concepts
- Check Tensions and Gaps for context

Indexes tell you what thinking exists and how it is organized. Someone already decided what matters for this topic.

**Path 2: Keyword Search** -- find what indexes might miss

Search for related notes by key terms and concepts:

```bash
grep -r "term" notes/ --include="*.md"
```

Use keyword search when:
- You know the exact words that should appear
- Searching for specific terminology or phrases
- Finding all uses of a named concept

**Secondary discovery (after primary):**

**Step 3: Description Scan**

Use ripgrep to scan note descriptions for edge cases:
- Does this extend the source note?
- Does this contradict or create tension?
- Does this provide evidence or examples?

Flag candidates with a reason (not just "related").

**Step 4: Link Following**

From promising candidates, follow their existing links:
- What do THEY connect to?
- Are there clusters of related notes?
- Do chains emerge that your source note should join?

This is graph traversal. You are exploring the neighborhood.

### Phase 3: Evaluate Connections

For each candidate connection, apply the articulation test.

**The Articulation Test:**

Complete this sentence:
> [[note A]] connects to [[note B]] because [specific reason]

If you cannot fill in [specific reason] with something substantive, the connection fails.

**Valid Relationship Types:**

| Relationship | Signal | Example |
|-------------|--------|---------|
| extends | adds dimension | "extends [[X]] by adding temporal aspect" |
| grounds | provides foundation | "this works because [[Y]] establishes..." |
| contradicts | creates tension | "conflicts with [[Z]] because..." |
| exemplifies | concrete instance | "demonstrates [[W]] in practice" |
| synthesizes | combines insights | "emerges from combining [[A]] and [[B]]" |
| enables | unlocks possibility | "makes [[C]] actionable by providing..." |

**Reject if:**
- The connection is "related" without specifics
- You found it through keyword matching alone with no semantic depth
- Linking would confuse more than clarify
- The relationship is too obvious to be useful

**Agent Traversal Check:**

Ask: **"If an agent follows this link, what do they gain?"**

| Agent Benefit | Keep Link |
|---------------|-----------|
| Provides reasoning foundation (why something works) | YES |
| Offers implementation pattern (how to do it) | YES |
| Surfaces tension to consider (trade-off awareness) | YES |
| Gives concrete example (grounds abstraction) | YES |
| Just "related topic" with no decision value | NO |

The vault is built for agent traversal. Every connection should help an agent DECIDE or UNDERSTAND something. Connections that exist only because they feel "interesting" without operational value are noise.

**Synthesis Opportunity Detection:**

While evaluating connections, watch for synthesis opportunities -- two or more notes that together imply a higher-order claim not yet captured.

Signs of a synthesis opportunity:
- Two notes make complementary arguments that combine into something neither says alone
- A pattern appears across three or more notes that has not been named
- A tension between two notes suggests a resolution claim

When you detect a synthesis opportunity:
1. Note it in the output report
2. Do NOT create the synthesis note during connect -- flag it for future work
3. Describe what the synthesis would argue and which notes contribute

**Deduplication Detection:**

While evaluating candidates, watch for notes that make the same claim. Two notes that argue the same thing with different words are redundant, not connected.

Signs of duplication:
- Two notes have near-identical core arguments despite different titles
- One note is a strict subset of another (everything it says, the other says too)
- Two notes reach the same conclusion via different reasoning (may be candidates for merge, keeping both reasoning paths)

When you detect duplication:
1. Flag it in the output report under "Flagged for Attention"
2. Do NOT auto-merge -- flag for human decision
3. Note which note is more complete or better connected
4. Suggest: merge into the stronger note, redirect links from the weaker one

### Phase 4: Add Inline Connections

Connections live in the prose, not just footers.

**Inline Links as Prose:**

The wiki link IS the argument. The title works as prose when linked.

Good patterns:
```markdown
Since [[other note]], the question becomes how to structure that memory for retrieval.

The insight that [[throughput matters more than accumulation]] suggests curation, not creation, is the real work.

This works because [[good systems learn from friction]] -- each iteration improves the next.
```

Bad patterns:
```markdown
This relates to [[other note]].

See also [[throughput matters more than accumulation]].

As discussed in [[good systems learn from friction]], systems improve.
```

If you catch yourself writing "this relates to" or "see also", STOP. Restructure so the claim does the work.

**Where to add links:**

1. Inline in the body where the connection naturally fits the argument
2. In the relevant_notes YAML field with context phrase
3. BOTH when the connection is strong enough

**Relevant Notes Format:**

```yaml
relevant_notes:
  - "[[note title]] -- extends this by adding the temporal dimension"
  - "[[another note]] -- provides the mechanism this claim depends on"
```

Context phrases use standard relationship vocabulary: extends, grounds, contradicts, exemplifies, synthesizes, enables.

**Bidirectional Consideration:**

When adding [[A]] to [[B]], ask: should [[B]] also link to [[A]]?

Not always. Relationships are not always symmetric:
- "extends" often is not bidirectional
- "exemplifies" usually goes one direction
- "contradicts" is often bidirectional
- "synthesizes" might reference both sources

Add the reverse link only if following that path would be useful for agent traversal.

### Phase 5: Update Indexes

Indexes are synthesis hubs, not just lists.

**When to update an index:**

- New note belongs in Core Ideas
- New tension discovered
- Gap has been filled
- Synthesis insight emerged
- Navigation path worth documenting

**Index Size Check:**

After updating Core Ideas, count the links:

```bash
grep -c '^\- \[\[' "notes/[index-name].md"
```

If approaching 20 links: note in output "index approaching split threshold (N links)"
If exceeding: warn "index exceeds recommended size -- consider splitting"

Splitting is a human decision (architectural judgment required), but /connect should surface the signal.

**Index Structure:**

```markdown
# [Topic Name]

[Opening synthesis: Claims about the topic. Not "this index collects notes" but "the core insight is Y because Z." This IS thinking, not meta-description.]

## Core Ideas

- [[claim note]] -- what it contributes to understanding
- [[another claim]] -- how it fits or challenges existing ideas

## Tensions

- [[claim A]] and [[claim B]] conflict because... [genuine unresolved tension]

## Gaps

- nothing about X aspect yet
- need concrete examples of Y
- missing: comparison with Z approach

---

Agent Notes:
- YYYY-MM-DD: [what was explored]. [the insight or dead end].
```

**Updating Core Ideas:**

Add new notes with context phrase explaining contribution:
```markdown
- [[new note]] -- extends the quality argument by showing how friction teaches you what to check
```

Order matters. Place notes where they fit the logical flow, not alphabetically.

**Updating Tensions:**

If the new note creates or resolves tension:
```markdown
## Tensions

- [[composability]] demands small notes, but [[context limits]] means traversal has overhead. [[new note]] suggests the tradeoff depends on expected traversal depth.
```

Document genuine conflicts. Tensions are valuable, not bugs.

**Updating Gaps:**

Remove gaps that are now filled. Add new gaps discovered during connection finding.

### Phase 6: Add Agent Notes

Agent notes are breadcrumbs for future navigation.

**Add agent notes when:**
- Non-obvious navigation path discovered
- Dead end worth documenting
- Productive note combination found
- Insight about topic cluster emerged

**Format:**
```markdown
Agent Notes:
- YYYY-MM-DD: [what was explored]. [the insight or finding].
```

**Good agent notes:**
```markdown
- 2026-02-15: tried connecting via "learning" -- too generic. better path: friction -> verification -> quality. the mechanism chain is tighter.
- 2026-02-15: [[claim A]] and [[claim B]] form a tight pair. A sets the standard, B teaches the method.
```

**Bad agent notes:**
```markdown
- 2026-02-15: read the index and added some links.
- 2026-02-15: connected [[note A]] to [[note B]].
```

The test: would this help a future agent navigate more effectively?

## Quality Gates

### Gate 1: Articulation Test

For every connection added, can you complete:
> [[A]] connects to [[B]] because [specific reason]

If any connection fails this test, remove it.

### Gate 2: Prose Test

For every inline link, read the sentence aloud. Does it flow naturally? Would you say this to a friend explaining the idea?

Bad: "this is related to [[note]]"
Good: "since [[note]], the implication is..."

### Gate 3: Bidirectional Check

For every A -> B link, explicitly decide: should B -> A exist?
Document your reasoning if the relationship is asymmetric.

### Gate 4: Index Coherence

After updating an index, read the opening synthesis. Does it still hold? Do new notes extend or challenge it?

If the synthesis is now wrong or incomplete, update it.

### Gate 5: Link Verification

Verify every wiki link target exists. Never create links to non-existent files.

```bash
ls notes/"target name.md" 2>/dev/null
```

## Handling Edge Cases

### No Connections Found

Sometimes a note genuinely does not connect yet. That is fine.

1. Ensure it is linked to at least one index via Topics footer
2. Note in index Gaps that this area needs development
3. Do not force connections that are not there

### Too Many Connections (Split Detection)

If a note connects to 5+ notes across different domains, it might be too broad.

**Split detection criteria:**

1. **Domain spread:** Connections span 3+ distinct indexes/topic areas
2. **Multiple claims:** The note makes more than one assertion that could stand alone
3. **Linking drag:** You would want to link to part of the note but not all of it

**How to evaluate:**

Ask: "If I link to this note from context X, does irrelevant content Y come along?"

If yes, the note bundles multiple ideas that should be separate.

**Split detection output:**

```markdown
### Split Candidate: [[broad note]]

**Indicators:**
- Connects to 7 notes across 3 domains
- Makes distinct claims about: (1) capture workflows, (2) synthesis patterns, (3) tool selection
- Linking from [[note A]] would drag in unrelated content about tool selection

**Proposed split:**
- [[capture workflows matter less than synthesis]] -- the first claim
- [[tool selection follows from workflow needs]] -- the third claim
- Keep original note focused on synthesis patterns

**Action:** Flag for human decision, do not auto-split
```

**When NOT to split:**
- Note is genuinely about one thing that touches many areas
- Connections are all variations of the same relationship
- Splitting would create notes too thin to stand alone

### Conflicting Notes

When new content contradicts existing notes:

1. Document the tension in both notes
2. Add to index Tensions section
3. Do not auto-resolve -- flag for judgment

### Orphan Discovery

If you find notes with no connections:

1. Flag them in your output
2. Attempt to connect them
3. If genuinely orphaned, note in relevant index Gaps

## Output Format

After connecting, report:

```markdown
## Connection Complete

### Discovery Trace

**Why this matters:** Shows methodology was followed. Trace enables verification.

**Index exploration:**
- Read [[index-name]] -- found candidates: [[note A]], [[note B]], [[note C]]
- Followed link from [[note A]] to [[note D]]

**Keyword search:**
- grep "specific term" -- found [[note H]] (already in index candidates)

### Connections Added

**[[source note]]**
- -> [[target]] -- [relationship type]: [why]
- <- [[incoming]] -- [relationship type]: [why]
- inline: added link to [[note]] in paragraph about X

### Index Updates

**[[index-name]]**
- Added [[note]] to Core Ideas -- [contribution]
- Updated Tensions: [[A]] vs [[B]] now includes [[C]]
- Removed from Gaps: [what was filled]
- Agent note: [what was learned]

### Synthesis Opportunities

[Notes that could be combined into higher-order insights, with proposed claim]

### Flagged for Attention

- [[orphan note]] -- could not find connections
- [[broad note]] -- might benefit from splitting
- Tension between [[X]] and [[Y]] needs resolution
- [[note A]] and [[note B]] -- possible duplicates (same claim about X, merge candidate)
```

## What Success Looks Like

Successful connection finding:
- Every connection passes the articulation test
- Inline links read as natural prose
- Indexes gain synthesis, not just entries
- Agent notes reveal non-obvious paths
- The knowledge graph becomes more traversable
- Future agents will navigate more effectively

The test: if someone follows the links you added, do they find genuinely useful context? Does the path illuminate understanding?

## Critical Constraints

**Never:**
- Create wiki links to non-existent files
- Add "related" connections without specific reasoning
- Force connections that are not there
- Auto-generate without semantic judgment
- Skip the articulation test

**Always:**
- Verify link targets exist
- Explain WHY connections exist
- Consider bidirectionality
- Update relevant indexes
- Add agent notes when navigation insights emerge
- Capture discovery trace as you work

## The Network Grows Through Judgment

This skill is about building a knowledge graph that compounds in value. Every connection you add is a traversal path that future thinking can follow. Every connection you do not add keeps the graph clean.

Quality beats quantity. One genuine connection is worth more than ten vague ones.

The graph is not just storage. It is an external thinking structure. Build it with care.
