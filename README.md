# Marrow

**Lightweight session memory for AI coding tools.**

Every time you start a new conversation with an AI coding tool, it forgets everything — what you were building, what you decided, where you left off. You end up repeating yourself every session.

Marrow gives your tools a memory. It saves your project context to simple text files on your machine, so the next session picks up right where the last one ended. Works across tools too — start a session in Claude Code, continue it in Cursor or Windsurf. The context follows you, not the tool.

## Use any tool, keep your context

Because Marrow stores context in plain files that any tool can read, you're not locked into paying for one tool's premium memory features. Use free tiers across multiple tools — Claude Code, Cursor, Windsurf — and Marrow carries your project history between all of them. Switch tools whenever you want. Your context stays yours.

## Why lightweight matters

AI tools have a limited memory budget per conversation (called a context window). Tools that try to "remember everything" eat into that budget, leaving less room for the tool to actually think about your problem.

Marrow stays small on purpose. Loading a project's context takes roughly 1-2K tokens — a fraction of the budget. The session log keeps only the 10 most recent entries and archives older ones automatically. Notes are stored separately and only loaded when they're actually relevant. More budget for thinking, less spent on remembering.

## What a session looks like

```
> /recall

  Project: my-app — React app with Supabase backend
  Last session: 2026-02-24 16:30 [Claude Code]
    Added pagination to the dashboard. Decided on cursor-based
    pagination over offset for performance.
  Next: Wire up the "load more" button to the cursor endpoint.
  Knowledge: 4 notes

  Ready to work on my-app.

> ... work for a while ...

> /checkpoint

  Checkpointed my-app. Session logged.
```

That's it. Two commands — one to load context, one to save it.

## Install

Marrow currently works as a [Claude Code plugin](https://docs.anthropic.com/en/docs/claude-code/plugins). Support for Cursor, Windsurf, and Antigravity is coming next.

Install from inside Claude Code:

```
/plugin marketplace add tinqr/marrow
/plugin install marrow@tinqr-marrow
```

Then run `/marrow:setup` — it'll ask you a few questions and set everything up in about a minute.

## What it creates

```
~/marrow/
├── CLAUDE.md              # Setup and commands reference
├── projects.md            # List of all your projects
├── index.md               # Global knowledge map across all projects
└── my-app/
    ├── CLAUDE.md          # Project description, tasks, session log
    ├── session-archive.md # Older session entries
    └── notes...           # Decisions, patterns, anything worth keeping
```

Everything is plain text. You can open these files in any editor, back them up however you like, or just browse them when you need to remember something.

## Commands

| Command | What it does |
|---------|-------------|
| `/marrow:setup` | First-time setup — creates your knowledge store and first project |
| `/recall` | Load a project's context at the start of a session |
| `/checkpoint` | Save your progress at the end of a session |
| `/new-project` | Add another project |
| `/joint` | Connect an existing code folder to a Marrow project |
| `/reindex` | Tidy up — rebuild indexes and fix broken links |

## How it works

### Session log

Each project keeps a running log of what changed, what decisions were made, and what should happen next. When you `/checkpoint`, a new entry gets added. When you `/recall`, the log is read back so the tool has full context on your project. The log keeps the 10 most recent entries — older ones move to an archive automatically, so the active file stays small.

### Notes

Notes are where you capture things worth remembering across sessions — decisions, architecture choices, tricky problems you solved. Each note is a plain text file with a few lines of structured info at the top (a description and some tags) so the tool can quickly understand what the note is about without reading the whole thing.

Notes link to each other using a simple `[[note name]]` syntax. These links let the tool navigate between related decisions — for example, jumping from a note about your database schema to one about your API design. When you checkpoint, Marrow automatically maintains these connections in both directions. Over time, your notes become a web of project knowledge that the tool can navigate efficiently instead of searching through everything.

### Joints

Your code probably lives in its own folder (like `~/my-app/`), separate from Marrow. A "joint" connects the two — it drops a small pointer into your code project so that any AI tool working there knows where to find the project's context and history. Think of it as a bridge between where your code lives and where your knowledge lives.

### Works across tools

The session log format is simple enough for any tool to read and write. Each entry is tagged with which tool wrote it (`[Claude Code]`, `[Cursor]`, etc.), so you get a complete history even when switching between tools.

## Checkpoint reminders

If you've been working for 20+ minutes without saving, Marrow will gently remind you to checkpoint. Just once per session — it won't nag.

## Philosophy

Your project knowledge should live in files you own, not locked inside any tool's proprietary storage. Marrow is plain text all the way down. If you stop using it tomorrow, everything you wrote is still there in readable files on your machine.

## License

[MIT](LICENSE)
