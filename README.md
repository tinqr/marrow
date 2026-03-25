# Marrow

Persistent memory for AI coding tools.

Every new Claude session starts from zero. Marrow fixes that. It stores your context as plain markdown -- notes, decisions, goals, session history -- and automatically loads it at the start of every session. A short setup conversation personalizes it to how you work.

## Install

```
claude plugin install tinqr/marrow
```

Requires Claude Code CLI, git, and tree.

## Setup

Run `/marrow:setup` in any directory. A 2-4 turn conversation creates your personalized vault. The setup generates your vault structure, a tailored CLAUDE.md, and initializes git tracking.

## How it works

**3 hooks run automatically:**

- **Session orient** -- loads your identity, goals, active tasks, and session history at the start of every conversation
- **Write validate** -- checks frontmatter structure whenever a note is written
- **Auto-commit** -- stages and commits vault changes after writes (async, debounced)

**9 skills for daily use:**

| Skill | What it does |
|-------|-------------|
| `/process` | Process an inbox source into connected notes |
| `/connect` | Find connections for a note, add wiki links |
| `/audit` | Check note structure across all notes |
| `/tasks` | View and manage the task stack |
| `/next` | Recommend the most valuable next action |
| `/revisit` | Update old notes with new context |
| `/remember` | Save a lesson so you don't repeat a mistake |
| `/process-all` | Batch process entire inbox |
| `/review` | Triage accumulated findings |

Skills are defined in the generated CLAUDE.md, so they work as natural language instructions rather than separate script files.

## Vault structure

```
your-vault/
  self/           # identity, methodology, goals
  inbox/          # raw captures, unprocessed
  notes/          # processed notes and indexes
  ops/            # tasks, sessions, reminders, observations
  archive/        # completed session logs
  CLAUDE.md       # generated instructions (the brain)
  marrow.yaml     # vault config
```

Everything is plain markdown. Portable, readable, git-tracked.

## How notes work

Every note is a proposition, not a label:

- Not: "Flutter navigation"
- But: "nested navigation in Flutter breaks back-stack on Android"

Notes flow through a pipeline: `inbox/` (capture) -> `/process` (extract and connect) -> `notes/` (permanent home). Wiki links (`[[note title]]`) connect ideas across domains.

## Testing

```bash
./test/run-tests.sh
```

13 tests covering hooks, utility scripts, and the setup skill.

## License

MIT
