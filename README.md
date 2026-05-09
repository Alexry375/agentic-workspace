# agentic-workspace — V2

A minimalist `workspace/` template for Claude Code agents. **One-shot autonomous by default**, with a documented exception for irreducible human-in-the-loop projects. Workspaces inline their procedure into a self-contained `CLAUDE.md`, so moving or deleting the cloned repo never breaks an existing workspace. The `genius` skill is installed once at the user level and shared across all workspaces.

```
agentic-workspace/
├── bin/aw                              # CLI: aw new / aw report / aw list / aw context
├── install.sh                          # wizard: writes ~/.agentic-workspace/config.json
├── shared/
│   ├── procedure.md                    # workspace top-level procedure (inlined into CLAUDE.md)
│   ├── procedure-sub.md                # sub-workspace procedure (inlined when --sub)
│   ├── agent-brief.md                  # dense brief printed by `aw context`
│   └── skills/genius/SKILL.md          # canonical skill, sync target for ~/.claude/skills/genius/
├── IDENTITY.example.md                 # copy to IDENTITY.md and fill (gitignored)
├── ONBOARDING.md                       # context handoff for a fresh session on this repo
├── README.md
└── LICENSE
```

`shared/` is dev-side. End users never see it: `aw new` consumes it to generate a fully self-contained workspace.

## Installation

```bash
git clone https://github.com/Alexry375/agentic-workspace.git
cd agentic-workspace
./install.sh           # interactive: defaults to ~/.agentic-workspace/ for config
aw help                # verify
```

The wizard:
1. Asks where to store config (default `~/.agentic-workspace/`).
2. Writes `config.json` with the absolute path of this repo and the path of `reports.jsonl`.
3. Symlinks `bin/aw → ~/.local/bin/aw` (in `PATH` by default on most modern shells).

If you move the repo, re-run `./install.sh` from the new location to refresh `repo_path` in the config.

Requirements: `bash`, `jq`, and [Claude Code](https://docs.claude.com/en/docs/claude-code) in `PATH`.

## Usage

### Create and run a workspace

```bash
cd ~/anywhere
aw new my-project                      # creates ./workspaces/my-project/
cp -r ~/some-data workspaces/my-project/inputs/
cd workspaces/my-project
claude                                 # launches Claude Code with the procedure inlined
```

The agent reads `IDENTITY.md` + `inputs/`, runs the 5-requirement alignment in one reply, then works autonomously until `outputs/` is filled.

### Sub-workspace (delegated by a parent agent)

```bash
aw new heavy-subtask --sub             # creates a sub-workspace with bounded scope
```

Inside the workspace, `inputs/prompt.md` is created empty for the parent agent to fill. The sub-workspace `CLAUDE.md` enforces stricter rules: no human alignment, no further delegation, structured `outputs/result.md` for the parent to read back.

### Report a bilan

```bash
aw report my-project "ok — built, tested, deployed without intervention"
aw report my-project "ko — blocked on auth credentials, see outputs/blocked.md"
aw report my-project "partial — main feature works, secondary skipped per scope"
```

Appends a JSON line to `~/.agentic-workspace/reports.jsonl`. The report is **decoupled from the workspace** — the workspace name is a free-form tag, not a foreign key. The corpus drives future harness pruning rounds.

### List workspaces in the current directory

```bash
aw list                  # live workspaces only (default)
aw list --all            # everything, with STATUS column (live/archived)
aw list --archived       # only archived
```

There is no global registry — workspaces live under `$PWD/workspaces/` wherever you ran `aw new`. By design.

### Archive a workspace once you're done with it

```bash
aw archive my-project    # touch workspaces/my-project/.archive
aw revive  my-project    # rm  workspaces/my-project/.archive
```

The folder name never changes — only a `.archive` flag file is added inside the workspace. This is deliberate: renaming or moving the workspace would orphan its Claude Code session history (which is keyed by absolute path under `~/.claude/projects/`).

**To check archive state from a script or agent:**

```bash
[ -f workspaces/<name>/.archive ] && echo archived || echo live
```

That's the single source of truth. `aw list` filters by default so agents that use it never see hundreds of dormant workspaces.

## The `genius` skill and hook

Two reinforcing mechanisms, both always on at the user level:

- **Skill** — `~/.claude/skills/genius/SKILL.md` (kept in sync with `shared/skills/genius/SKILL.md`). Auto-discovered in every Claude Code session of the user. `aw new` does not copy it locally; workspaces rely on the user-level install.
- **Hook** — a `UserPromptSubmit` entry in `~/.claude/settings.json` prepends `[GENIUS] ...` to every prompt unconditionally.

**Sub-agents (`Agent` tool) edge case.** A sub-agent auto-discovers skills via their description, but auto-invocation of `genius` is not reliable. When you spawn a sub-agent on a non-trivial task, include in its prompt: *"Before acting, read and apply `~/.claude/skills/genius/SKILL.md`."* The sub-agent shares the filesystem with the parent, that path always resolves.

## Sub-tasks: two patterns, no recursive process

When the agent needs to delegate part of the work, two patterns only:

- **Intra-workspace delegation** → use the Claude Code `Agent` tool. The sub-agent returns a structured summary that you fold back into your context — implicit compaction, no token waste on transcripts.
- **Heavy work that deserves its own session** → the agent runs `aw new <name> --sub` to scaffold a sub-workspace, fills `inputs/prompt.md`, and asks the human to run `claude` there. No nested `claude -p` processes.

No recursive `claude -p`. Recursion adds complexity (control loss, lost visibility, cost overhead) for benefit that does not appear in any public benchmark.

## Design constraints

- **≤ 8 GB RAM** for the workspace alone (rules out massive parallelism)
- **No paid external APIs** — Claude Max subscription only
- **Self-contained procedure** — each workspace ships its own `CLAUDE.md` (procedure inlined). No hard dependency on the cloned repo path at runtime, only at `aw new` time. The `genius` skill is the one exception: it is sourced from the user-level `~/.claude/skills/`.
- **Caller-agnostic** — invocable by a human or by a parent Claude Code agent

## Status

V2. Experimental. Public for transparency and feedback. Future versions add bricks one at a time, each justified by a measured improvement on a benchmark we run ourselves.

## Open questions we're trying to answer

- How do you pose the **k highest-information questions** at t=0 instead of asking k random ones? (active questioning, GATE-style)
- How do you keep intent stable across `/clear` and compaction without paying for it in tokens? (sub-agents-as-compaction vs ledger files)
- How do you turn a free-form spec into machine-checkable rules at the start of a project, so violations are blocked by a hook instead of caught by a post-hoc audit?
- Where exactly is the marginal ROI of an extra skill / hook / sub-agent on a real project?

## Related work

- [walkinglabs/learn-harness-engineering](https://github.com/walkinglabs/learn-harness-engineering) — the most rigorous public curriculum on the topic
- [ai-boost/awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering) — index of the field
- [HumanLayer 12-factor agents](https://github.com/humanlayer/12-factor-agents) — conceptual compass
- [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [SWE-agent / mini-swe-agent](https://github.com/SWE-agent/mini-swe-agent) — the bash-only baseline this project is benchmarked against

## License

MIT
