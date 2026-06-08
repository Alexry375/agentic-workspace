# agentic-workspace

A minimalist `workspace/` template for autonomous coding agents (Claude Code and Codex CLI). **One workspace type, dedicated interactive sessions.** A **main session** (with the human) aligns, writes `inputs/prompt.md`, runs `aw new`. The human opens a **dedicated session** in the workspace; the agent works autonomously. The main session resumes, adversarially audits the delivery, then files the report.

Workspaces inline their procedure into self-contained `CLAUDE.md` and `AGENTS.md` files (the harness picks whichever it natively reads), so moving or deleting the cloned repo never breaks an existing workspace. The `genius` skill is installed once at each harness's user level and shared across all workspaces.

```
agentic-workspace/
├── bin/aw                              # CLI: new / start / end / report / list / archive / context
├── install.sh                          # wizard: writes ~/.agentic-workspace/config.json
├── shared/
│   ├── procedure-core.md               # harness-agnostic core (inlined by aw new)
│   ├── procedure-claude-tail.md        # Claude-specific tail (concatenated into CLAUDE.md)
│   ├── procedure-codex-tail.md         # Codex-specific tail (concatenated into AGENTS.md)
│   ├── agent-brief.md                  # dense brief printed by `aw context`
│   └── guides/                         # opt-in domain guides
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

Move the repo? Re-run `./install.sh` from the new location to refresh `repo_path`.

Requirements: `bash`, `jq`, and [Claude Code](https://docs.claude.com/en/docs/claude-code) in `PATH`.

## Usage

### Main session — create & cadre

In your interactive Claude session, ask the agent to align with you (questions are sharper because main has full context), then:

```bash
aw new my-project                      # creates ./workspaces/my-project/
# main fills workspaces/my-project/inputs/prompt.md exhaustively
```

### Dedicated session — execute

You launch a fresh Claude session inside the workspace:

```bash
cd workspaces/my-project
claude
```

The agent calls `aw start` (timer), reads `inputs/prompt.md` as the authoritative spec, works autonomously, writes `outputs/`, then `aw end` as its very last action. **No human Q&A** in this session.

Why a dedicated session and not a sub-agent of main? So the workspace agent keeps full tool access (Agent tool, sub-agents, etc.) — which it would lose as a sub-agent.

### Main session — audit & report

Back in main, you ask the agent to read `workspaces/my-project/outputs/` directly (not the summary), critically audit the delivery (circular metrics, silently-abandoned criteria, edge cases unchecked, auto-audits that *rename* problems instead of fixing them — cf. `uk_clml` 2026-05-14), trigger a round 2 via `inputs/round-2.md` if needed, then:

```bash
aw report my-project "ok — built, tested, audited"
aw report my-project "ko — circular metric, round 2 dispatched"
aw report my-project "partial — main feature works, secondary skipped per scope"
```

Appends a JSON line `{ts, name, note, duration_seconds}` to `~/.agentic-workspace/reports.jsonl`. `duration_seconds` comes from the timestamps the workspace agent wrote via `aw start`/`aw end`. Note convention: `ok` / `ko` / `partial` prefix, free text after.

### List workspaces

```bash
aw list                  # live workspaces only (default)
aw list --all            # everything, with STATUS column
aw list --archived       # only archived
```

No global registry — workspaces live under `$PWD/workspaces/` wherever you ran `aw new`. By design.

### Archive a workspace

```bash
aw archive my-project    # touch workspaces/my-project/.archive
aw revive  my-project    # rm  workspaces/my-project/.archive
```

The folder name never changes — only a `.archive` flag file is added. Renaming would orphan the Claude Code session history (keyed by absolute path under `~/.claude/projects/`).

Check from a script:

```bash
[ -f workspaces/<name>/.archive ] && echo archived || echo live
```

`aw list` filters archived by default so agents never see hundreds of dormant workspaces.

## The `genius` skill (per-harness, user-level)

The skill lives once per harness, outside this repo. `aw new` does not copy it.

- **Claude Code** — `~/.claude/skills/genius/SKILL.md` auto-discovered every session, **plus** a `UserPromptSubmit` hook in `~/.claude/settings.json` that prepends `[GENIUS] ...` to every prompt.
- **Codex CLI** — `~/.agents/skills/genius/SKILL.md` auto-discovered via Codex's skill scan (`~/.agents/skills/`, `.agents/skills/` in the repo, `/etc/codex/skills`). No hook equivalent; the procedure tells the agent to invoke the discipline explicitly.

**Sub-agents edge case.** Auto-invocation of `genius` inside sub-agents is unreliable on both harnesses. When you spawn one on a non-trivial task, include in its prompt: *"Before acting, read and apply the `genius` skill (Claude: `~/.claude/skills/genius/SKILL.md`; Codex: `~/.agents/skills/genius/SKILL.md`)."*

## Project-lab pattern (when a workspace outgrows itself)

A single workspace under `$PWD/workspaces/<name>/` is the right shape for **one-shot work** — fill `inputs/prompt.md`, run `claude`, harvest `outputs/`. But sometimes a workspace produces a non-disposable artifact: a webapp, a library, a paper, a corpus that you keep iterating on for weeks. Once that artifact is bigger than the workspace that birthed it, **split**:

```
<project>-lab/
├── repo/                              ← permanent code / artifact, versioned (git, GitHub…)
│   ├── (whatever the project is — Next.js app, Python package, docs site…)
│   └── README.md, ARCHITECTURE.md, CONTRIBUTING.md
└── workspaces/
    ├── <seed-workspace>/              ← the original one-shot, kept for its inputs/ corpus
    │   ├── inputs/ outputs/ CLAUDE.md AGENTS.md
    │   └── .archive                   ← typically archived once repo/ is stable
    └── <future-task>/                 ← later: a sub-task that contributes to repo/
        ├── inputs/ outputs/ CLAUDE.md AGENTS.md
        └── ...
```

The rationale:

- **`repo/` is the permanent target.** It has its own git history, its own README, its own deploy. It survives every workspace being archived.
- **`workspaces/` are scoped contributions.** Each one delivers something into `outputs/` that an agent then folds into `repo/` (a feature, a refactor, a content batch, a research note). The workspace stays around for its inputs and audit trail, but the diff is what matters.
- **One project = one `<project>-lab/`.** Don't mix multiple permanent artifacts under one lab. If your single repo grows two distinct deliverables, fork the lab.
- **The seed workspace stays.** It's where the project's `inputs/` corpus (scraped data, original spec) lives. Archive it with `aw archive` once repo/ is self-sufficient, but never delete it — its `inputs/` is irreproducible by the agent alone.

Naming: stick to `<project>-lab/` (e.g. `learning-lab/`, `nexus-lab/`, `research-lab/`). The `-lab` suffix signals "this is a project with permanent code AND throwaway workspaces", not just a single one-shot.

There is no CLI command to scaffold a project-lab — it's a folder convention, not a tool. When the moment comes, just `mkdir <project>-lab/{repo,workspaces}` and `mv` what you already have.

## Design constraints

- **≤ 8 GB RAM** for the workspace alone (rules out massive parallelism)
- **No paid external APIs** — Claude Max subscription only
- **Self-contained procedure** — each workspace ships its own `CLAUDE.md` (procedure inlined). No hard dependency on the cloned repo path at runtime, only at `aw new` time. `genius` is the one exception: sourced from `~/.claude/skills/`.
- **Caller-agnostic** — invocable by a human or by another Claude Code agent

## Status

Post-pivot 2026-06-07. Single workspace type, main/dedicated split, timers. Public for transparency and feedback.

## Related work

- [walkinglabs/learn-harness-engineering](https://github.com/walkinglabs/learn-harness-engineering)
- [ai-boost/awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering)
- [HumanLayer 12-factor agents](https://github.com/humanlayer/12-factor-agents)
- [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [SWE-agent / mini-swe-agent](https://github.com/SWE-agent/mini-swe-agent)

## License

MIT
