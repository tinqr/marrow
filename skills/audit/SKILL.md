---
name: audit
description: Check note structure across all notes -- disconnected notes, missing descriptions, missing topics, broken wiki links. Non-blocking report. Use as a quality gate after creating notes or as periodic maintenance. Triggers on "/audit", "/audit [note]", "check note health", "audit notes".
user-invocable: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
context: fork
---

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse immediately:
- If target contains a note name: audit that specific note
- If target is "all" or empty: audit all notes in `notes/`
- If target is "recent": audit recently created/modified notes

**Execute these steps IN ORDER:**

### Step 1: Discover Notes

Find all notes to audit:

```bash
find notes/ -name "*.md" -not -name "*.md~" | sort
```

If a specific note was targeted, audit only that note. Otherwise audit everything.

### Step 2: Check Each Note

For each note, run these 5 checks. Tag every finding with a severity level:

- **FAIL** -- structural problem, note is broken or unusable. Fix before it causes downstream issues.
- **WARN** -- quality issue, note works but is degraded. Address when convenient.
- **INFO** -- observation worth noting but not a problem. No action needed.

**1. YAML frontmatter integrity**
- File starts with `---`, has closing `---` -- missing delimiters = **FAIL**
- YAML parses without errors -- parse failure = **FAIL**
- No duplicate keys -- duplicates = **FAIL**

**2. Description quality**
- Description field is present and non-empty -- missing entirely = **FAIL**
- Description adds information beyond the title -- restates title = **WARN**
- Description is not just the title rephrased -- same check, different angle = **WARN**
- Length is roughly 50-200 characters -- outside range = **WARN**
- No trailing period -- trailing period = **WARN**

**3. Index connection**
- Note appears in at least one index's Core Ideas section -- not in any index = **WARN**
- How to check: grep for `[[note title]]` in index files
- The note's Topics footer references a valid index -- missing Topics footer = **WARN**
- Topics targets exist as files -- broken Topics reference = **WARN**
- A note that fails ALL three (no index mention, no Topics footer, no valid Topics target) = **FAIL** -- effectively invisible to graph traversal

**4. Wiki link density**
- Count outgoing wiki links in the note body (not just frontmatter)
- Expected minimum: 2 outgoing links
- If < 2: **WARN** -- the note is not participating in the graph
- If 0: **WARN** -- dead end, route to /connect
- Sparse notes should be routed to /connect for connection finding

**5. Link resolution**
- Scan ALL wiki links in the note -- body, frontmatter `relevant_notes`, and Topics
- For each `[[link]]`, confirm a matching file exists in the vault
- **Exclude** wiki links inside backtick-wrapped code blocks (single backtick or triple backtick) -- these are syntax examples, not real links
- A single dangling link = **FAIL** with the specific broken link identified

### Step 3: Identify Disconnected Notes

After checking individual notes, look for vault-wide issues:

**Orphan detection:**
- For each note, count incoming links: grep for `[[note title]]` across all .md files
- If 0 incoming links: AT RISK -- note exists but nothing references it
- If 1 incoming link: LOW RISK -- single point of connection
- If 2+ incoming links: OK

**Index coverage:**
- List all area indexes (`notes/*.md` that have `type: index`)
- List all project indexes (`notes/*/*.md` that have `type: index`)
- For each index, count how many notes reference it in their Topics footer
- Flag indexes with 0 referencing notes

**Deduplication scan:**
- While reading notes, watch for notes that make the same claim with different words
- Check notes that share the same Topics references and similar descriptions
- If two notes argue the same thing: flag as **WARN** with both paths listed and a merge suggestion
- Do NOT auto-merge -- flag for human decision, note which is more complete or better connected

### Step 4: Compile Report

Produce a summary report. This is non-blocking -- no auto-fixes, just findings.

```markdown
## Audit Report

**Scope:** [N notes checked]
**Date:** [YYYY-MM-DD]

### Summary

| Check | Pass | Warn | Fail |
|-------|------|------|------|
| Frontmatter | N | N | N |
| Description | N | N | N |
| Index connection | N | N | N |
| Wiki link density | N | N | N |
| Link resolution | N | N | N |

**Totals:** N notes checked. N FAIL, N WARN, N INFO. [N notes fully passing.]

### Critical Issues (FAIL)

Fix these first -- they indicate broken or unusable notes.

- `notes/[file].md` -- **broken link:** [[target]] does not resolve
- `notes/[file].md` -- **no description:** description field missing entirely
- `notes/[file].md` -- **bad frontmatter:** YAML does not parse
- `notes/[file].md` -- **invisible:** no index connection, no Topics footer, no incoming links

### Warnings (WARN)

Quality issues -- notes work but are degraded.

#### Description Quality
- `notes/[file].md` -- description restates title, adds no information

#### Disconnected Notes (no index reference)
- `notes/[file].md` -- not referenced in any index

#### Sparse Notes (< 2 outgoing links)
- `notes/[file].md` -- [N] outgoing links

#### Orphan Notes (0 incoming links)
- `notes/[file].md` -- nothing links here

### Observations (INFO)

- `notes/[file].md` -- single incoming link (low risk, not urgent)
- Index `notes/[index].md` -- approaching size threshold ([N] links)

### Possible Duplicates

- `notes/[file-a].md` and `notes/[file-b].md` -- both argue [same claim]. Merge candidate.

### Recommended Actions

- Fix all FAIL items before they cause downstream issues
- Run `/connect` on sparse and disconnected notes
- Fix broken wiki links (remove or create target)
- Add descriptions to notes missing them
- Review orphan notes -- connect or archive
- Review possible duplicates -- merge or differentiate
```

**START NOW.** The reference material below explains philosophy -- use to guide reasoning, not as output to repeat.

---

# Audit

Check note structure across the vault. Surfaces disconnected notes, missing descriptions, missing topics, broken wiki links. Produces a non-blocking report.

## Philosophy

**Verification serves the graph, not bureaucracy.**

The audit exists because a knowledge graph degrades silently. Notes lose connections, descriptions go stale, links break. Without periodic checks, the vault becomes a pile of files instead of a traversable network.

But audit is a diagnostic, not a gatekeeper. It produces a report of findings. It does not block work. It does not auto-fix. It surfaces problems so the user can decide what matters.

> "The unit of verification is the note, not the check type."

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| FAIL | Structural problem -- note is broken or unusable | Fix before it causes downstream issues |
| WARN | Quality issue -- note works but is degraded | Address when convenient |
| INFO | Observation -- worth noting but not a problem | No action needed |

### What counts as FAIL

- Missing frontmatter delimiters (`---`)
- YAML that does not parse
- Missing description field entirely
- Broken wiki link (target file does not exist)

### What counts as WARN

- Description restates the title without adding information
- Description exceeds 200 characters
- Note has fewer than 2 outgoing wiki links
- Note is not referenced in any index
- Note has 0 incoming links from other notes

### What counts as INFO

- Note has only 1 incoming link (single point of connection)
- Index is approaching size threshold

## Check Details

### Frontmatter Integrity

```bash
# Check that file starts with --- and has a closing ---
head -1 "notes/file.md"  # should be ---
grep -n "^---$" "notes/file.md"  # should find at least 2 occurrences
```

Valid frontmatter:
- Starts with `---` on line 1
- Has a closing `---` within the first 20 lines
- YAML between delimiters parses without error
- No duplicate keys

### Description Quality

The description is the API of the note. Agents decide whether to load a note based on title + description. A bad description causes two failure modes:
- **False positive:** agent reads the note expecting X, wastes context on Y
- **False negative:** agent skips the note because description does not signal relevance

**Checks:**

| Constraint | Check | Severity |
|------------|-------|----------|
| Exists | `description` field present and non-empty | FAIL |
| Length | 50-200 characters | WARN |
| Content | Adds NEW information beyond the title | WARN |
| Format | Single sentence, no trailing period | WARN |

**How to check "adds new info":** Read the title, read the description. If the description says the same thing in different words, it fails this check. A good description adds: mechanism (how/why), scope (boundaries), implication (what follows), or context (where it applies).

### Index Connection

Notes exist in a graph. A note with no index connection is floating -- agents cannot discover it through normal navigation.

**Checks:**

| Check | Method | Severity |
|-------|--------|----------|
| Topics footer exists | Note has `Topics:` section with `[[index]]` links | WARN |
| Topics targets exist | Each referenced index file exists | WARN |
| Appears in an index | `grep -r '[[note title]]'` finds the note in at least one index | WARN |

A note that fails all three is disconnected -- effectively invisible to graph traversal.

### Wiki Link Density

Notes participate in the knowledge graph through wiki links. A note with no outgoing links is a dead end -- it receives but does not give.

**Threshold:** minimum 2 outgoing wiki links in the note body.

Notes below threshold should be routed to `/connect` for connection finding.

**Exclude from count:**
- Wiki links inside code blocks (backtick-wrapped)
- Wiki links in frontmatter `topics` field (these are structural, not content connections)
- Wiki links in the Topics footer (same reason)

### Link Resolution

Every wiki link must resolve to an existing file. Dangling links are broken promises -- an agent following the link finds nothing.

**How to check:**

For each `[[link text]]` in the note:
1. Check if `notes/link text.md` exists
2. Check if `notes/*/link text.md` exists (project subfolder)
3. If neither exists: broken link

**Exclude:** wiki links inside backtick code blocks are syntax examples, not real links.

### Orphan Detection (vault-wide)

After checking individual notes, run a vault-wide orphan scan:

```bash
# For each note, count incoming links
grep -r '[[note title]]' notes/ --include="*.md" | wc -l
```

| Incoming Links | Risk Level | Action |
|---------------|------------|--------|
| 0 | AT RISK | Flag -- nothing references this note |
| 1 | LOW RISK | Note -- single point of connection |
| 2+ | OK | Healthy |

Orphan notes are not necessarily bad. A newly created note has 0 incoming links until /connect runs. But a note that has existed for a while with 0 incoming links is likely forgotten.

## Common Failure Patterns

| Pattern | Symptom | Fix |
|---------|---------|-----|
| Title restated as description | Description adds no information | Rewrite description to add mechanism/scope |
| Missing index connection | Note not in any index | Add to appropriate index or create Topics footer |
| Dangling links | Link target does not exist | Remove link, create target note, or fix spelling |
| Sparse note | < 2 outgoing links | Route to /connect for connection finding |
| Orphan accumulation | Multiple notes with 0 incoming links | Batch /connect or archive if no longer relevant |

## Batch Mode

When auditing all notes (default behavior):

1. Discover all notes in `notes/` directory (recursive)
2. Skip index files (`type: index` in frontmatter) for content checks -- only check their structural integrity
3. Run all 5 checks on each note
4. Run vault-wide orphan detection
5. Produce summary report with:
   - Total notes checked
   - Pass/Warn/Fail counts per check category
   - Top issues grouped by check type
   - Notes needing immediate attention (FAIL items)

## Single Note Mode

When auditing a specific note:

1. Run all 5 checks on the target note
2. Check incoming links for that note specifically
3. Report findings for just that note

## Critical Constraints

**Never:**
- Auto-fix issues without being asked -- audit is diagnostic only
- Block work based on audit findings -- the report is non-blocking
- Skip checks to save time -- run all checks, report all findings
- Mark a note as "passing" if any FAIL-level issue exists

**Always:**
- Check ALL wiki links, not just a sample
- Distinguish between FAIL, WARN, and INFO clearly
- Suggest specific next actions for each issue
- Report the full picture -- good news and bad news
- Exclude code-block wiki links from resolution checks
