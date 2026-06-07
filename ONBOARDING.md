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
│   ├── procedure.md                    # unique workspace procedure (inlined by aw new)
│   ├── agent-brief.md                  # dense brief, printed by `aw context`
│   └── skills/genius/SKILL.md          # canonical genius, sync target for ~/.claude/
├── ONBOARDING.md, README.md, LICENSE
```

Per-user state lives in `~/.agentic-workspace/`:
- `config.json` — `{repo_path, reports_path}` written by install.sh
- `reports.jsonl` — append-only bilans from `aw report` (with `duration_seconds`)

The `genius` skill and its `UserPromptSubmit` hook are at the user level
(`~/.claude/skills/genius/` and `~/.claude/settings.json`), both unconditional.
Workspaces rely on that user-level install — `aw new` does not copy the skill.

Workspaces are created at `$PWD/workspaces/<name>/` by `aw new`. The procedure
is **inlined** into `CLAUDE.md` (no `@import`), so moving or deleting the
cloned repo does not break existing workspaces.

## Le pivot 2026-06-07

Anciennement deux types (workspace top-level / sub-workspace). Maintenant un seul.

**Flow standard** :
1. **Session main** (interactive, chez Alexis) : aligne avec l'humain, `aw new <name>`, remplit `inputs/prompt.md`.
2. **Session dédiée** (`cd workspaces/<name> && claude`) : agent appelle `aw start`, bosse en autonomie, `aw end` à sa dernière action. **N'appelle pas `aw report`.**
3. **Session main reprend** : audit adversarial des outputs (jamais juste `result.md`), `aw report <name> "<note>"` qui calcule `duration_seconds = ended_at - started_at` et écrit dans `reports.jsonl`.

Pourquoi une session dédiée et pas un sub-agent de main ? Pour que l'agent du workspace garde accès aux outils complets (Agent tool, sub-agents) — perdus si lui-même est sub-agent.

Récursion autorisée : un workspace peut créer son propre enfant (et porte la même responsabilité d'audit critique à la livraison).

## Read these first

1. `README.md`
2. `shared/procedure.md` — ce que voit l'agent dans son `CLAUDE.md`
3. `shared/agent-brief.md` — référence pour les agents qui touchent au méta-repo
4. `bin/aw` — générateur, ~200 lignes de bash
5. `shared/skills/genius/SKILL.md`

## Method already established (don't re-litigate without a strong signal)

- **Audit critique par la main à la livraison** : Pattern B step 4 de `procedure.md`. Lis directement les artefacts du workspace, jamais juste son résumé. Cherche métriques tautologiques, critères abandonnés silencieusement, auto-audits qui renomment au lieu de traiter. Incident fondateur : `uk_clml_implementation` 2026-05-14.
- **Timer split** : agent du workspace fait `aw start`/`aw end` ; main fait `aw report`. Trois commandes distinctes, séparation de responsabilités claire.
- **Pattern A (Agent tool)** = intra-workspace sub-task. Le sous-agent rend un résumé structuré, transcript non persisté.
- **Pattern B (`aw new <child>`)** = workspace enfant pour du lourd isolé. Récursion autorisée (différence avec la version pré-pivot). **Pas de `claude -p` récursif.**
- **Skill priority** = `Enterprise > Personal > Project`. `genius` vit une fois au niveau user (`~/.claude/skills/genius/`) ; `shared/skills/` est la source canonique de sync.
- **Self-containment du workspace** (procédure seulement) : `aw new` inline. End users never see `shared/`. Le skill n'est **pas** copié.
- **Hook inconditionnel** : `~/.claude/settings.json` prepende `[GENIUS] ...` à chaque prompt.
- **Brick admission rule** : ≥3 occurrences dans des prompts réels avant d'embarquer dans `procedure.md`.

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
