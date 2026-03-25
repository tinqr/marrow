---
name: marrow:check
description: Schema validation for notes. Checks required fields, description quality, link health, and composability. Non-blocking -- warns but doesn't prevent capture. Triggers on "/check", "/check [note]", "check schema", "validate note", "validate all".
user-invocable: true
context: fork
model: sonnet
allowed-tools: Read, Grep, Glob
---

## EXECUTE NOW

**Target: $ARGUMENTS**

Parse immediately:
- If target contains a note name or path: validate that specific note
- If target is "all" or "notes": validate all notes in `notes/`
- If target is empty: ask which note to check

**Execute these steps:**

### Step 1: Locate Template

Determine which template applies to the target note:

1. Check the note's location -- notes in `notes/` use the standard note template
2. Check the `type` field in frontmatter -- specialized types may have dedicated templates
3. Look for a templates directory (`templates/`)
4. If no template found, use the default schema checks below

### Step 2: Read Target Note

Read the target note's full YAML frontmatter. Parse:
- All YAML fields and their values
- The body content (for link scanning)
- The footer section (for Topics and Relevant Notes)

### Step 3: Run Schema Checks

Run ALL validation checks. Each check produces PASS, WARN, or FAIL.

**START NOW.**

---

## Schema Checks

### Required Fields (FAIL if missing)

| Check | Rule | How to Verify |
|-------|------|---------------|
| `description` | Must exist and be non-empty | Check YAML frontmatter for `description:` field with non-empty value |
| Topics | Must link to at least one index | Check for `topics:` in YAML or `Topics:` section in footer. Must contain at least one wiki link |

A missing required field is a hard failure. The note cannot pass validation without these.

### Description Quality (WARN if weak)

| Check | Rule | How to Verify |
|-------|------|---------------|
| Length | Should be ~50-200 characters | Count characters in description value |
| New information | Must add context beyond the title | Compare description text against filename/title -- if semantically equivalent, WARN |
| No trailing period | Convention: descriptions don't end with periods | Check last character |
| Single sentence | Should be one coherent statement | Check for sentence-ending punctuation mid-description |

**How to check "adds new info":** Read the title (filename without .md). Read the description. If the description merely restates the title using different words, it fails this check. A good description adds one of:
- **Mechanism** -- how or why the claim works
- **Scope** -- what boundaries the claim has
- **Implication** -- what follows from the claim
- **Context** -- where the claim applies

**Examples:**

Bad (restates title):
- Title: `vector proximity measures surface overlap not deep connection`
- Description: "Semantic similarity captures surface-level overlap rather than genuine conceptual relationships"

Good (adds mechanism):
- Title: `vector proximity measures surface overlap not deep connection`
- Description: "Two notes about the same concept with different vocabulary score high, while genuinely related ideas across domains score low"

### YAML Validity (FAIL if broken)

| Check | Rule | How to Verify |
|-------|------|---------------|
| Frontmatter delimiters | Must start with `---` on line 1 and close with `---` | Read first line and scan for closing delimiter |
| Valid YAML | Must parse without errors | Check for common YAML errors: unquoted colons in values, mismatched quotes, bad indentation |
| No duplicate keys | Each YAML key appears only once | Scan for repeated field names |
| No unknown fields | Fields not in the template schema | Compare against template if available -- unknown fields get WARN |

### Enum Checks (WARN if invalid)

If the note has fields with enumerated values, check them:

| Field | Expected Values | Severity |
|-------|----------------|----------|
| `type` | note, methodology, tension, problem, learning, index | WARN |
| `area` | design, building, learning, finance, life | WARN |

If a field has a value not in the expected list, report the invalid value and list the valid options.

### Link Health (WARN per broken link)

| Check | Rule | How to Verify |
|-------|------|---------------|
| Body wiki-links | Each `[[link]]` should point to an existing file | Extract all `[[...]]` patterns from body, check each against file tree |
| Topics links | Index referenced in Topics must exist | Verify each topic wiki link resolves |
| Relevant notes links | Each note in Relevant Notes must exist | Verify each wiki link resolves |
| Backtick exclusion | Wiki links inside backticks are examples, not real links | Skip `[[...]]` patterns inside single or triple backtick blocks |

**How to verify link resolution:** For each `[[link text]]`, check if a file named `link text.md` exists anywhere in the vault. Wiki links resolve by filename, not path.

### Relevant Notes Format (WARN if incorrect)

| Check | Rule | Severity |
|-------|------|----------|
| Format | Each entry has `[[note]] -- relationship` | WARN |
| Context phrase present | Each entry should include `--` followed by relationship description | WARN |
| Relationship type | Standard types: extends, foundation, contradicts, enables, example | INFO |
| No bare links | `[[note]]` without context is a bare link -- useless for navigation | WARN |

### Composability (WARN if fails)

| Check | Rule | How to Verify |
|-------|------|---------------|
| Title test | Can you complete "This note argues that [title]"? | Read the title as a sentence fragment -- does it make a claim? |
| Specificity | Is the claim specific enough to disagree with? | Could someone reasonably argue the opposite? |
| Prose fitness | Would `since [[title]]` read naturally in another note? | Check if the title works as an inline wiki link |

**Topic labels vs claims:**
- "knowledge management" -- topic label, not a claim, FAILS composability
- "knowledge management requires curation not accumulation" -- claim, PASSES composability

## Batch Mode

When validating all notes (target is "all" or "notes"):

1. Discover all .md files in `notes/` directory (including subdirectories)
2. Run all schema checks on each note
3. Produce summary report:
   - Total notes checked
   - PASS / WARN / FAIL counts
   - Top issues grouped by check type
   - Notes needing immediate attention (FAIL items)
   - Pattern analysis: are certain check types failing systematically?

**Batch output format:**

```
## Validation Summary

Checked: N notes
- PASS: M (X%)
- WARN: K (Y%)
- FAIL: J (Z%)

### FAIL Items (immediate attention)
| Note | Check | Detail |
|------|-------|--------|
| [[note]] | description | Missing |
| [[note]] | topics | No topics footer |

### Top WARN Patterns
- Description restates title: N notes
- Missing context phrases in relevant_notes: N notes
- Enum value not in expected list: N notes
- Unknown fields in frontmatter: N notes

### Systematic Issues
[If certain check types fail across many notes, call it out here.
E.g., "12 of 20 notes have bare links in Relevant Notes -- this suggests
a pattern gap in /connect or /extract, not individual note problems."]

### Notes Needing Attention
1. [[note]] -- 2 FAIL, 1 WARN
2. [[note]] -- 1 FAIL, 3 WARN
```

## Output Format (Single Note)

```
=== CHECK: [[note title]] ===

PASS:
- description: present, 147 chars, adds mechanism beyond title
- topics: ["[[index-name]]"] -- exists
- yaml: well-formed, valid delimiters
- composability: title works as prose ("This note argues that [title]")

WARN:
- relevant_notes: bare link without context phrase for [[note-x]]
- type: "observation" not in expected values (valid: note, methodology, tension, problem, learning)

FAIL:
- (none)

Overall: PASS (2 warnings)
===
```

If WARN or FAIL items exist, include:

```
### Suggested Fixes
- **relevant_notes**: Add context phrase -- e.g., `[[note-x]] -- extends this by adding...`
- **type**: Change to valid value or document why a new type is needed
```

## Task File Update (when called from /process)

When a task file is in context (pipeline execution), update the `## Check` section:

```markdown
## Check
**Checked:** [UTC timestamp]

Schema check:
- description: PASS (147 chars, adds mechanism beyond title)
- topics: PASS (["[[index-name]]"])
- yaml: PASS (well-formed)
- type: WARN ("observation" not in expected values)
- relevant_notes: WARN (bare link for [[note-x]])
- composability: PASS

Overall: PASS (2 warnings)
```

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| PASS | Meets requirement fully | None needed |
| WARN | Optional issue or soft violation | Consider fixing, not blocking |
| FAIL | Required field missing or invalid format | Must fix before note is complete |
| INFO | Informational observation | No action needed |

**FAIL blocks pipeline completion.** A note with any FAIL-level issue should be flagged for fixes. It should NOT be considered done until FAIL items are resolved.

**WARN does not block.** Warnings are quality signals, not gates. A note can proceed through the pipeline with warnings.

---

## Critical Constraints

**never:**
- Block note creation based on validation failures (validation is a quality check, not a gate)
- Auto-fix issues without reporting them first
- Skip checks because the note "looks fine"
- Report PASS without actually running the check
- Ignore template schemas when they exist

**always:**
- Check ALL schema requirements, not a subset
- Report specific field values in FAIL/WARN messages (not just "description is weak")
- Suggest concrete fixes for every WARN and FAIL
- Fall back to default checks gracefully when no template exists
- Log patterns when running batch validation (recurring issues signal systematic problems)
- Update task file Check section when running in pipeline mode
