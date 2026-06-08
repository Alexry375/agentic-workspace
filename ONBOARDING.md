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

| Version          | Notes                                                  |
|------------------|--------------------------------------------------------|
| V0               | 5-file skeleton baseline                               |
| V1               | Split into `shared/procedure.md` + `template/`         |
| V1.1             | Bricks distilled from a real prompt corpus             |
| V2               | Self-contained workspaces, reports.jsonl, hook toggle  |
| Pivot 2026-06-07 | One workspace type, main/dedicated split, timers       |

Run `git log --oneline` for the full history.

**Architecture (post-pivot):**
```
agentic-workspace/
├── bin/aw                              # CLI
├── install.sh                          # wizard
├── shared/
│   ├── procedure-core.md               # harness-agnostic core (inlined by aw new)
│   ├── procedure-claude-tail.md        # Claude-specific (Agent tool, user-level skill+hook)
│   ├── procedure-codex-tail.md         # Codex-specific (subagents via natural language)
│   ├── agent-brief.md                  # dense brief, printed by `aw context`
│   └── guides/                         # opt-in domain guides
├── ONBOARDING.md, README.md, LICENSE
```

Per-user state lives in `~/.agentic-workspace/`:
- `config.json` — `{repo_path, reports_path}` written by install.sh
- `reports.jsonl` — append-only bilans from `aw report` (with `duration_seconds`)

The `genius` skill lives at the user level of each harness:
`~/.claude/skills/genius/` for Claude (paired with a `UserPromptSubmit` hook
in `~/.claude/settings.json`) and `~/.agents/skills/genius/` for Codex
(auto-discovered, no hook). Workspaces rely on that user-level install —
`aw new` does not copy the skill.

Workspaces are created at `$PWD/workspaces/<name>/` by `aw new`. The procedure
is **inlined** into both `CLAUDE.md` (core + claude-tail) and `AGENTS.md`
(core + codex-tail) — no `@import`, so moving or deleting the cloned repo
does not break existing workspaces.

## Le pivot 2026-06-07

Anciennement deux types (workspace top-level / sub-workspace). Maintenant un seul.

**Flow standard** :
1. **Session main** (interactive, chez Alexis) : aligne avec l'humain, `aw new <name>`, remplit `inputs/prompt.md`.
2. **Session dédiée** (`cd workspaces/<name> && claude`) : agent appelle `aw start`, bosse en autonomie, `aw end` à sa dernière action. **N'appelle pas `aw report`.**
3. **Session main reprend** : audit adversarial des outputs (jamais juste `result.md`), `aw report <name> "<note>"` qui calcule `duration_seconds = ended_at - started_at` et écrit dans `reports.jsonl`.

Pourquoi une session dédiée et pas un sub-agent de main ? Pour que l'agent du workspace garde accès aux outils complets (Agent tool, sub-agents) — perdus si lui-même est sub-agent.

L'agent ne crée pas de workspace enfant : ça casserait l'autonomie (il faudrait que la main lance une nouvelle session dédiée). Pour du lourd intra-tâche, il délègue dans sa propre session.

## Read these first

1. `README.md`
2. `shared/procedure-core.md` (+ `procedure-claude-tail.md` ou `procedure-codex-tail.md`) — ce que voit l'agent dans son `CLAUDE.md` / `AGENTS.md`
3. `shared/agent-brief.md` — référence pour les agents qui touchent au méta-repo
4. `bin/aw` — générateur, ~200 lignes de bash
5. `~/.claude/skills/genius/SKILL.md` (ou `~/.agents/skills/genius/SKILL.md` côté Codex) — vit hors repo

## Method already established (don't re-litigate without a strong signal)

- **Audit critique par la main à la livraison** : la main lit directement les artefacts du workspace, jamais juste son résumé. Cherche métriques tautologiques, critères abandonnés silencieusement, auto-audits qui renomment au lieu de traiter. Incident fondateur : `uk_clml_implementation` 2026-05-14.
- **Timer split** : agent du workspace fait `aw start`/`aw end` ; main fait `aw report`. Trois commandes distinctes, séparation de responsabilités claire.
- **Délégation intra-session** = sub-task dans la même session. Claude : tool `Agent`. Codex : demande explicite en langage naturel (`spawn N subagents...`). Le sous-agent rend un résumé structuré, transcript non persisté. **Pas de workspace enfant** — incohérent avec l'autonomie (forcerait une nouvelle session humaine).
- **`genius` au niveau user de chaque harness** : Claude `~/.claude/skills/genius/` + hook `UserPromptSubmit` ; Codex `~/.agents/skills/genius/` (pas de hook). Pas de copie dans le repo.
- **Self-containment du workspace** (procédure seulement) : `aw new` inline core + tail. End users never see `shared/`. Le skill n'est **pas** copié.
- **Brick admission rule** : ≥3 occurrences dans des prompts réels avant d'embarquer dans `procedure-core.md`.

## Reference repos worth a look

Prior art, pas des dépendances :

- `humanlayer/12-factor-agents`
- `princeton-nlp/SWE-agent`
- `MineDojo/Voyager`
- `nus-apr/auto-code-rover`
- `stanfordnlp/dspy`
- `obra/superpowers`

## Conceptual backlog

1. **Valider le pivot sur une vraie tâche** : flow main → dédiée → audit + report, voir si le split timer/report tient en pratique.
2. **Auto-capture des prompts** depuis `~/.claude/projects/*.jsonl` post-session.
3. **Survey templates Claude Code publics** (pattern `thoughts/ledgers/` qui survit à `/clear`).
4. **Re-prune** à n=20, n=50, n=100 reports.

## Personal overlay

Si tu utilises ce repo comme template quotidien, drop un `ONBOARDING.local.md` à côté (gitignored).

## Tone

Tight iterative pruning. Defend your choices when challenged, cut without sentiment when a brick fails to earn its place. No filler, no sycophancy.
