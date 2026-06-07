# Procédure workspace

> Tu es l'agent d'un workspace. La session main (chez l'humain) a écrit
> `inputs/prompt.md` comme **spec autoritaire**. Tu bosses en autonomie totale
> du début à la fin. La main t'audite à la livraison — pas de checkpoint
> humain entre temps.

## Boot

1. `aw start` immédiatement (marque le début du timer).
2. Lis `inputs/prompt.md`. Puis le reste de `inputs/`.
3. Si `prompt.md` est incomplet ou contradictoire : `outputs/blocked.md` + termine.
   **Ne devine pas l'intention de la main.**

## Cadrage strict

- **Pas de questions humain.** Tout est dans `inputs/`.
- **Scope borné par `prompt.md`.** Travail adjacent identifié → `outputs/result.md` §Adjacent work, pas exécuté.
- **`inputs/` en lecture seule.** Copie vers `outputs/work/` si besoin de modifier.

## Pendant l'exécution

- **Skill `genius`** auto-disponible (user-level). Applique-le sur toute affirmation factuelle, hypothèse, claim de complétion.
- **Hold-out** : si tu itères sur un dataset A jusqu'à passing, le score sur A est faussé. Mesure et rapporte sur un B intouché.
- **Processus longs (>30 s)** : `run_in_background` + monitor logs. Pas d'attente passive.
- **Recherche web** : pour syntaxe API, limites plateforme, état de l'art. Cutoff training ≠ état actuel.

## Délégation

Récursion autorisée — tu peux toi-même créer un workspace enfant.

### Pattern A — `Agent` tool intra-session

Pour Explore, Plan, audit, analyse parallèle. Le sous-agent rend un résumé structuré = ta compaction implicite.

**Discipline genius** : inclus dans le prompt du sous-agent : *"Avant d'agir, lis et applique `~/.claude/skills/genius/SKILL.md`."* L'auto-invocation est aléatoire.

### Pattern B — `aw new <child>` (workspace enfant)

Pour du lourd (>30 min, état isolé). Tu :

1. `aw new <child>` (depuis ta racine), remplis `workspaces/<child>/inputs/prompt.md` exhaustivement.
2. Demandes à l'humain de lancer `cd workspaces/<child> && claude`.
3. **À la livraison de l'enfant : tu auditres adversarialement ses outputs** — code, métriques, fichiers — jamais juste son `result.md`. Cherche : métriques tautologiques/circulaires, critères abandonnés silencieusement, edge cases non investigués, auto-audits qui *renomment* un problème au lieu de le traiter (incident `uk_clml` 2026-05-14). Round 2 ciblé via `inputs/round-2.md` si CRITIQUE/IMPORTANT.
4. Tu fais ensuite `aw report <child> "<note>"` pour clore l'enfant.

## Audit adversarial avant complétion

Trigger 1 : avant tout claim de complétion finale.
Trigger 2 : après toute avancée majeure (feature end-to-end, archi committée, 1ère livrable d'un module, pivot).

1. Lance un sous-agent `audit-adversarial` (Pattern A) : *"Attaque code (bugs, edge cases, fichiers oubliés), archi (choix structurels fragiles, hypothèses implicites), cadrage (la métrique optimisée correspond-elle au prompt initial ?). Classe CRITIQUE / IMPORTANT / MINEUR. Cite fichier:ligne ou décision pour chaque finding."*
2. Traite CRITIQUE et IMPORTANT. Re-audit après.
3. Finalise `outputs/`.

## Format `outputs/`

- **`outputs/result.md`** — structuré pour la main :
  - `## Done` — concis, bullets.
  - `## Not done` — demandé mais non fait, pourquoi.
  - `## Verification` — comment la main vérifie (commandes, fichiers, valeurs de référence).
  - `## Adjacent work` — pistes hors scope (optionnel).
- **`outputs/audit-report.md`** — findings audit + traitement.
- **`outputs/<artefacts>`** — code, données, docs.

## Compaction

À ~200 k tokens, si les sub-agents (Pattern A) n'ont pas suffi : écris `outputs/.ledger.md` (objectif, décisions, reste, fichiers) et `/clear`. Relis le ledger au démarrage suivant.

## Si tu es bloqué

Une seule fois : `outputs/blocked.md` (essayé / manque / 2-3 options avec conséquence). Puis termine. **Ne brute-force pas** après 2 tentatives sur le même point — `Agent` tool d'analyse parallèle, ou bloqué.

## Fin de tâche

`aw end` en toute dernière action (marque le timer). **N'appelle pas `aw report`** — la main s'en charge après son audit.
