# agentic-workspace — V1

A minimalist `workspace/` template for Claude Code agents. **One-shot autonomous by default**, with a documented exception for irreducible human-in-the-loop projects.

```
agentic-workspace/
├── bin/
│   └── aw                 # CLI: aw new <name> / aw list
├── install.sh             # adds bin/ to your PATH (interactive, idempotent)
├── shared/
│   └── procedure.md       # common procedure (~70 lines, imported by template)
├── template/              # classic workspace (with a human at t=0)
│   ├── CLAUDE.md          # imports shared/ + 5 alignment requirements at boot
│   ├── inputs/            # human (or another agent) drops content here
│   └── outputs/           # agent writes here
├── .claude/skills/genius/ # cognitive discipline skill, auto-loaded
├── IDENTITY.example.md    # template — copy to IDENTITY.md and fill (gitignored)
├── README.md
└── LICENSE
```

One template, one shared procedure, one skill. Everything else is added only with documented ROI.

## Installation

```bash
git clone https://github.com/Alexry375/agentic-workspace.git
cd agentic-workspace
./install.sh    # appends `bin/` to your PATH in ~/.bashrc or ~/.zshrc (asks first)
# Open a new shell, then verify:
aw help
```

If you prefer not to modify your shell rc, just call `./bin/aw` directly from the repo or add `bin/` to your `PATH` manually.

You also need [Claude Code](https://docs.claude.com/en/docs/claude-code) installed (`claude` in your PATH).

## Usage

```bash
# 1. Create a new workspace
aw new my-project

# 2. Drop your project, data, or task description into inputs/
cp -r ~/some-repo workspaces/my-project/inputs/

# 3. Launch Claude Code from the workspace (cd yourself — pass any flags you want)
cd workspaces/my-project
claude              # or: claude --continue, claude --resume, etc.

# 4. The agent will:
#    - read IDENTITY.md, inputs/
#    - run the 5-requirement alignment in one reply (0-3 questions max)
#    - work autonomously until outputs/ is filled

# List workspaces:
aw list
```

## Sub-tasks: two patterns, no recursive process

When the agent needs to delegate part of the work, two patterns only:

- **Intra-workspace delegation** → use the Claude Code `Agent` tool. Optionally pre-load skills via `.claude/agents/<name>.md` frontmatter (`skills: [genius]`). The sub-agent returns a structured summary that you fold back into your context — implicit compaction, no token waste on transcripts.
- **Heavy work that deserves its own session** → the agent prepares a new workspace under `workspaces/<name>/`, drops a complete prompt in `inputs/prompt.md`, and asks the human to run `claude` there. No nested `claude -p` processes; the human stays in the loop for these cases (low cost: just a launch command). The new agent sees the prepared prompt and skips most alignment questions.

No recursive `claude -p`, no `template-sub/`. Recursion adds complexity (control loss, lost visibility, cost overhead) for benefit that does not appear in any public benchmark — we'll add it only when measured ROI justifies it.

## Design constraints

- **≤ 8 GB RAM** for the workspace alone (rules out massive parallelism)
- **No paid external APIs** — Claude Max subscription only
- **Self-contained** — no dependencies outside the workspace directory
- **Caller-agnostic** — invocable by a human or by a parent Claude Code agent (the parent prepares `inputs/prompt.md`)

## Status

V1. Experimental. Public for transparency and feedback.

Future versions will add bricks one at a time, each justified by a measured improvement on a benchmark we run ourselves (since no public benchmark currently measures "build a complete app from scratch" — see [METR Time Horizon](https://metr.org/time-horizons/) for the closest thing).

## Open questions we're trying to answer

- How do you pose the **k highest-information questions** at t=0 instead of asking k random ones? (active questioning, GATE-style)
- How do you keep intent stable across `/clear` and compaction without paying for it in tokens? (sub-agents-as-compaction vs ledger files)
- How do you turn a free-form spec into machine-checkable rules at the start of a project, so violations are blocked by a hook instead of caught by a post-hoc audit?
- Where exactly is the marginal ROI of an extra skill / hook / sub-agent on a real project?

## Related work

- [walkinglabs/learn-harness-engineering](https://github.com/walkinglabs/learn-harness-engineering) — the most rigorous public curriculum on the topic (5 subsystems: Instructions / State / Verification / Scope / Session Lifecycle)
- [ai-boost/awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering) — index of the field
- [HumanLayer 12-factor agents](https://github.com/humanlayer/12-factor-agents) — conceptual compass
- [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [SWE-agent / mini-swe-agent](https://github.com/SWE-agent/mini-swe-agent) — the bash-only baseline this project is benchmarked against

## License

MIT
