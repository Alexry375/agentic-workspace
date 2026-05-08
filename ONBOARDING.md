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

| Version | Notes                                                      |
|---------|------------------------------------------------------------|
| V0      | 5-file skeleton baseline                                   |
| V1      | Split into `shared/procedure.md` + `template/`             |
| V1.1    | Bricks distilled from a real prompt corpus                 |
| V2      | Self-contained workspaces, reports.jsonl, hook toggle      |

Run `git log --oneline` for the full history.

**Architecture (V2):**
```
agentic-workspace/
├── bin/aw                              # CLI: aw new / aw report / aw list
├── install.sh                          # wizard: writes ~/.agentic-workspace/config.json
├── shared/
│   ├── procedure.md                    # workspace top-level (inlined into CLAUDE.md)
│   ├── procedure-sub.md                # sub-workspace (inlined when --sub)
│   └── skills/genius/SKILL.md          # cognitive discipline skill
├── .claude/
│   ├── skills/genius -> ../../shared/skills/genius   # symlink (meta-repo coverage)
│   └── commands/{genius-on,genius-off}.md
├── IDENTITY.example.md
├── ONBOARDING.md, README.md, LICENSE
```

Per-user state lives in `~/.agentic-workspace/`:
- `config.json` — `{repo_path, reports_path}` written by install.sh
- `reports.jsonl` — append-only bilans from `aw report`
- `genius-hook-on` — flag file (presence ⇒ the user-level UserPromptSubmit hook fires)

Workspaces are created at `$PWD/workspaces/<name>/` by `aw new`. They are
**self-contained**: each ships its own `CLAUDE.md` (procedure inlined) and
its own `.claude/skills/genius/SKILL.md`. No `@import`, no runtime
dependency on the cloned repo's path. Moving or deleting the repo does not
break existing workspaces.

There is no `template/` folder anymore — its role is taken by `shared/` +
`bin/aw` generating the workspace at creation time.

## Read these first

In order:

1. `README.md`
2. `shared/procedure.md` — the heart of the project (top-level workspace)
3. `shared/procedure-sub.md` — sub-workspace variant
4. `bin/aw` — generator
5. `shared/skills/genius/SKILL.md`

## Method already established (don't re-litigate without a strong signal)

- **Pattern A (Agent tool)** = intra-workspace sub-task (Explore, Plan, audit,
  parallel analyses). The sub-agent returns a structured summary; its
  transcript is **not** persisted to disk.
- **Pattern B (`aw new --sub`)** = heavy isolated sub-task (>30 min, distinct
  dependencies). The parent agent prepares `workspaces/<name>/inputs/prompt.md`
  and asks the human to run `cd workspaces/<name> && claude`. **No
  `claude -p` recursion.**
- **Skill priority** is `Enterprise > Personal > Project`. A user-level skill
  with the same `name:` will override a project skill. Renaming the user-level
  copy (e.g. `genius-old`) breaks the conflict cleanly.
- **Workspace self-containment**: `aw new` inlines the relevant procedure and
  copies the skill. End users never see `shared/`. This avoids brittle paths
  and `@import` resolution.
- **Hook toggle** via flag file (`~/.agentic-workspace/genius-hook-on`). Off
  by default. Slash commands `/genius-on` and `/genius-off` toggle at runtime
  with no restart.
- **Brick admission rule**: a candidate brick should be backed by **≥3
  occurrences in real prompts** before being added to `shared/procedure.md`.
  2 occurrences = candidate. 1 = noted, not embedded.

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

1. **Validate V2 on a real task.** Especially `aw report` — collect bilans
   and see whether the corpus actually drives useful pruning.
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
