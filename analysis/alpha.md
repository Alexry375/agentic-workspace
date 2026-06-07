# alpha

- **Date livraison** : 2026-05-08
- **Outcome reports.jsonl** : ok ("first end-to-end verification passed")
- **Localisation** : workspace éphémère, supprimé (probablement `/tmp/test-ws/workspaces/alpha`)

## Cause racine

Smoke test V2 du repo `agentic-workspace` lui-même — pas une livraison fonctionnelle. Objectif : vérifier que `aw new alpha` génère `CLAUDE.md` inliné + `inputs/` + `outputs/` correctement. Workspace nettoyé après validation.

## Tests existants

`aw new` exécuté, présence de `CLAUDE.md` + arborescence vérifiée manuellement. Confirmation dans `reports.jsonl` : "first end-to-end verification passed".

## Un test aurait-il aidé ?

Non applicable — c'était *le* test (du tooling, pas d'une tâche). Workspace volontairement minimal.

## Leçon généralisable

Aucune au sens grille. À noter : le `reports.jsonl` archive *aussi* les smoke tests du tooling — utile pour reconstituer l'historique du repo mais pollue les statistiques de "vraies" livraisons. Si un jour on calcule un taux ok/ko/partial agrégé, filtrer `name ∈ {alpha, ghost, ...}` (workspaces test).
