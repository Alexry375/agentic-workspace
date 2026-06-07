# country_uk_audit

- **Date livraison** : 2026-05-08
- **Outcome reports.jsonl** : ok
- **Localisation** : `/home/alexis/Global/My_projects/Relay_X/workspaces/country_uk_audit`

## Cause racine

Audit empirique solide grâce à la **vérification directe contre les données brutes** plutôt que contre la spec officielle. L'agent a téléchargé 4 fichiers CLML réels (`curl`/WebFetch), parsé le XML sans LLM pour extraire marqueurs d'amendement (`<Addition>`, `<Substitution>`, `ChangeId`), et **croisé contre deux index indépendants** : métadonnées XML (`<dct:valid>`, `<RestrictStartDate>`, `<CommentaryRef>`) et feed Atom (`EffectId`). Les 3 findings CRITIQUES de l'audit adversarial ont émergé du **parsing du CLML brut** : 28 % des `<Addition>` étaient des inline-ranges imbriqués (pas wrappers de cellule entière), invisible depuis la doc dev officielle.

## Tests existants

- 4 URLs distinctes testées (HTTP 200, latences mesurées 1-3 s).
- 4 versions consolidées datées du 1223 : SHA256 distincts vérifiés → preuve du versioning historique.
- Comptage exhaustif de 2961 `<Addition>` par parent direct (2123 `td`, 651 `Text`, etc.) — pas une assertion, un scan.
- Probabilités bayésiennes sur viabilité approche A vs B dérivées de mesures, pas d'intuition.
- Pas d'exécution Python (PoC déclaré inimplémenté), mais pseudo-code validé contre arborescence XML réelle.

## Un test aurait-il aidé ?

**Partiellement.** Tests unitaires classiques (mocking HTTP, assertions sur `Cell.is_added`) auraient raté les 3 findings (ils valident un comportement supposé, pas la réalité du format). En revanche, un **test d'intégration empirique précoce** aurait dévoilé deux des trois :
- **C1 inline-ranges** : `assert count(Addition under td) == count(Addition)` aurait échoué (2123 ≠ 2961).
- **C2 natural-key collisions** : test comparatif de deux versions du 1223 aurait révélé les 6 collisions first-cell.
- **C3 risques OGL/rate-limit/dépendance gov** : hors test, c'est de la risk assessment.

## Leçon généralisable

- **Audit d'un format externe = vérification contre l'artefact réel, pas contre le schéma supposé.** Descendre parser 2-3 samples bruts révèle les écarts schéma-réalité (C1) plus vite que tout pseudo-code. Pattern fort à embarquer si retrouvé ailleurs.
- **Empirisme > confiance en la spec officielle.** La doc `legislation.gov.uk/developer` ne précisait pas la granularité inline-range ; seul le XML l'a révélé. Symétrie avec **uk_clml_round1** : l'absence de vérification empirique précoce du format est exactement ce qui a permis la métrique tautologique.
- **Audit adversarial pre-implémentation = setter de dette.** Identifier C1/C2/C3 *avant* d'écrire le code économise la réécriture qui a frappé `uk_clml_implementation` round 1.
