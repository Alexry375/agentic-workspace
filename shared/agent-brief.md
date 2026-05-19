# agentic-workspace — brief pour Claude Code

> Tu es un agent Claude Code qui va utiliser ou modifier `agentic-workspace`.
> Lis tout. C'est plus dense et plus à jour que le README.

## En une phrase

`agentic-workspace` est un template minimaliste de workspaces pour Claude Code.
Une CLI (`aw`) crée des workspaces auto-suffisants à partir d'une procédure
canonique. Chaque brick (skill, hook, instruction) doit gagner sa place :
biais vers la **soustraction**, pas l'accumulation.

## Architecture

```
<repo>/                              ← côté dev, source canonique
├── bin/aw                           ← CLI (new / report / list / context / help)
├── install.sh                       ← wizard, écrit ~/.agentic-workspace/config.json
├── shared/
│   ├── procedure.md                 ← workspace top-level (inlinée par aw new)
│   ├── procedure-sub.md             ← sub-workspace (inlinée par aw new --sub)
│   ├── agent-brief.md               ← CE FICHIER, sorti par aw context
│   └── skills/genius/SKILL.md       ← skill canonique, à synchroniser avec ~/.claude/
└── README.md, LICENSE

~/.agentic-workspace/                ← état per-machine
├── config.json                      {repo_path, reports_path}
└── reports.jsonl                    append-only bilans

~/.claude/                           ← niveau utilisateur, prérequis
├── settings.json                    hook UserPromptSubmit "[GENIUS] ..." actif
└── skills/genius/SKILL.md           skill canonique, auto-disponible

$PWD/workspaces/<name>/              ← créé n'importe où par aw new
├── CLAUDE.md                        procedure inlinée (pas d'@import)
├── inputs/                          contenu utilisateur / spec
└── outputs/                         livrables de l'agent
```

**Invariant clé** : un workspace est self-contained pour sa procédure (CLAUDE.md
inliné, pas d'`@import`). Déplacer ou supprimer le dépôt ne casse aucun
workspace existant. Le skill `genius` est en revanche au niveau utilisateur,
donc le workspace présume un setup `~/.claude/skills/genius/` actif.

## Les commandes (toutes lisibles dans `bin/aw`)

| Commande | Effet |
|---|---|
| `aw new <name>` | Crée `$PWD/workspaces/<name>/` avec `procedure.md` inlinée. |
| `aw new <name> --sub` | Sub-workspace : `procedure-sub.md` inlinée + `inputs/prompt.md` vide. |
| `aw report <name> "<note>"` | Append `{ts,name,note}` dans `reports.jsonl`. Nom libre. |
| `aw archive <name>` | Marque le workspace comme terminé (touch `.archive`). |
| `aw revive <name>` | Annule l'archivage (rm `.archive`). |
| `aw list` | Liste les workspaces **vivants seulement** (par défaut). |
| `aw list --all` | Tout, avec colonne STATUS (live/archived). |
| `aw list --archived` | Seulement les archivés. |
| `aw context` | Affiche ce brief. |
| `aw help` | Aide courte. |

Pas de registre global de workspaces. Ils vivent là où tu les as créés. C'est
voulu.

## État d'un workspace : la convention `.archive`

Pour savoir si un workspace est encore d'actualité, **regarde si le fichier
`.archive` existe à sa racine**. C'est la seule source de vérité :

```bash
[ -f workspaces/<name>/.archive ] && echo archived || echo live
```

- Présent ⇒ archivé (humain a confirmé que c'est terminé / plus utile).
- Absent ⇒ vivant.

Le nom du dossier ne change **jamais** (sinon l'historique de session Claude
Code à `~/.claude/projects/<chemin-encodé>/` se retrouve orphelin). Le flag
`.archive` est la seule mutation. Pour énumérer ce qui est encore actif :
**utilise `aw list`, pas `ls workspaces/`** — `aw list` filtre les archivés
par défaut, `ls` n'a aucun signal.

## Workspace vs sub-workspace

Le flag `--sub` n'est pas cosmétique, il change la procédure inlinée :

- **Top-level** (`procedure.md`) : aligne avec l'humain via 5 questions au boot,
  travaille de manière autonome jusqu'à remplir `outputs/`, peut déléguer.
- **Sub** (`procedure-sub.md`) : lit `inputs/prompt.md` comme spec autoritaire,
  **pas** de questions à l'humain, **pas** de re-délégation, retour structuré
  obligatoire dans `outputs/result.md` (Done / Not done / Verification /
  Adjacent work).

## Délégation : deux patterns, jamais de récursion

- **Pattern A — outil `Agent` intra-session.** Pour une sous-tâche dont tu
  veux juste le résultat structuré (Explore, Plan, audit, analyse parallèle).
  Le sous-agent renvoie un résumé, son transcript n'est pas persisté.
- **Pattern B — `aw new <child> --sub`.** Pour du lourd (>30 min, dépendances
  distinctes) qui mérite sa propre session. Tu remplis
  `workspaces/<child>/inputs/prompt.md`, et tu demandes à l'humain de lancer
  `cd workspaces/<child> && claude`.

**Jamais de `claude -p` récursif.** Coût, perte de visibilité, contrôle bancal.

## Hook & skill « genius »

Les deux sont actifs en permanence au niveau utilisateur.

- **Le skill** vit à `~/.claude/skills/genius/SKILL.md` (source canonique pour
  cet utilisateur) et est synchronisé avec `shared/skills/genius/SKILL.md` dans
  ce dépôt. Il est auto-disponible dans toute session `claude` de l'utilisateur,
  workspace ou pas. `aw new` **ne copie plus** le skill localement.
- **Le hook** `UserPromptSubmit` dans `~/.claude/settings.json` prepende
  `[GENIUS] ...` à chaque prompt, sans condition.

**Edge case sous-agents.** Un sous-agent (`Agent` tool) auto-découvre les
skills via leur description, mais l'auto-invocation de `genius` n'est pas
fiable (sa description cible l'investigation, pas tout). Discipline obligatoire :
quand tu spawn un sous-agent sur une sous-tâche non triviale, inclus dans son
prompt : *"Avant d'agir, lis et applique `~/.claude/skills/genius/SKILL.md`."*
Le sous-agent partage le filesystem du parent, ce path résout toujours.

## Guides opt-in

`shared/guides/` héberge des markdown denses tirés de chantiers passés.
**Pas auto-chargés** ; tu les lis via `Read` *si* la tâche du workspace
correspond au trigger ci-dessous. Pas de frontmatter, pas d'auto-découverte
— l'invitation à charger doit venir d'ici ou de l'humain.

| Guide | Charge si la tâche est |
|---|---|
| `shared/guides/reimplementation-parity.md` | ré-implémenter un système existant sur une autre stack / langage / framework, **ou** absorber le cœur d'un repo upstream en l'adaptant à un autre cas d'usage |

Différence avec `shared/skills/` : un *skill* est synchronisé avec
`~/.claude/skills/` et auto-disponible partout (cf. `genius`) ; un *guide*
est confiné au repo et opt-in. Pruning ≥3 occurrences observées, comme le
reste de la méthode.

## Reports

`aw report <name> "<note>"` ajoute une ligne JSON
`{ts, name, note}` à `~/.agentic-workspace/reports.jsonl`.

- `name` est **libre**, pas de validation, pas de foreign key vers un
  workspace existant. C'est un tag.
- La convention de note : commencer par `ok`, `ko` ou `partial`, puis du texte
  libre. Exemple : `aw report nexus "ok — déployé sans intervention"`.
- Objectif : nourrir un corpus qui drive les futures rondes de pruning.

## Méthode (à respecter si tu modifies le dépôt)

- **Brick admission rule** : un candidat brick ne rentre dans
  `procedure.md` qu'avec ≥3 occurrences observées dans des prompts réels.
  2 = candidat. 1 = noté, pas embarqué.
- **Soustraction par défaut** : si un brick ne se défend pas après 1-2
  sessions d'usage, il dégage.
- **Pas de duplication source-de-vérité** : le skill `genius` a deux copies
  (`shared/skills/genius/` dans le repo, `~/.claude/skills/genius/` côté
  utilisateur). Elles doivent être synchronisées manuellement (cp depuis le
  repo après modification). C'est le user-level qui est exécuté.
- **Pas de chemin hardcodé** dans les workspaces. Tout passe par le mécanisme
  d'inline au moment de `aw new`.

## Backlog conceptuel (non urgent)

1. Valider V2 sur une vraie tâche (collecter `aw report`, voir si le corpus
   produit du signal).
2. Auto-capture des prompts depuis `~/.claude/projects/*.jsonl` post-session.
3. Survey des templates Claude Code publics (notamment le pattern
   `thoughts/ledgers/` qui survit à `/clear`).
4. Re-prune à n=20, n=50, n=100 reports.

## Référentiels prior art (pas des dépendances)

- `humanlayer/12-factor-agents` — principes de design d'agents
- `princeton-nlp/SWE-agent` — task-loop / scaffolding
- `MineDojo/Voyager` — skill library long-horizon
- `nus-apr/auto-code-rover` — pipeline de réparation de code
- `stanfordnlp/dspy` — programmation de prompts (compilation)
- `obra/superpowers` — collection communautaire de skills Claude Code

## Si tu cherches plus de profondeur

- Lire **`shared/procedure.md`** et **`shared/procedure-sub.md`** : c'est ce
  que voient tes futurs agents dans leur `CLAUDE.md`.
- Lire **`bin/aw`** : ~180 lignes de bash, pas de magie cachée.
- `git log --oneline` : V0 → V1 → V1.1 → V2, l'évolution est traçable.
