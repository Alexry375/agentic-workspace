# agentic-workspace — brief agent

> Tu es un agent (Claude Code ou Codex CLI) qui va utiliser ou modifier `agentic-workspace`.
> Lis tout. Plus dense et plus à jour que le README.

## En une phrase

Un seul type de workspace. Une **session main** (interactive, chez l'humain) aligne, écrit `inputs/prompt.md`, lance `aw new`. L'humain ouvre une **session dédiée** dans le workspace (`cd workspaces/<name> && claude`), l'agent bosse en autonomie totale. La main reprend, audite la livraison, écrit le report.

Biais vers la **soustraction** : chaque brick gagne sa place.

## Architecture

```
<repo>/                              ← source canonique
├── bin/aw                           ← CLI
├── install.sh                       ← wizard, écrit ~/.agentic-workspace/config.json
├── shared/
│   ├── procedure-core.md            ← noyau harness-agnostique
│   ├── procedure-claude-tail.md     ← spécifique Claude (Agent tool, skill genius user-level)
│   ├── procedure-codex-tail.md      ← spécifique Codex (subagents en langage naturel)
│   ├── agent-brief.md               ← CE FICHIER (aw context)
│   └── guides/                      ← guides opt-in (cf. plus bas)
└── README.md, LICENSE

~/.agentic-workspace/                ← état per-machine
├── config.json                      {repo_path, reports_path}
└── reports.jsonl                    append-only bilans

~/.claude/                           ← prérequis user-level Claude
├── settings.json                    hook UserPromptSubmit "[GENIUS] ..." actif
└── skills/genius/SKILL.md           skill auto-disponible

~/.agents/skills/genius/SKILL.md     ← prérequis user-level Codex (auto-discovery
                                       depuis ~/.agents/skills/ + .agents/skills/)

$PWD/workspaces/<name>/              ← créé n'importe où par aw new
├── CLAUDE.md                        core + claude-tail concaténés (pas d'@import)
├── AGENTS.md                        core + codex-tail concaténés (pas d'@import)
├── inputs/prompt.md                 spec autoritaire écrite par la main
├── inputs/<autres>                  data, refs
├── outputs/                         livrables de l'agent
├── .started_at, .ended_at           timestamps timer (epoch)
└── .archive                         flag posé par aw archive
```

**Invariant** : un workspace est self-contained (`CLAUDE.md` et `AGENTS.md` inlinés, pas d'`@import`). Le skill `genius` reste au niveau utilisateur de chaque harness (Claude : `~/.claude/skills/genius/` ; Codex : `~/.agents/skills/genius/`).

## Le pivot mental

**Session main** (chez l'humain) :
1. Aligne avec l'humain (questions précises, contexte riche).
2. `aw new <name>` puis remplit `workspaces/<name>/inputs/prompt.md` exhaustivement.
3. Dit à l'humain : *"Lance `cd workspaces/<name> && claude` (ou `codex`) quand tu peux."*
4. À la livraison : **audite adversarialement** (code, métriques, fichiers livrés ≠ `result.md`). Round 2 ciblé via `inputs/round-2.md` si besoin.
5. `aw report <name> "<note>"` (lit `.started_at`/`.ended_at`, écrit duration_seconds).

**Session dédiée (agent workspace)** :
1. `aw start` → lit `inputs/prompt.md` (autoritative) → bosse.
2. `aw end` en dernière action. **N'appelle pas `aw report`** — la main s'en charge.

Pourquoi une session dédiée et pas un sub-agent ? Pour que l'agent du workspace garde accès aux outils complets (Agent tool, sub-agents, etc.) — impossible si lui-même est un sub-agent de la main.

## Project-lab : quand un workspace devient un projet

Un workspace seul (`$PWD/workspaces/<name>/`) suffit pour du **one-shot**.
Mais si son `outputs/` contient un **artefact permanent** qu'on itère pendant
des semaines (une webapp, une lib, un corpus, un site), on **scinde** :

```
<project>-lab/
├── repo/                          ← le code permanent versionné (git/GitHub)
└── workspaces/
    ├── <seed-workspace>/          ← workspace d'origine, gardé pour son inputs/
    │   └── .archive               (typiquement archivé une fois repo/ stable)
    └── <future-task>/             ← workspaces ultérieurs qui contribuent à repo/
```

Règles :

- `repo/` est la cible permanente : son propre git, son propre README, son
  propre déploiement. Survit à toute archive de workspace.
- Les workspaces sont des **contributions scopées** : chacun pose dans
  `outputs/` quelque chose qu'un agent intègre ensuite dans `repo/`.
- Un projet = un `<project>-lab/`. Pas deux artefacts permanents distincts
  sous le même lab (sinon on fork).
- Le seed workspace reste : son `inputs/` est irreproductible. On archive
  via `aw archive`, on ne supprime jamais.
- Naming : `<project>-lab/` (ex. `learning-lab/`, `nexus-lab/`). Le suffixe
  `-lab` signale "ce truc a du code permanent ET des workspaces jetables".

Pas de commande CLI pour scaffolder — c'est une convention de dossiers, pas
un outil. Au moment où tu décides de scinder :
`mkdir <project>-lab/{repo,workspaces}` puis `mv` ce que tu as déjà.

## Commandes (toutes lisibles dans `bin/aw`)

| Commande | Qui appelle | Effet |
|---|---|---|
| `aw new <name>` | main | Crée `$PWD/workspaces/<name>/` avec `inputs/prompt.md` vide à remplir. |
| `aw start` | workspace | Écrit timestamp epoch dans `$PWD/.started_at`. |
| `aw end` | workspace | Écrit timestamp epoch dans `$PWD/.ended_at`. |
| `aw report <name> "<note>"` | main | Append `{ts,name,note,duration_seconds}` à `reports.jsonl`. |
| `aw archive <name>` | main | Touch `.archive`. |
| `aw revive <name>` | main | Remove `.archive`. |
| `aw list [--all\|--archived]` | n'importe | Vivants par défaut. |
| `aw context` | n'importe | Affiche ce brief. |

Pas de registre global. Les workspaces vivent là où tu les as créés.

## État d'un workspace : `.archive`

Source de vérité unique :

```bash
[ -f workspaces/<name>/.archive ] && echo archived || echo live
```

Le nom du dossier ne change **jamais** (sinon historique session Claude à `~/.claude/projects/<chemin-encodé>/` orphelin). Énumère via `aw list`, pas `ls workspaces/`.

## Skill `genius`

Vit au niveau utilisateur de chaque harness, pas dans ce dépôt :

- **Claude** : `~/.claude/skills/genius/SKILL.md` auto-disponible + hook `UserPromptSubmit` dans `~/.claude/settings.json` qui prepende `[GENIUS] ...` à chaque prompt.
- **Codex** : `~/.agents/skills/genius/SKILL.md` (auto-discovery par Codex depuis `~/.agents/skills/`, `.agents/skills/` du repo, `/etc/codex/skills`). Pas de hook équivalent — l'agent doit invoquer la discipline explicitement.

**Edge case sous-agents (délégation intra-session)** : auto-invocation aléatoire sur les deux harnesses. Inclus dans le prompt du sous-agent : *"Avant d'agir, lis et applique le skill `genius` (Claude : `~/.claude/skills/genius/SKILL.md` ; Codex : `~/.agents/skills/genius/SKILL.md`)."*

## Guides opt-in

`shared/guides/` héberge des markdown denses tirés de chantiers passés.
**Pas auto-chargés** ; tu les lis via `Read` *si* la tâche du workspace
correspond au trigger ci-dessous. Pas de frontmatter, pas d'auto-découverte
— l'invitation à charger doit venir d'ici ou de l'humain.

| Guide | Charge si la tâche est |
|---|---|
| `shared/guides/reimplementation-parity.md` | ré-implémenter un système existant sur une autre stack / langage / framework, **ou** absorber le cœur d'un repo upstream en l'adaptant à un autre cas d'usage |

Différence avec un *skill* (`genius`) : le skill vit user-level et est
auto-disponible dans toute session du harness ; un *guide* est confiné au
repo et opt-in. Pruning ≥3 occurrences observées, comme le reste de la
méthode.

## Reports

`aw report <name> "<note>"` ajoute `{ts, name, note, duration_seconds}` à `~/.agentic-workspace/reports.jsonl`. `duration_seconds` est `null` si l'agent du workspace n'a pas appelé `aw start`/`aw end`.

- `name` libre, pas de foreign key — c'est un tag.
- Note : commence par `ok` / `ko` / `partial`, puis texte libre.
- Objectif : corpus pour piloter les rondes de pruning.

## Méthode (si tu modifies le dépôt)

- **Brick admission rule** : un candidat brick rentre dans `procedure-core.md` (ou un tail si harness-spécifique) qu'avec ≥3 occurrences observées. 2 = candidat. 1 = noté, pas embarqué.
- **Soustraction par défaut** : si un brick ne se défend pas après 1-2 sessions, il dégage.
- **Pas de duplication source-de-vérité** : `genius` vit exclusivement au niveau utilisateur de chaque harness. Pas de copie dans ce dépôt.
- **Pas de chemin hardcodé** dans les workspaces. Tout passe par l'inline au moment de `aw new`.

## Référentiels prior art (pas des dépendances)

- `humanlayer/12-factor-agents` — principes de design d'agents
- `princeton-nlp/SWE-agent` — task-loop / scaffolding
- `MineDojo/Voyager` — skill library long-horizon
- `nus-apr/auto-code-rover` — pipeline de réparation de code
- `stanfordnlp/dspy` — programmation de prompts (compilation)
- `obra/superpowers` — collection communautaire de skills Claude Code

## Si tu cherches plus de profondeur

- **`shared/procedure-core.md` + tails** : ce que voit l'agent dans son `CLAUDE.md`/`AGENTS.md` (concaténation au moment du `aw new`).
- **`bin/aw`** : ~200 lignes de bash, pas de magie cachée.
- `git log --oneline` : V0 → V1 → V1.1 → V2 → pivot 2026-06-07.
