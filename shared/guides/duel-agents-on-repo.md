# Duel d'agents sur un repo de code — workspace aw + git worktree

> Charge ce guide quand la tâche est :
> **monter N agents en parallèle (duel, ou simple fan-out) qui MODIFIENT le même
> dépôt de code** et dont on veut ensuite **merger proprement la meilleure
> livraison**.
>
> Ne le charge pas pour du one-shot isolé qui ne touche pas un repo versionné
> (un workspace aw nu suffit alors).
>
> Source : retex trade-center 2026-06 (duels WS2 `operator-quota-governor` à 2,
> WS3 `operator-liveness` à 4). Densité maximale, règles actionnables.

## La tension de départ

`aw new` crée un **dossier de brief** (`CLAUDE.md`, `AGENTS.md`, `inputs/`,
`outputs/`) — **pas** une copie git du repo à modifier. Or pour qu'un agent
**code et commit** sur sa propre branche, puis qu'on **merge le gagnant sans
friction**, il faut un **git worktree** : un 2ᵉ (3ᵉ, …) dossier de travail
branché sur le même `.git`, chacun sur sa branche, checkout en parallèle.

Le réflexe « clone séparé par agent » marche mais coûte cher : 4× l'historique,
et merger le gagnant oblige à rajouter un remote / cherry-pick. Le réflexe
« worktree nu, pas de aw » marche aussi mais jette tout l'outillage aw (timer,
`outputs/`, procédure anti-shortcut, double fichier d'instructions). **La bonne
réponse marie les deux.**

## La topologie recommandée : `repo/` imbriqué dans le workspace

```
workspaces/<name>-A/            ← aw new : CLAUDE.md + AGENTS.md + inputs/prompt.md + outputs/
  repo/                          ← git worktree (branche feat/<name>-A) : le code, là où l'agent commit
workspaces/<name>-B/ …C/ …D/    ← idem, une branche par agent
```

L'agent lance `cd workspaces/<name>-A && claude` (ou `codex`) : il lit le
`CLAUDE.md` de procédure aw + `inputs/prompt.md` (la spec), **code dans `repo/`**,
commit sur sa branche, dépose sa synthèse dans `outputs/`. Le merge du gagnant se
fait depuis `repo/` (`git merge feat/<name>-X` côté dépôt principal).

Pourquoi cette topologie et pas un workspace aw + worktree côte-à-côte (deux
endroits séparés) : l'agent n'a qu'**un** point d'entrée (`cd workspaces/<name>`),
le code est un sous-dossier explicite, et `aw report`/`aw archive` opèrent
nativement sur le workspace.

## Recette pas-à-pas

Depuis le parent qui contient `workspaces/` :

```bash
aw new <name>-A                                   # crée workspaces/<name>-A/ (brief + inputs/outputs)
git -C <repo> worktree add \
    <abs>/workspaces/<name>-A/repo -b feat/<name>-A   # le code dans repo/, branche dédiée
cp spec.md workspaces/<name>-A/inputs/prompt.md   # ta spec, IDENTIQUE entre agents
( cd workspaces/<name>-A/repo && uv sync )        # venv propre à CE worktree (cf. piège plus bas)
```

Répète par agent. La spec dans `inputs/prompt.md` doit porter **une note de
localisation** (sinon l'agent code à la racine du workspace, pas dans `repo/`) :

> *« Le code à modifier est dans `./repo/` (git worktree déjà sur ta branche).
> Commits-y, sur la branche checkout — ne change pas de branche, ne touche pas
> master. Venv : `./repo/.venv`. »*

## Ce que le worktree isole — et ce qu'il n'isole PAS

- **Isole** : les fichiers de travail. Agent A ne voit pas les modifs non
  committées de B.
- **N'isole PAS** : le `.git` est **commun**. Les branches des voisins
  (`feat/<name>-B`…) sont **visibles** via git depuis n'importe quel worktree.
  Le worktree **range** les voisins, il ne les **cache** pas.

En pratique le risque « l'agent va fouiller chez le voisin » est quasi nul : son
`inputs/prompt.md` ne nomme aucune autre branche, il ignore qu'elles existent, et
son instinct est de résoudre SA tâche. Si tu veux fermer même ce résidu : garde la
spec muette sur les autres agents + une ligne *« ne consulte aucune autre branche
ni worktree git »*. Pour une étanchéité **dure** (rare), passe aux clones séparés
ou aux users OS distincts — mais c'est rarement justifié pour un duel de dev.

## Spécial duel à l'aveugle

- **Le double `CLAUDE.md` + `AGENTS.md` généré par `aw new` est un atout** : le
  fichier d'instructions ne trahit plus le harness (Claude lit l'un, Codex l'autre,
  mais **les deux sont présents partout**). Sans aw, un seul des deux traînerait et
  signerait l'agent.
- **Impose des conventions anti-tells dans `inputs/prompt.md`** (identiques pour
  tous) : une seule langue de code/commentaires, commits au format neutre sans
  trailer nommant un modèle, pas d'emoji, interdiction de créer un autre fichier
  d'instructions signant l'outil.
- **L'auditeur s'engage sur la note AVANT de connaître le mapping** lettre→agent.
  Le canal de fuite dominant n'est pas git, c'est l'auditeur qui pourrait lire les
  transcripts hors-arbre (`~/.claude/projects/<hash-cwd>/`) ou `~/.codex/` :
  discipline = n'auditer que le diff de code.

## Pièges (tous rencontrés)

1. **Le venv n'est PAS partagé entre worktrees** et casse au déplacement (chemins
   absolus dans les scripts/`pyvenv.cfg`). Après tout `git worktree move`,
   **re-`uv sync`** (cache chaud = rapide). `.venv/bin/python -m pytest` survit en
   général (le `python` est un symlink système), mais sync de toute façon.
2. **Deux `CLAUDE.md` distincts, ne les confonds pas** : celui du workspace
   (procédure aw, à la racine) et celui du **projet** (dans `repo/`). Ils se
   **cumulent** (nested), c'est voulu — n'écrase jamais le `CLAUDE.md` projet.
3. **Retire le doublon de spec** : si tu copies la spec en `repo/TASK.md` *et*
   en `inputs/prompt.md`, supprime l'un. Source unique = `inputs/prompt.md`.
4. **Spec strictement identique entre agents**, au md5 près. Seules tolérées : les
   différences techniques inévitables (nom de branche, port). Une amorce
   d'instructions plus musclée pour un agent fausse la comparaison.
5. **Au merge, exclus les méta du workspace** (`inputs/`, `outputs/`, `RAPPORT.md`,
   `TASK.md`) : ne ramène sur `master` que le **diff de code** de la branche
   gagnante (`git checkout feat/<name>-X -- <fichiers de code>` puis commit).
6. **Mesure le plancher de non-régression dans chaque `repo/` avant lancement**
   (`pytest`) : c'est le point de comparaison de fin.
