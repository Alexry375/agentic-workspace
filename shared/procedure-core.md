# Procédure workspace

Tu es l'agent de ce workspace. `inputs/` est le contrat : scellé, hashé, lecture
seule. Aucun humain ne répondra en cours de route. La main auditera ta livraison
en ré-exécutant `inputs/checks/` **plus des vérifications que tu ne verras
jamais**, et en lisant ton code. Le seul moyen de tout passer : faire réellement
le travail demandé, par le chemin demandé.

## Boot

1. `aw start`. S'il affiche REPRISE : lis `outputs/journal.md` §Reprise, vérifie
   l'état annoncé, continue. S'il refuse : copie son message dans
   `outputs/blocked.md`, termine.
2. Lis `inputs/prompt.md` en entier, puis le reste d'`inputs/`. Lance `aw check` :
   l'état initial attendu est rouge. Spec incomplète ou contradictoire →
   `outputs/blocked.md`, termine. Ne devine pas l'intention de la main.
3. Charge la discipline `genius` (bloc harness en fin de fichier).

## ALWAYS

- Après chaque étape coûteuse : `aw check`. Un vert qui repasse rouge = stop and fix.
- Chaque ligne livrée se justifie par un done-criterion du prompt (diff minimal).
- Avant toute action destructive ou dépendance externe : probe de 30 s — le tool
  répond ? le format réel correspond ? le prérequis existe ?
- Toute métrique rapportée a une référence indépendante : baseline triviale,
  oracle disjoint du code mesuré, ou éval annotée. Sinon écris « non mesuré ».
- `journal.md` §Decision Log : toute décision non triviale et toute divergence vs
  `prompt.md`, **au moment où tu la prends** — pas au bilan. §Reprise : toujours à
  jour (état exact + prochaine action) — ta session peut mourir à tout moment.

## NEVER

- Faire passer un check en contournant l'intention : stub étiqueté, valeur en
  dur, config construite mais inutilisée, test sur un état ou un timing que le
  déploiement réel ne produit pas tout seul. « via X » = X réellement exécuté,
  prouvé.
- Modifier `inputs/`, `CLAUDE.md` ou `AGENTS.md` (hashés — détection certaine).
  Besoin d'une copie modifiable → `outputs/work/`.
- Élargir le scope : travail adjacent → `result.md` §Adjacent work, non exécuté.
- Insister plus de 2 fois sur le même blocage → `outputs/blocked.md` (essayé /
  manque / 2-3 options avec conséquence), une seule fois, puis termine. Un échec
  déclaré est une livraison valide ; un succès maquillé non.

## Livraison

1. `aw check` final vert — ou échec honnête déclaré.
2. Tâche longue (>2 h) ou à invariants : fais relire ta livraison par un
   sous-agent adversarial (code, archi, cadrage) avant le check final.
3. Relis `prompt.md` ligne à ligne contre ta livraison : chaque divergence →
   `result.md` §Not done (« aucune » explicite sinon).
4. `outputs/result.md` : `## Done` (chaque bullet cite son check) · `## Not done`
   · `## Verification` (commandes exactes + sorties attendues) · `## Adjacent
   work` (optionnel).
5. `aw end` en toute dernière action. N'appelle jamais `aw report` — c'est le
   travail de la main, après audit.
