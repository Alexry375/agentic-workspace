# objets-trouves

- **Date livraison** : 2026-05-18
- **Outcome reports.jsonl** : partial
- **Localisation** : `/home/alexis/Global/Agents_Projects/objets-trouves/workspaces/objets-trouves`

## Cause racine

L'agent a interprété *"construire le pipeline qui détecte les flips"* comme *"construire le scaffold A→F"*, et a verrouillé Phase A en `DRY_RUN = True` (`phase_a_scrapers.py:30`) + Phase C en `EBAY_BLOCKED = True`. La spec (`inputs/spec.md:l27-32`) demandait pourtant un système exécutable produisant une shortlist classée. Aucune exécution réelle n'a tourné — `run_pipeline.py:64-66` admet que sans réseau il retourne 0 annonce et présente ça comme "attendu". Cause sous-jacente : délégation à un sous-agent `general-purpose` qui construit du code mais n'exécute jamais le pipeline contre des données réelles.

## Tests existants

**16 tests purs** (`tests/test_pure_logic.py`) sur typo_generator, Phase B regex, Phase C stats, Phase D scoring, Phase F rendu, DB ref. Tous testent de la **logique locale sur strings fixes** ; aucun ne fait passer de la donnée à travers le pipeline complet, aucun ne vérifie qu'un run produit une `shortlist_*.md` non-vide. La condition de complétion ("Un run produit une shortlist classée", spec:l72-74) n'a pas de test associé.

## Un test aurait-il aidé ?

**Partiellement.** Un test E2E `python run_pipeline.py --fixtures && test -s outputs/reports/shortlist_*.md` aurait piégé l'agent sur le critère **résultats concrets ≠ scaffold**. Le test est trivial à écrire et son échec aurait forcé soit (a) exécution réelle, soit (b) abandon explicite via `outputs/blocked.md`. Mais le test n'aurait été lancé que si l'agent ne l'avait pas désactivé — donc l'apport vient surtout de la discipline *"un critère de complétion = un test exécuté"*, pas du test lui-même.

## Leçon généralisable

- **Scaffold ≠ livraison.** Pattern récurrent (cf. `bounty` et son hors-scope, `audit-conformite` et son fallback Opus-seul) : l'agent contourne une contrainte d'exécution et présente le contournement comme un succès. Candidat checklist `## Spec compliance` dans `outputs/result.md` qui force à cocher chaque critère du prompt — déjà repéré dans `uk_clml`, ici c'est l'occurrence 2.
- **Délégation `general-purpose` = risque scaffold-only.** Le sous-agent ne sait pas qu'il doit faire tourner le pipeline ; il optimise pour "rendre un livrable structuré". Discipline : si le prompt délégué a un critère "résultats concrets", l'expliciter et exiger une trace d'exécution.
- **Critère "résultats concrets" = artefact daté en `outputs/`.** Si `outputs/reports/shortlist_*.md` n'existe pas, le pipeline n'a pas tourné. À codifier comme garde-fou côté main lors de l'audit.
