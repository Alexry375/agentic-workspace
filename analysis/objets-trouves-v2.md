# objets-trouves-v2

- **Date livraison** : 2026-05-18
- **Outcome reports.jsonl** : partial
- **Localisation** : `/home/alexis/Global/Agents_Projects/objets-trouves/workspaces/objets-trouves-v2`

## Cause racine

Phase B rattache les optiques au référentiel sans vérifier la cohérence du triplet **(marque + focale + monture)**. Une annonce *"Minolta 135mm"* accumule confiance=0.60 (marque 0.25 + focale 0.20 + monture 0.15) et passe en Phase D **sans ref_entry valide**, qui la cote ensuite contre un modèle inventé du référentiel (ex. *"MC Rokkor 58mm f/1.2"*). Résultat : 22/26 faux positifs sur les optiques flaggées (`phase_b_identify.py:170` — rattachement par simple inclusion ; fix post-audit lignes 246-269 ajoute la validation focale stricte). La détection des signaux fonctionnait, le **rattachement** au référentiel manquait de garde-fou.

## Tests existants

16 tests purs (`tests/test_pure_logic.py:54-74`) sur typo_generator, Phase B/C/D, F, DB ref. **Zéro test de lens-mismatch** : aucun cas *"focale annonce ≠ focale ref"* n'est testé. Validation côté audit a posteriori uniquement (`outputs/audit-report.md:9-23`).

## Un test aurait-il aidé ?

**Oui, critique.** Deux niveaux :
1. **Test unitaire** : `test_b_lens_mismatch_needs_vision()` — annonce *"Minolta 135mm"* + monture M42 vs référentiel *"58mm f/1.2"* → attendu `needs_vision=True`. ~10 lignes. Aurait échoué avant le fix.
2. **Eval set annoté** : 20-30 annonces eBay/LBC étiquetées (vrai/faux flip) jouées en CI avant complétion. Le taux de faux positifs (84 %) aurait sauté aux yeux. Coût : ~30 min d'annotation, payé une fois.

## Leçon généralisable

- **Rattachement multi-signaux = test obligatoire de cohérence du triplet.** Détecter (marque, focale, monture) ≠ rattacher (modèle existant). Toute combinaison de 3+ signaux pour identifier une entité demande un test qui valide l'**ensemble**, pas la présence de chaque champ. Candidat fort `procedure.md` si on retrouve ce pattern ailleurs (3e occurrence à chercher).
- **Eval set annoté << audit a posteriori.** 30 annonces étiquetées en amont > 300k tokens d'audit + 22 faux positifs livrés. Symétrie avec `font-size-fda` (pas de baseline triviale) et `uk_clml` (pas d'annotation humaine indépendante) — **3e occurrence du pattern "métrique acceptée sans référence indépendante", embarquement justifié**.
- **Phase de mesure de précision avant complétion.** Critère DoD : taux faux positifs < seuil mesuré sur eval set, sinon `blocked.md` ou ajustement.
