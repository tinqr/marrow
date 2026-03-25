---
name: marrow:extract
description: Extract structured notes from source material. Comprehensive extraction is the default -- every insight that serves the vault gets extracted. For relevant sources, skip rate must be below 10%. Zero extraction from a relevant source is a BUG. Triggers on "/extract", "/extract [file]", "extract insights", "mine this".
user-invocable: true
context: fork
model: sonnet
allowed-tools: Read, Write, Grep, Glob, Bash
---

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse immediately:
- If target contains a file path: extract insights from that file
- If target contains a batch ID: look up the extract task in `ops/queue/` and process its source
- If target is empty: scan `inbox/` for unprocessed items, pick one
- If target is "inbox" or "all": process all inbox items sequentially

**Execute these steps:**

1. Read the source file fully -- understand what it contains
2. **Source size check:** If source exceeds 2500 lines, STOP. Plan chunks of 350-1200 lines. Process each chunk with fresh context. See "Large Source Handling" section below.
3. Hunt for insights (see extraction categories below)
4. For each candidate: run keyword grep duplicate checks against `notes/`
5. If duplicate found: READ the existing note fully, evaluate for enrichment (see Duplicate Detection)
6. Categorize FIRST, then route (see Workflow step 3)
7. Classify as OPEN (needs more investigation) or CLOSED (standalone, ready)
8. Run calibration check against expected yields (see Quality Gates)
9. Output extraction report with titles, classifications, extraction rationale
10. Wait for user approval before creating files

**START NOW.** Reference below explains methodology -- use to guide, not as output.

---

## The Mission

You are the extraction engine. Raw source material enters. Structured, atomic notes exit. Everything between is your judgment -- and that judgment must err toward extraction, not rejection.

### The Core Distinction

| Concept | What It Means | Example |
|---------|---------------|---------|
| **Having knowledge** | The vault contains information | "We store notes in folders" |
| **Articulated reasoning** | The vault explains WHY something works as a traversable note | "folder structure mirrors cognitive chunking because..." |

**Having knowledge is not the same as articulating it.** Even if information is embedded in the system, the vault may lack the externalized reasoning explaining WHY it works. That reasoning is what you extract.

### The Comprehensive Extraction Principle

**For relevant sources, COMPREHENSIVE EXTRACTION is the default.** This means:

1. **Extract ALL core notes** -- direct assertions about the domain that can stand alone as atomic propositions.
2. **Extract ALL evidence and validations** -- if source confirms an approach, that confirmation IS the note. Evidence is extractable even when the conclusion is already known, because the reasoning path matters.
3. **Extract ALL patterns and methods** -- techniques, workflows, practices. Named patterns are referenceable. Unnamed intuitions are not.
4. **Extract ALL tensions** -- contradictions, trade-offs, conflicts. These are wisdom, not problems.
5. **Extract ALL enrichments** -- if source adds detail to existing notes, create enrichment tasks. Near-duplicates almost always add value.

**"We already know this" means we NEED the articulation, not that we should skip it.**

### The Extraction Question (ask for EVERY candidate)

**"Would a future session benefit from this reasoning being a retrievable note?"**

If YES -> extract to appropriate category
If NO -> verify it is truly off-topic before skipping

### INVALID Skip Reasons (these are BUGS)

- "validates existing approach" -- validations ARE evidence. Extract them.
- "already captured in system config" -- config is implementation, not articulation. The WHY needs a note.
- "we already do this" -- DOING is not EXPLAINING. The explanation needs externalization.
- "obvious" -- obvious to whom? Future sessions need explicit reasoning.
- "near-duplicate" -- near-duplicates almost always add detail. Create enrichment task.
- "not a claim" -- is it an implementation idea? tension? validation? Those ARE extractable.

### VALID Skip Reasons (rare)

- Completely off-topic (unrelated to the vault's domains)
- Too vague to act on (applies to everything, disagrees with nothing)
- Pure summary with zero extractable insight
- LITERALLY identical text already exists (not "same topic" -- IDENTICAL)

**For relevant sources: skip rate < 10%. Zero extraction = BUG.**

---

## Extraction Categories

| Category | What to Find | Output Type | Gate Required? |
|----------|--------------|-------------|----------------|
| Core notes | Direct assertions about the domain | note | NO |
| Patterns | Recurring structures across sources | note | NO |
| Comparisons | How different approaches compare, trade-offs | note | NO |
| Tensions | Contradictions, conflicts, unresolved trade-offs | tension note | NO |
| Anti-patterns | What breaks, what to avoid, failure modes | problem note | NO |
| Enrichments | Content that adds detail to existing notes | enrichment task | NO |
| Open questions | Unresolved questions worth tracking | note (open) | NO |
| Implementation ideas | Techniques, workflows, features to build | methodology note | NO |
| Validations | Evidence confirming an approach works | note | NO |
| Off-topic general content | Insight unrelated to vault domains | apply selectivity gate | YES |

**IMPORTANT:** Categories 1-9 bypass the selectivity gate. They extract directly to the appropriate output type. The selectivity gate exists ONLY for filtering off-topic content from general sources.

### Category Detection Signals

Hunt for these signals in every source:

**Core signals:**
- Direct assertions: "the key insight is...", "this means that...", "the pattern is..."
- Evidence: "research shows...", "data indicates...", "studies confirm..."
- Named methods: any named system, technique, or framework

**Comparison signals:**
- "X vs Y", "trade-off between...", "prefer X when...", "unlike Y, this..."
- "choose X when...", "depends on whether..."

**Tension signals:**
- "contrary to...", "however...", "the problem with...", "fails when..."
- "on the other hand...", "but this conflicts with..."

**Anti-pattern signals:**
- "systems fail when...", "the anti-pattern is...", "avoid this because..."
- Warnings, cautionary examples, failure postmortems

**Enrichment signals:**
- Content covering ground similar to an existing note
- New examples, evidence, or framing for an established claim
- Deeper explanation of something already captured shallowly

**Implementation signals:**
- "we could build...", "would enable...", "a tool that...", "pattern for..."
- Actionable techniques, concrete workflows

**Validation signals:**
- "this supports...", "evidence shows...", "validates...", "confirms..."
- Research that grounds existing practice in theory

**Implicit signals (the best insights often hide in):**
- Problems that imply solutions
- Constraints that reveal what works
- Failures that suggest approaches
- Asides that contain principles
- Tangents that reveal mental models

---

## The Selectivity Gate (for OFF-TOPIC content only)

**CRITICAL:** This gate exists to filter OUT content that does not serve the vault's domains. It applies ONLY to standard claims from GENERAL (off-topic) sources.

**Do NOT use the gate to reject:**
- Implementation ideas ("not a claim" is WRONG -- it is roadmap)
- Tensions ("not a claim" is WRONG -- it is wisdom)
- Enrichments ("duplicate" is WRONG -- it adds detail)
- Validations ("already known" is WRONG -- it is evidence)
- Open questions ("not testable" is WRONG -- it is direction)

For STANDARD claims from general sources, verify all four criteria pass:

### 1. Standalone

The claim is understandable without source context. Someone reading this note cold can grasp what it argues without needing to know where it came from.

Fail: "the author's third point about methodology"
Pass: "explicit structure beats implicit convention"

### 2. Composable

This note would be linked FROM elsewhere. Notes function as APIs. If you cannot imagine writing `since [[this claim]]...` in another note, it is not composable.

Fail: a summary of someone's argument
Pass: a claim you could invoke while building your own argument

### 3. Novel

Not already captured in the vault. Duplicate check AND existing notes scan both clear.

Fail: semantically equivalent to an existing note
Pass: genuinely new angle not yet articulated

### 4. Connected

Relates to existing thinking in the vault. Isolated insights that do not connect to anything are orphans. They rot.

Fail: interesting observation about unrelated domain
Pass: extends, contradicts, or deepens existing notes

**If ANY criterion fails for off-topic content: do not extract.**

---

## Workflow

### 1. Orient

Before reading the source, understand what already exists:

```bash
# Get descriptions from existing notes (including subdirectories)
for f in notes/*.md notes/**/*.md; do
  [[ -f "$f" ]] && echo "=== $(basename "$f" .md) ===" && rg "^description:" "$f" -A 0
done
```

Scan descriptions to understand current notes. This prevents duplicate extraction and helps identify connection points and enrichment opportunities.

### 2. Read Source Fully

Read the ENTIRE source. Understand what it contains, what it argues, what domain it serves.

**Planning the extraction:**
- How many notes do you expect from this source?
- What categories will be represented?
- Is this relevant (comprehensive extraction) or general (gate applies)?

**Explicit signal phrases to hunt:**
- "the key insight is..."
- "this means that..."
- "the pattern is..."
- "contrary to..."
- "the implication..."
- "what matters here is..."
- "the real issue is..."
- "this suggests..."

**Implicit signals (the best insights often hide in):**
- Problems that imply solutions
- Constraints that reveal what works
- Failures that suggest approaches
- Asides that contain principles
- Tangents that reveal mental models

**What you are hunting:**
- Assertions that could be argued for or against
- Patterns that apply beyond this specific source
- Insights that change how you think about something
- Claims that would be useful to invoke elsewhere

### 3. Categorize FIRST, Then Route (MANDATORY)

**STOP. Before ANY filtering, determine the category of each candidate.**

This is the critical step that prevents over-rejection. Categorize FIRST, then route to the appropriate extraction path.

| Category | How to Identify | Route To |
|----------|-----------------|----------|
| Core note | Direct assertion about a domain | -> note (SKIP selectivity gate) |
| Implementation idea | Describes a feature, tool, system, or workflow to build | -> methodology note (SKIP selectivity gate) |
| Tension/challenge | Describes a conflict, risk, or trade-off | -> tension note (SKIP selectivity gate) |
| Validation | Evidence confirming an approach works | -> note (SKIP selectivity gate) |
| Near-duplicate | Keyword search finds related vault note | -> evaluate for enrichment task |
| Off-topic claim | General insight not about vault domains | -> apply selectivity gate |

**CRITICAL:** Implementation ideas, tensions, validations, and domain notes do NOT need to pass the 4-criterion selectivity gate. The gate is for off-topic filtering ONLY.

**Why this matters:** The selectivity gate was designed for filtering general insights. But implementation ideas ("build a trails feature"), tensions ("optimization vs readability trade-off"), and validations ("research confirms our approach") are DIFFERENT output types that serve different purposes. Applying the selectivity gate to them is a category error.

### 4. Duplicate Detection

For each candidate, run duplicate detection via keyword grep:

```bash
grep -rl "{key terms}" notes/ 2>/dev/null | head -5
```

**MANDATORY protocol when search finds overlap:**

1. **READ the existing note fully** (not just title/description)
2. Ask: "What does source ADD that existing note LACKS?"
   - New examples -> ENRICHMENT
   - Deeper framing -> ENRICHMENT
   - Citations/evidence -> ENRICHMENT
   - Different angle -> ENRICHMENT
   - Concrete implementation -> ENRICHMENT
   - Literally identical -> skip (RARE)
3. If source adds ANYTHING: **CREATE ENRICHMENT TASK**
4. Only skip if source adds literally NOTHING new (verify this claim)

**The Enrichment Judgment (DEFAULT TO ENRICHMENT):**

| Situation | Action |
|-----------|--------|
| Exact text already exists | SKIP (truly identical -- RARE) |
| Same claim, different words, source adds nothing | SKIP (verify by re-reading existing note) |
| Same claim, source has MORE detail/examples/framing | -> ENRICHMENT TASK (update existing note) |
| Same topic, DIFFERENT claim | -> EXTRACT as new note, flag for cross-linking |
| Related mechanism, different scope | -> EXTRACT as new note, flag for cross-linking |

**DEFAULT TO ENRICHMENT.** If source mentions the same topic, it almost certainly adds something. Truly identical content is RARE.

**Near-duplicates are opportunities, not rejections.** Creating enrichment tasks is CORRECT behavior. If you are skipping near-duplicates without enrichment tasks, you are probably wrong.

### 5. Classify Each Extraction

Every extracted candidate gets classified:

- **CLOSED** -- standalone claim, design decision, ready for processing as-is
- **OPEN** -- needs more investigation, testable hypothesis, requires evidence

Classification affects downstream handling but does NOT affect whether to extract. Both open and closed candidates get extracted.

### 6. Present Findings

Report what you found by category. **Include counts:**

```
Extraction scan complete.

SUMMARY:
- notes: N
- implementation ideas: N
- tensions: N
- enrichment tasks: N
- validations: N
- open questions: N
- skipped: N
- TOTAL OUTPUTS: N

---

NOTES:
1. [note as sentence] -- connects to [[existing note]]
2. [note as sentence] -- extends [[existing note]]
...

IMPLEMENTATION IDEAS:
1. [feature/pattern] -- what it enables, why it matters
...

TENSIONS:
1. [X vs Y] -- the conflict, why it matters
...

ENRICHMENT TASKS:
1. [[existing note]] -- source adds [what is missing]
...

SKIPPED:
- [description] -- why nothing extractable
```

**Wait for user approval before creating files.** Never auto-extract.

### 7. Extract (With User Approval)

For each approved note:

**a. Craft the title**

The title IS the claim. Express the concept in exactly the words that capture it.

Test: "this note argues that [title]"
- Must make grammatical sense
- Must be something you could agree or disagree with
- Composability over brevity -- a full sentence is fine if the concept requires it
- Lowercase with spaces
- No punctuation that breaks filesystems: . * ? + [ ] ( ) { } | \ ^

Good: "explicit structure beats implicit convention for agent navigation"
Good: "small differences compound through repeated selection"
Bad: "context management strategies" (topic label, not a claim)

**b. Write the note**

```markdown
---
description: [~150 chars elaborating the claim, adds info beyond title]
type: [note | methodology | problem | learning | tension]
area: [area from vault domains]
created: YYYY-MM-DD
topics: []
---

# [prose-as-title proposition]

[Body: 150-400 words showing reasoning]

Use connective words: because, but, therefore, which means, however.
Acknowledge uncertainty where appropriate.
Consider the strongest counterargument.
Show the path to the conclusion, not just the conclusion.

---

Source: [[source filename]]

Relevant Notes:
- [[related note]] -- [why it relates: extends, contradicts, builds on]

Topics:
- [[relevant index]]
```

**c. Verify before writing**

- Title passes the claim test ("this note argues that [title]")
- Description adds information beyond the title (not a restatement)
- Body shows reasoning, not just assertion
- At least one relevant note connection identified
- At least one index link
- Source attribution present

**d. Create the file**

Write to: `notes/[title].md`

---

## Large Source Handling

**For sources exceeding 2500 lines: chunk processing is MANDATORY.**

Context degrades as it fills. A single-pass extraction of a 3000-line source will miss insights in the later sections because attention has degraded by the time you reach them. Chunking ensures each section gets fresh attention.

### Chunking Strategy

| Source Size | Chunk Count | Chunk Size | Rationale |
|-------------|------------|------------|-----------|
| 2500-4000 lines | 3-4 chunks | 700-1200 lines | Standard chunking |
| 4000-6000 lines | 4-5 chunks | 800-1200 lines | Balanced attention |
| 6000+ lines | 5+ chunks | 1000-1500 lines | Prevent context overflow |

**Chunk boundaries:** Split at natural section breaks (headings, topic transitions). Never split mid-paragraph or mid-argument. A chunk should be a coherent unit of content.

### Cross-Chunk Coordination

When processing in chunks:
1. Keep a running list of extracted notes across chunks
2. Later chunks check against earlier chunks' extractions (not just existing vault notes)
3. Cross-chunk connections get flagged for /connect
4. The final extraction report covers ALL chunks combined

**The anti-pattern:** Processing chunk 3 and extracting a duplicate of something already extracted in chunk 1 because you lost track. Maintain the running list.

---

## Enrichment Detection

When source content adds value to an EXISTING note rather than creating a new one, create an enrichment task instead.

### When to Create Enrichment Tasks

| Signal | Action |
|--------|--------|
| Source has better examples for an existing note | Enrichment: add examples |
| Source has deeper framing or context | Enrichment: strengthen reasoning |
| Source has citations or evidence | Enrichment: add evidence base |
| Source has a different angle on the same claim | Enrichment: add perspective |
| Source has concrete implementation details | Enrichment: add actionable specifics |

### Enrichment Task Format

Each enrichment task specifies:
- **Target:** Which existing note to enrich (by title)
- **What to add:** Specific content from the source
- **Why:** What the existing note lacks that this adds
- **Source lines:** Where in the source the enrichment content is found

**The enrichment default:** When in doubt between "new note" and "enrichment to existing note", lean toward enrichment. The existing note already has connections and integration. Adding to it compounds existing value.

---

## Quality Gates

### Calibration Check (REQUIRED Before Finishing)

**STOP before outputting results.** Count your outputs by category:

```
notes extracted: ?
implementation ideas: ?
tensions: ?
enrichment tasks: ?
validations: ?
open questions: ?
truly skipped: ?
TOTAL: ?
```

**Expected yields by source size:**

| Source Size | Expected Outputs | Skip Rate |
|-------------|------------------|-----------|
| ~100 lines | 5-10 outputs | varies by relevance |
| ~350 lines | 15-30 outputs | < 10% for relevant sources |
| ~500+ lines | 25-50+ outputs | < 10% for relevant sources |
| ~1000+ lines | 40-70 outputs | < 5% for relevant sources |

**Zero extraction from a relevant source is a BUG.**

**If your total outputs are significantly below these ranges, you are over-filtering.**

### Red Flags: Extraction Too Tight (THE COMMON FAILURE MODE)

If you catch yourself doing ANY of these, STOP IMMEDIATELY and recalibrate:

#### The Cardinal Sins (NEVER do these)

1. **"validates existing approach" as skip reason**
   - WRONG: "This just confirms what we do, skip"
   - RIGHT: Validations ARE valuable. Extract as note with evidence framing.
   - WHY: Future sessions need to see WHY an approach is validated, not just that it works.

2. **"already captured in config" as skip reason**
   - WRONG: "We already have this in our config, skip"
   - RIGHT: Extract the reasoning that explains WHY the config works
   - WHY: Config is implementation. Notes explain WHY it works.

3. **"we already do this" as skip reason**
   - WRONG: "We use wiki links, this is obvious, skip"
   - RIGHT: Extract the reasoning that explains WHY it works
   - WHY: DOING is not EXPLAINING. The reasoning needs externalization.

4. **"obvious" or "well known" as skip reason**
   - WRONG: "Everyone knows structure helps, skip"
   - RIGHT: Extract the specific, named, referenceable claim
   - WHY: Named patterns are referenceable. Unnamed intuitions are not.

5. **Treating near-duplicates as skips instead of enrichments**
   - WRONG: "Similar to existing note, skip"
   - RIGHT: Create enrichment task to add source's details to existing note
   - WHY: Near-duplicates almost always add framing, examples, or evidence.

#### Other Red Flags

- Rejecting implementation ideas as "not claims" (they ARE extractable as methodology notes)
- Rejecting tensions as "not claims" (they become tension notes)
- Zero extraction from a relevant source (the source IS about your domain)
- Rejecting open questions as "not testable" (directions guide future work)
- Applying the 4-criterion gate to non-off-topic categories (gate is for off-topic filtering)
- Skip rate > 10% on relevant sources (most domain content should extract to SOME category)

#### The Test

Before skipping ANYTHING, ask: **"Would a future session benefit from this being a retrievable note?"**

If YES -> extract (even if "we already know this")
If NO -> verify it is truly off-topic or literally identical to existing content

### Red Flags: Extraction Too Loose

- Extracting vague observations with no actionable content
- Creating notes without articulating vault connection
- Titles that are topics, not claims ("knowledge management" instead of "knowledge management fails without active maintenance")
- Body text that is pure summary without reasoning

### Mandatory Review If Low Yield

Go back through candidates you marked as "duplicate" or "rejected":

1. **Did any "duplicates" have source content that enriches existing notes?**
   - YES -> convert to enrichment task (DEFAULT TO ENRICHMENT)
   - NO -> verify by re-reading existing note FULLY

2. **Did any "rejected" items describe features to build?**
   - YES -> extract as implementation idea
   - NO -> verify it is truly unactionable

3. **Did any "rejected" items describe conflicts or challenges?**
   - YES -> extract as tension note
   - NO -> verify it is truly vague

4. **Did any "rejected" items provide evidence for existing approaches?**
   - YES -> extract as validation note
   - NO -> verify it does not support existing methodology

5. **Did any "rejected" items suggest questions worth investigating?**
   - YES -> extract as open question note
   - NO -> verify it is not worth tracking

**Do not proceed until low yield is investigated.**

---

## Note Design Reference

### Titles

Titles are claims that work as prose when linked:

```
since [[explicit structure beats implicit convention]], the question becomes...
the insight is that [[small differences compound through repeated selection]]
because [[capture speed beats filing precision]], we separate the two...
```

The claim test: "this note argues that [title]"

| Example | Passes? |
|---------|---------|
| quality requires active judgment | yes: "argues that quality requires active judgment" |
| knowledge management | no: "argues that knowledge management" (incomplete) |
| small differences compound through selection | yes: "argues that small differences compound through selection" |
| tools for thought | no: "argues that tools for thought" (incomplete) |

### Description

One field. ~150 characters. Must add NEW information beyond the title -- scope, mechanism, or implication.

Bad (restates title): "quality is important in knowledge work"
Good (adds mechanism + implication): "when creation becomes trivial, maintaining signal-to-noise becomes the primary challenge -- selection IS the work"

The description is progressive disclosure: title says WHAT the claim is, description says WHY it matters or HOW it works. If the description just rephrases the title, it wastes context and provides no filter value.

### Body

Show reasoning. Use connective words. Acknowledge uncertainty.

Bad:
> Quality matters. When creation is easy, curation becomes the work.

Good:
> The easy part is capture. We bookmark things, save screenshots, clip articles we never open again. The hard part is doing something with it all. Since [[structure without processing provides no value]], the question becomes: who does the selecting?

Characteristics:
- Conversational flow (because, but, therefore)
- Shows path to conclusion
- Acknowledges where thinking might be wrong
- Considers strongest objection
- Invokes other notes as prose

### Section Headings

Headings serve navigation, not decoration. Use when agents would benefit from grepping the outline.

**Always use headings for:**
- Tension notes (sections: Quick Test, When Each Pole Wins, Dissolution Attempts, Practical Applications)
- Index notes (sections: Synthesis, Core Ideas, Tensions, Explorations Needed)
- Implementation patterns with discrete steps
- Notes exploring multiple facets of a concept (>1000 words AND distinct sub-topics)

**Use prose without headings for:**
- Single flowing arguments under ~1000 words
- Notes where transitions like "since [[X]]..." already carry structure

### Footer

```markdown
---

Source: [[source filename]]

Relevant Notes:
- [[related note]] -- extends this by adding the temporal dimension

Topics:
- [[relevant index]]
```

The relationship context explains WHY to follow the link:
- Bad: "-- related"
- Good: "-- contradicts by arguing for explicit structure"
- Good: "-- provides the foundation this challenges"

---

## The Composability Test

Before finalizing ANY note, verify:

**1. Standalone Sense**
If you link to this note from another context, will it make sense without reading three other notes first?

**2. Specificity**
Could someone disagree with this claim? Vague notes cannot be built on.

**3. Clean Linking**
Would linking to this note drag unrelated content along? If yes, the note covers too much.

**When to skip:** content does not pass all four selectivity criteria (off-topic content only)
**When to split:** multiple distinct claims in one extraction
**When to sharpen:** claim too vague, title is label not statement

---

## Research Provenance

When the source file contains provenance metadata (source_type, research_prompt, generated), preserve the chain:

- Each created note's Source footer links to the source file
- The source file's YAML contains the research prompt
- The chain: research query -> inbox file -> /extract -> notes/

If source has `source_type` in frontmatter, this is research-generated content -- handle with extra care for attribution.

---

## Example: What Good Extraction Looks Like

### Example 1: 300-line relevant source

**Source:** 300-line research document directly relevant to the vault's domains

**Scan found:** ~45 items across sections

**Extraction results:**
- 12 core notes
- 6 implementation ideas -> methodology notes
- 4 tensions -> tension notes
- 5 enrichment tasks -> update existing notes
- 3 validations -> notes
- 3 skipped (too vague to act on)

**Total: 30 outputs, 3 skipped (~9% skip rate)**

### Example 2: 100-line general article

**Source:** 100-line article with partial relevance to the vault's domains

**Extraction results:**
- 4 core notes
- 1 enrichment task
- 2 skipped (off-topic)
- 3 skipped (too vague)

**Total: 5 outputs, 5 skipped (50% skip rate -- acceptable for general source)**

### Contrast: WRONG Behavior

- 45 candidates -> 0 outputs (everything "rejected as duplicate or not a claim")
- Treating implementation ideas as "not claims" and skipping
- Treating tensions as "not claims" and skipping
- Treating near-duplicates as skips instead of enrichment tasks
- Skip rate > 10% on a relevant source

---

## Task File Mode (when called from /process)

When invoked as part of the /process pipeline (a task file exists in `ops/queue/`), also:

1. Update the extract task's "Execution Notes" and "Outputs" sections
2. For EACH note, create a task file in `ops/queue/` named `{source}-NNN.md`
3. For EACH enrichment, create a task file continuing the numbering
4. Update `ops/queue/queue.json`: mark extract task done, add per-note entries

**Task file structure for notes:**

```markdown
---
claim: "[the note as a sentence]"
classification: closed | open
source_task: [source-basename]
semantic_neighbor: "[related note title]" | null
---

# Note NNN: [note title]

Source: [[source filename]]

## Extract Notes
Extracted from [source_task]. This is a [CLOSED/OPEN] note.
Rationale: [why this was extracted, what it contributes]
Semantic neighbor: [if found, explain why DISTINCT not DUPLICATE]

---

## Connect
(to be filled by /connect phase)

## Check
(to be filled by /check phase)
```

**Task file structure for enrichments:**

```markdown
---
type: enrichment
target_note: "[[existing note title]]"
source_task: [source-basename]
addition: "what to add from source"
source_lines: "NNN-NNN"
---

# Enrichment NNN: [[existing note title]]

Source: [[source filename]] (lines NNN-NNN)

## Extract Notes
Enrichment for [[existing note title]]. Source adds [what it adds].
Rationale: [why this enriches rather than duplicates]

---

## Connect
(to be filled by /connect phase)

## Check
(to be filled by /check phase)
```

**Queue entry structure (per note):**

```json
{
  "id": "note-NNN",
  "type": "note",
  "status": "pending",
  "target": "[note title]",
  "classification": "closed|open",
  "batch": "[source-basename]",
  "file": "[source-basename]-NNN.md",
  "created": "[ISO timestamp]"
}
```

**Queue entry structure (per enrichment):**

```json
{
  "id": "enrich-NNN",
  "type": "enrichment",
  "status": "pending",
  "target": "[existing note title]",
  "source_detail": "[what to add]",
  "batch": "[source-basename]",
  "file": "[source-basename]-NNN.md",
  "created": "[ISO timestamp]"
}
```

**Note numbering:** Start from `next_note_start` value in the extract task file (set by /queue). Numbers are globally unique and never reused across batches. Enrichments continue the same numbering sequence after notes.

---

## Critical Constraints

Never auto-extract. Always present findings and wait for user approval.

**When in doubt, extract.** For relevant sources, err toward capturing. Implementation ideas, tensions, validations, open questions, and near-duplicates all have value -- they become different output types, not rejections.

**The principle:** the goal is to capture everything relevant to the vault's domains. For relevant sources, that is MOST of the content. The selectivity gate exists for OFF-TOPIC filtering, not for rejecting on-mission content that happens to have a different form.

**Remember:**
- Implementation ideas are NOT "not claims" -- they are roadmap
- Tensions are NOT "not claims" -- they are wisdom
- Enrichments are NOT "duplicates" -- they add detail
- Validations are NOT "already known" -- they are evidence
- Open questions are NOT "not testable" -- they are guidance

**For relevant sources: skip rate < 10%. Zero extraction = BUG.**
