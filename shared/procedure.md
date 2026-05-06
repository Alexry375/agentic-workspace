# Procédure commune

## Pendant l'exécution

- **Skill `genius`** : il est chargé automatiquement (`.claude/skills/genius/SKILL.md`).
  Applique-le sur toute affirmation factuelle, hypothèse, et claim de complétion.
- **`inputs/` est en lecture seule.** Si tu dois travailler sur une copie, copie
  vers `outputs/work/`.

## Sous-tâches

Deux patterns selon la nature de la sous-tâche :

### Pattern A — Agent tool (intra-workspace)

Pour Explore, Plan, recherche, audit, sous-problème de la tâche en cours :
utilise le tool `Agent`. Tu peux pré-charger un skill dans le sub-agent via
le frontmatter `skills: [genius]` d'une définition d'agent dans
`.claude/agents/<name>.md`. Le sub-agent retourne un **résumé structuré** que
tu intègres à ton contexte — c'est ta compaction implicite.

### Pattern B — Workspace dédié pour l'humain (sous-tâche lourde)

Si une sous-tâche mérite vraiment sa propre session Claude Code complète
(état très isolé, plusieurs dizaines de minutes de travail, dépendances
distinctes), **ne pas tenter de la lancer toi-même** (pas de `claude -p`,
pas de récursion). À la place :

1. Crée un sous-dossier `workspaces/<name>/` à partir du `template/` du repo.
2. Dépose dans `workspaces/<name>/inputs/prompt.md` un prompt clair et
   complet : objectif, contexte minimal, critères de succès, contraintes.
3. Indique à l'humain dans ta réponse : *"J'ai préparé un workspace dédié
   à cette sous-tâche. Lance `cd workspaces/<name> && claude` quand tu peux,
   le prompt est dans `inputs/prompt.md`."*

L'humain reste dans la boucle pour ces cas lourds, mais le coût est minime
(juste lancer une commande). Le nouvel agent verra le prompt préparé et
pourra zapper la plupart des questions d'alignement.

## Gestion du contexte

- **Sub-agents-first** : pour toute exploration lourde (lecture massive,
  recherche multi-fichier, brainstorming d'architecture), délègue via
  `Agent` tool. Le résumé qu'il rend = ta compaction implicite, gratuite.
- **Compaction explicite à ~200 k tokens** seulement si nécessaire malgré les
  sub-agents : écris l'état essentiel dans `outputs/.ledger.md` (objectif,
  décisions, ce qui reste, fichiers touchés) et fais `/clear`. Au démarrage
  de la session suivante, relis le ledger.
- **Pas plus tard que 200 k** : au-delà, "dumb zone" documentée (perte de
  qualité non linéaire).

## Avant tout claim de complétion

**NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.**

1. Lance un sous-agent `audit-adversarial` (`Agent` tool) avec consigne :
   *"Cherche TOUS les problèmes possibles dans le travail livré : violations
   de spec, oublis, erreurs d'inattention, anti-patterns, edge cases non
   testés. Classe en CRITIQUE / IMPORTANT / MINEUR. Cite fichier:ligne pour
   chaque finding."*
2. Si findings CRITIQUE ou IMPORTANT : traite-les. Re-audit après.
3. Une fois propre : écris la livraison dans `outputs/`.

## Format de `outputs/`

Toujours présent à la fin :

- `outputs/result.md` — résumé exécutif (≤ 200 mots) : ce qui a été fait,
  ce qui n'a pas pu l'être, ce qui reste à valider par l'humain.
- `outputs/audit-report.md` — findings de l'audit adversarial et leur
  traitement.
- `outputs/<artefacts>` — fichiers livrés (code, données, docs).
- `outputs/identity-suggested-updates.md` — uniquement si tu as appris des
  choses sur l'humain qui mériteraient un update de `IDENTITY.md`
  (validation manuelle de l'humain en fin de session).

## Si tu es bloqué

Une seule fois, écris une question dans `outputs/blocked.md` avec :

- ce que tu as déjà essayé
- ce qui te manque pour continuer
- 2-3 options possibles avec leur conséquence

Puis termine. **Ne brute-force pas** après deux tentatives ratées sur le
même sous-problème — lance plutôt un `Agent` d'analyse parallèle.
