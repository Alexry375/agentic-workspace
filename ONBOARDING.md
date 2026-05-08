# ONBOARDING — agentic-workspace

> Context handoff for a fresh Claude Code session working **on this repo
> itself** (the meta-project), not for an agent running inside a created
> workspace. Read this in full before responding.

## Why this repo exists

A minimalist Claude Code workspace template, built around one principle:
**every brick has to earn its place**. No skill, hook, or rule is added
without documented evidence that it pulls its weight on real tasks.

The bias is toward **subtraction**, not accumulation. If a brick can't be
defended after 1-2 sessions of use, it gets cut.

## Current state

| Version | Commit  | Change                                           |
|---------|---------|--------------------------------------------------|
| V0      | `a926c17` | 5-file skeleton baseline                       |
| V1      | `c4079c6` | Split into `shared/procedure.md` + `template/` |
| V1.1    | `8789c1a` | Bricks distilled from a real prompt corpus     |
| —       | `ad71389` | Non-interactive symlink installer              |

Run `git log --oneline` for the full history.

**Architecture:**
```
agentic-workspace/
├── shared/procedure.md      # common procedure (~120 lines)
├── template/
│   ├── CLAUDE.md            # @../shared/procedure.md + 5 boot requirements
│   ├── inputs/              # human (or another agent) drops content here
│   └── outputs/             # agent writes here
├── .claude/skills/genius/SKILL.md   # cognitive discipline skill, auto-loaded
├── bin/aw                   # CLI: aw new <name> / aw list
├── install.sh               # idempotent symlink to ~/.local/bin/aw
├── IDENTITY.example.md      # template — copy to IDENTITY.md (gitignored) per workspace
├── README.md, LICENSE
└── workspaces/              # gitignored — created by `aw new`
```

There is no `template-sub/`. Heavy delegated sub-tasks use the **Pattern B**
flow described in `shared/procedure.md` (the parent prepares
`workspaces/<name>/inputs/prompt.md`, the human launches a fresh
`claude` session there).

## Read these first

In order:

1. `README.md`
2. `shared/procedure.md` — the heart of the project
3. `template/CLAUDE.md` — see how `@import` is wired
4. `.claude/skills/genius/SKILL.md`

## Method already established (don't re-litigate without a strong signal)

- **Pattern A (Agent tool)** = intra-workspace sub-task (Explore, Plan, audit,
  parallel analyses). The sub-agent returns a structured summary; its
  transcript is **not** persisted to disk.
- **Pattern B (dedicated workspace)** = heavy isolated sub-task
  (>30 min, distinct dependencies). Prepare
  `workspaces/<name>/inputs/prompt.md`, then ask the human to launch
  `cd workspaces/<name> && claude` themselves. **No `claude -p` recursion.**
- **Skill priority** is `Enterprise > Personal > Project` (counter-intuitive).
  A user-level skill with the same `name:` will override a project skill —
  rename or set `disable-model-invocation: true` to neutralize it.
- **`@<path>`** is the official Claude Code import mechanism. Inline content
  expansion, max depth 5, path relative to the file containing the `@`.
- **Brick admission rule**: a candidate brick should be backed by **≥3
  occurrences in real prompts** before being added to `shared/procedure.md`.
  2 occurrences = candidate. 1 = noted, not embedded.
- **Empirically verified**: the current `genius` skill alone covers most of
  the dominant pattern across observed prompts (anti-self-deception). That's
  why it's the only embedded skill.

## Reference repos worth a look

If asked "what did we miss", these are useful study material (clone them
yourself if needed):

- `humanlayer/12-factor-agents` — opinionated agent design principles
- `princeton-nlp/SWE-agent` — task-loop / scaffolding reference
- `MineDojo/Voyager` — long-horizon agent skills library
- `nus-apr/auto-code-rover` — code repair pipeline
- `stanfordnlp/dspy` — prompt programming (compilation, not chat)
- `obra/superpowers` — community Claude Code skill collection

These are **not** dependencies — they're prior art. Steal ideas, don't import.

## Conceptual backlog

In rough priority order:

1. **Validate V1.1 on a real task.** The only way to know whether a brick
   pulls its weight or adds noise is to use it.
2. **Auto-capture prompts** from `~/.claude/projects/*.jsonl` post-session,
   to grow the corpus that drives future pruning rounds.
3. **Survey the top public Claude Code workspace templates** (e.g. the
   `thoughts/ledgers/` pattern that survives `/clear`) — see what we missed.
4. **Re-prune** at corpus size milestones (n=20, n=50, n=100).

## Personal overlay

If you maintain a personal fork or use this repo as your daily template,
you can drop a local `ONBOARDING.local.md` next to this file with
machine-specific paths, your own backlog, references to your knowledge
base, etc. That file is gitignored.

## Tone

This project is built through **tight iterative pruning**. Defend your
choices when challenged, but cut without sentiment when a brick fails to
earn its place. No filler, no sycophancy. If you make a non-trivial
decision during a session, document it in this file before leaving.
