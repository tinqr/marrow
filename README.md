# Marrow

**Your AI assistant remembers what you were working on — even when you start a new conversation.**

Marrow is a plugin for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that teaches it to remember. What you built, what you decided, what comes next — it's all saved between conversations so you never have to re-explain your project.

## The problem

Every time you start a fresh conversation in Claude Code, it starts from scratch. It doesn't know what you built yesterday, what decisions you made, or where you left off. You end up re-explaining your project every time.

Marrow fixes that. It saves your project context to files on your computer, so your next conversation picks up right where the last one ended.

## What it looks like

<!-- TODO: Replace with a screenshot of /recall in the Claude desktop app -->

```
> /recall

  Project: onboarding-flow — Redesigning the signup experience
  Last session: 2026-02-24 16:30 [Claude Code]
    Built the welcome screen and email validation step.
    Decided on a 3-step flow instead of single-page form
    for better mobile experience.
  Next: Build the "choose your plan" step with the pricing cards.
  Knowledge: 3 notes

  Ready to work on onboarding-flow.

> ... you work for a while ...

> /checkpoint

  Checkpointed onboarding-flow. Session logged.
```

Two commands. `/recall` loads your context at the start. `/checkpoint` saves it when you're done. That's the core of Marrow — everything else builds on this.

## Why Marrow

### Use any tool, keep your history

Start a session in Claude Code, save your progress, then continue in [Cursor](https://www.cursor.com/) or [Windsurf](https://windsurf.com/) tomorrow — your full history carries over. Each session entry is tagged with which tool wrote it (`[Claude Code]`, `[Cursor]`, etc.), so you can always see who did what.

This works because Marrow stores everything in plain text files — a format called [Markdown](https://www.markdownguide.org/getting-started/) (files that end in `.md`). Markdown is text with some formatting symbols, and it's readable by any text editor and any AI coding tool. There's no special format that locks you into one tool.

### It stays small so your tool stays smart

AI tools can only hold so much information in a single conversation — think of it as a thinking budget. When too much gets loaded in, the tool gets slower, loses track of details, and gives worse answers.

Marrow avoids this by design. Loading a project's full context uses a tiny fraction of the budget. The session log keeps only the 10 most recent entries and archives older ones automatically. Notes are stored separately and only loaded when they're relevant. More budget for thinking, less spent on remembering.

### Your files, your data

Everything Marrow creates is a text file on your computer. No cloud sync, no account, no database. You can open these files in any text editor, back them up however you like, or browse them yourself when you need to remember something. If you stop using Marrow, your files are still there and still readable.

## Install

**You'll need:** [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and working.

1. Open the Claude desktop app
2. Type these two commands, one at a time:

```
/plugin marketplace add tinqr/marrow
```

```
/plugin install marrow@tinqr-marrow
```

3. Type `/marrow:setup`

It'll ask your name, what you do, and what your first project is called. Takes about a minute. Setup creates a folder on your computer (by default, a folder called `marrow` in your home directory) — this is where your project history and notes will live.

4. To start using Marrow, open Claude from that new folder. In the Claude desktop app, you can change your working folder from the folder icon at the top of the conversation. Point it to your Marrow folder.

## What it creates

Here's what's inside your Marrow folder:

```
marrow/
├── CLAUDE.md       # Instructions that Claude reads automatically
├── projects.md     # List of all your projects
├── index.md        # Map of all your saved knowledge
└── onboarding-flow/
    ├── CLAUDE.md          # Project description and session history
    ├── session-archive.md # Older session entries
    └── notes...           # Decisions and knowledge worth keeping
```

You can have as many projects as you want — each one gets its own folder inside Marrow.

## When you start a session

Every time you open Claude from your Marrow folder, it automatically shows you the lay of the land — which projects you have, what happened last, and what needs attention. You don't need to type anything:

```
=== marrow ===
Projects: 3 (2 active, 1 paused)

onboarding-flow
  2026-02-24 16:30 [Claude Code] Built welcome screen. Next: pricing cards
landing-page
  2026-02-23 11:00 [Cursor] Updated hero section. Next: add testimonials

Commands: /recall <project> · /checkpoint · /new-project
===============
```

From there, type `/recall onboarding-flow` to load the full context for that project and start working.

## Commands

You only need two commands day to day:

| Command | What it does |
|---------|-------------|
| `/recall` | Load your project's context when you start a session |
| `/checkpoint` | Save your progress when you're done |

And a few you'll use occasionally:

| Command | What it does |
|---------|-------------|
| `/new-project` | Add another project |
| `/joint` | Connect a code folder so any AI tool can find your project's context |
| `/reindex` | Tidy up — rebuild the knowledge map and fix broken links |

## How it works

Here's what's happening under the hood when you use those commands.

### Session history

Each project keeps a running log of what happened — what changed, what was decided, and what comes next. When you run `/checkpoint`, a new entry is added to the bottom of that log. When you run `/recall` in your next conversation, the tool reads the log and picks up where things left off.

Here's what a session log entry looks like (the formatting symbols like `###` and `**` are Markdown — the same format mentioned earlier):

```
### 2026-02-24 16:30 [Claude Code]
**What changed:**
- Built the welcome screen with email validation
- Added the step progress indicator

**Decisions:**
- Went with a 3-step flow instead of single page — better on mobile

**Next:** Build the "choose your plan" step with pricing cards.
```

The tag at the top (`[Claude Code]`) records which tool wrote this entry. If you switch to Cursor for the next session, that entry would say `[Cursor]`. This way the log is always a complete timeline of your project, no matter which tools you used along the way.

Each tool adds its entries at the bottom and never changes or removes what another tool wrote. This is why the cross-tool handoff works — nothing gets overwritten, nothing gets lost.

The log keeps the 10 most recent entries. Older ones are moved to an archive file automatically, so the active log stays short and the tool can read it quickly.

### Notes

As you work, you can ask Claude to save things worth remembering as notes — decisions you made, tricky problems you solved, patterns you want to reuse. You can say something like "save a note about why we chose the 3-step flow" and Claude creates a small text file in your project folder.

Notes can link to each other using something called "wiki links" — they work like links between Wikipedia pages. A link looks like `[[note name]]`. These links let the tool jump between related decisions. For example, from a note about your signup flow to one about your pricing model. When you `/checkpoint`, Marrow automatically makes sure links work in both directions.

Over time, your notes become a connected web of project knowledge that your tools can navigate on their own, instead of you having to re-explain everything.

### Connecting your code folder

Your code probably lives in its own folder somewhere, separate from Marrow. The `/joint` command connects the two — the name comes from anatomy, like Marrow: a joint is where two bones meet, and here it's where your code folder meets your project knowledge.

To set this up, just tell Claude something like "joint my-project to code/my-app" and it'll handle it. Marrow adds a small file called `CLAUDE.md` to your code folder with instructions telling any AI tool where to find your project's full history and notes.

After that, when you open your code folder in any AI tool, just tell it to read the `CLAUDE.md` file. It'll find the Marrow section and understand where your project's context lives — session history, decisions, notes, everything. That's how cross-tool support works: the joint is the bridge between your code and your knowledge, and any tool can cross it.

### Checkpoint reminders

If you've been working for 20+ minutes without saving, Marrow will gently remind you to run `/checkpoint`. Once per conversation — it won't nag.

## Getting help

If something isn't working or you're not sure how to do something, [open an issue on GitHub](https://github.com/tinqr/marrow/issues). Describe what you were trying to do and what happened — that helps us help you faster.

## License

[MIT](LICENSE)
