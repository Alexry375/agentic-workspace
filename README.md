# agentic-workspace — V1

A minimalist `workspace/` template for Claude Code agents. **One-shot autonomous by default**, with a documented exception for irreducible human-in-the-loop projects.

```
agentic-workspace/
├── shared/
│   └── procedure.md       # common procedure (~50 lines, used by both templates below)
├── template/              # classic workspace (with a human at t=0)
│   ├── CLAUDE.md          # imports shared/ + 5 alignment requirements at boot
│   ├── inputs/            # human drops content here
│   └── outputs/           # agent writes here
├── template-sub/          # sub-workspace (no human, called by a parent agent)
│   ├── CLAUDE.md          # imports shared/ + structured task.json contract
│   ├── inputs/
│   └── outputs/
├── .claude/skills/genius/ # cognitive discipline skill, auto-loaded
├── IDENTITY.example.md    # template — copy to IDENTITY.md and fill (gitignored)
├── README.md
└── LICENSE
```

Two templates, one shared procedure, one skill. Everything else is added only with documented ROI.

## Why so minimal?

A few data points from the public literature (May 2026):

- On **SWE-bench Pro** with the same model (Opus 4.5), the spread between three real-world harnesses is only **5.2 points** (Auggie 51.8% / Claude Code 55.4% / Cursor 50.2%). Source: [morphllm.com/swe-bench-pro](https://www.morphllm.com/swe-bench-pro).
- Bare `mini-swe-agent` (Claude + bash, ~100 lines of Python) hits **51.9% Pro** with Opus 4.6 — within 3-7 points of full Claude Code.
- On Anthropic's BrowseComp eval, **token usage alone explains 80% of the variance** ([Multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)).

→ The model matters far more than the harness. The harness gives you ~5-10 marginal points, not 30.

So instead of starting from a 30-skills + 13-hooks template and trying to figure out what's actually pulling weight, this V0 starts from **nothing** and will only add bricks with documented ROI.

## Usage

For now, manual. A `bin/create-work` / `bin/create-sub-work` script is planned.

### Classic workspace (with a human)

```bash
# 1. Copy the classic template into a new workspace
cp -r template/ workspaces/my-project/

# 2. Drop your project, data, or task description into inputs/
cp -r ~/some-repo workspaces/my-project/inputs/

# 3. Launch Claude Code from the workspace
cd workspaces/my-project/
claude

# 4. The agent will:
#    - read IDENTITY.md, inputs/
#    - run the 5-requirement alignment in one reply (0-3 questions max)
#    - work autonomously until outputs/ is filled
```

### Sub-workspace (no human, called by a parent agent)

```bash
# Parent agent populates inputs/task.json with a structured contract
cp -r template-sub/ workspaces/sub-task-name/
# (parent writes task.json describing objective, deliverable schema, success criteria)

# Parent then runs:
cd workspaces/sub-task-name/ && claude -p "$(cat inputs/task.json)" \
  --output-format json --max-turns 50 > outputs/result.json
```

Why a separate process and not the `Agent` tool? Because Claude Code's `Agent` tool starts in the parent's cwd and won't load the sub-workspace's `CLAUDE.md` or local skills, and subagents cannot recursively spawn other subagents. A standalone `claude -p` process gets the right `CLAUDE.md` hierarchy, full skill loading, and recursion.

## Design constraints

- **≤ 8 GB RAM** for the workspace alone (rules out massive parallelism)
- **No paid external APIs** — Claude Max subscription only
- **Self-contained** — no dependencies outside the workspace directory
- **Caller-agnostic** — invocable by a human or by a parent Claude Code agent (recursive instantiation)

## Status

V1. Experimental. Public for transparency and feedback.

Future versions (V1, V2, ...) will add bricks one at a time, each justified by a measured improvement on a benchmark we run ourselves (since no public benchmark currently measures "build a complete app from scratch" — see [METR Time Horizon](https://metr.org/time-horizons/) for the closest thing).

## Open questions we're trying to answer

- How do you pose the **k highest-information questions** at t=0 instead of asking k random ones? (active questioning, GATE-style)
- How do you keep intent stable across `/clear` and compaction without paying for it in tokens? (ledger pattern, à la [MitchellkellerLG/claude-workspace-template](https://github.com/MitchellkellerLG/claude-workspace-template))
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
