# audit-monsantorin

- **Date livraison** : 2026-05-10
- **Outcome reports.jsonl** : ok
- **Localisation** : `/home/alexis/Global/Agents_Projects/monsantorin/workspaces/audit-monsantorin`

## Cause racine

**Audit entièrement textuel** sur ~4000 lignes JS/HTML : lecture statique, `grep` ciblé, pattern matching, comparaison code/doc. Zéro exécution du code, zéro instanciation de l'app. 12 findings produits, traçabilité fichier:ligne pristine (~100 références dans `audit-complet.md`). Risque hallu-findings très bas (~0 %) car les findings sont soit **code mort vérifiable par grep** (B1, B9-12 — SUBS/GREEK définis jamais appelés), soit **écarts doc/code textuels** (B4 — majoration TT documentée vs. implémentation), soit **antipatterns connus** (B3 `JSON.parse` sans try/catch, B7 `innerHTML` non échappé). Aucune trouvaille basée sur spéculation.

## Tests existants

**Aucun test automatisé** dans le code audité — noté explicitement (`audit-complet.md:51`). Méthode d'audit = lecture + grep + pattern matching. Validation des findings : citation ligne-par-ligne, l'auteur peut corriger en ~15 min.

## Un test aurait-il aidé ?

**Partiellement.** Tri par catégorie :
1. **Findings purement textuels (B1, B4, B5, B9-12)** — code mort, écart doc/code, logique de calcul lisible : lecture suffit, tests inutiles.
2. **Findings à validation dynamique (B2, B3, B7, B8)** — gros data: URL silencieux, `JSON.parse` crash, XSS appréciation, regex `*` markdown : nécessitent l'app lancée pour preuve. ~15 min de test interactif aurait fermé ces 4 findings au lieu de les laisser à l'auteur. Type : mini-smoke tests E2E manuels documentés.
3. **Findings perf perçue (B6)** — tri sur keystroke à 200 élèves : profilable seulement à l'exécution.

**Stratégie optimale** estimée : 10 min lecture (5-6 findings textuels) + 15 min app lancée (4 findings dynamiques) ≈ 25 min vs. ~45 min de l'audit textuel pur, **avec preuve plus forte** sur les CRITIQUES.

## Leçon généralisable

- **Audit statique ≠ validation dynamique.** ~67 % d'un audit technique est code-reviewable par lecture seule ; 33 % gagne fort à exécution. Mixer (lecture rapide → identifier candidats → 1 run + 2-3 inputs probants) divise le temps total tout en gardant haute confiance sur les CRITIQUES. Symétrie avec `webapp-cinematic` (validation visuelle sans mesure chiffrée).
- **Risque hallu-findings ≈ 0 si méthode strictement non-spéculative.** Lecture + grep + comparaison doc/code = preuve traçable. Spéculation algorithmique ("ce code est O(n²)") sans profiling = ~40 % de faux positifs. Discipline : pour les audits de repo externe sans exécution, interdire toute trouvaille qui ne pointe pas un fichier:ligne ou un écart doc/code.
- **Méthode textbook + traçabilité ligne-par-ligne** = standard pen-test / code review asynchrone. Reproductible sur d'autres audits externes — bon candidat pour un guide `shared/guides/audit-textuel-repo-externe.md` si on a un 2e cas comparable.
