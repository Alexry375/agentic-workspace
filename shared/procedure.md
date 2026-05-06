# Procédure commune (workspace classique + sub-workspace)

## Pendant l'exécution

- **Skill `genius`** : il est chargé automatiquement (`.claude/skills/genius/SKILL.md`).
  Applique-le sur toute affirmation factuelle, hypothèse, et claim de complétion.
- **`inputs/` est en lecture seule.** Si tu dois travailler sur une copie, copie
  vers `outputs/work/`.
- **Sous-tâches** :
  - Découpage **intra-workspace** (Explore, Plan, recherche, sous-problème de la
    même tâche) → utilise le tool `Agent`.
  - Tâche qui mérite son propre `CLAUDE.md` / `inputs/` / `outputs/` (vraiment
    autonome, état isolé) → utilise `bin/create-sub-work` puis
    `Bash("cd workspaces/<name> && claude -p ...")`. Le tool `Agent` ne suffit
    pas : il ne charge pas le `CLAUDE.md` du sous-dossier ni ses skills locales,
    et il ne peut pas spawn d'autres sub-agents (limite officielle).
- **Compaction** : quand le contexte arrive à ~70 %, écris l'état complet dans
  `outputs/.ledger.md` (objectif, ce qui est fait, ce qui reste, décisions
  prises, fichiers touchés) et fais `/clear`. Ce fichier est lu en début de
  session suivante.

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

- `outputs/result.md` (workspace classique) ou `outputs/result.json`
  (sub-workspace) — résumé exécutif (≤ 200 mots ou JSON schema imposé) :
  ce qui a été fait, ce qui n'a pas pu l'être, ce qui reste à valider.
- `outputs/audit-report.md` — findings de l'audit adversarial et leur
  traitement.
- `outputs/<artefacts>` — fichiers livrés (code, données, docs).
- `outputs/identity-suggested-updates.md` — uniquement si tu as appris des
  choses sur l'humain qui mériteraient un update de `IDENTITY.md` (validation
  manuelle de l'humain en fin de session).

## Si tu es bloqué

Une seule fois, écris une question dans `outputs/blocked.md` (ou
`outputs/blocked.json` pour un sub-workspace) avec :

- ce que tu as déjà essayé
- ce qui te manque pour continuer
- 2-3 options possibles avec leur conséquence

Puis termine. **Ne brute-force pas** après deux tentatives ratées sur le même
sous-problème — lance plutôt un `Agent` d'analyse parallèle.
