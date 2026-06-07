# bounty

- **Date livraison** : 2026-05-18
- **Outcome reports.jsonl** : partial
- **Localisation** : `/home/alexis/Global/Agents_Projects/bug-bounty/workspaces/bounty`

## Cause racine

Absence de gate de dédoublonnage **avant** la vérification coûteuse. Le prompt fournissait un corpus d'exclusion V12 (125k lignes, findings connus hors scope). L'agent a généré 5 findings → lancé 4 PoC en parallèle (copies de repo, builds, `cargo test`) → seul l'audit adversarial a découvert que 4/5 étaient des doublons V12 (#44847, #44866, #44486 + un Critical hors-scope). Coût : ~600k tokens + 7.6 Go disque pour valeur monétaire nulle (`outputs/harness-findings.md:9-47`). Un `grep` croisé de 5 min suffisait à éliminer 80 % du hors-scope avant la première compilation.

## Tests existants

- **PoC exécution** : 5/5 verts (compilation + `cargo test`) — valide la mécanique du finding, **pas son éligibilité scope**.
- **Audit adversarial procédural** : relecture + re-run indépendant — détecte les doublons *a posteriori*, après l'investissement.
- **Aucun gate scope** entre génération du finding et son PoC.

## Un test aurait-il aidé ?

**Oui** — un **gate de dédoublonnage** déclaratif, exécuté entre étape "candidat" et étape "PoC". Type : E2E de cadrage, pas unit. Forme concrète : `for f in candidates: assert grep_corpus_exclusion(f) == 0` avant tout build. Coût : quasi nul. Bénéfice prouvé : évite 4/5 PoC. Coordonne aussi le second levier (séparation des rôles cognitifs : chercheur ≠ vérificateur de scope) — l'agent qui génère est mauvais juge de l'éligibilité de son propre output.

## Leçon généralisable

- **Scope comme contrainte L1, vérifiée tôt.** Pour toute tâche "trouver X dans corpus + scope d'exclusion explicite" (bug bounty, recherche avec état de l'art, audit avec findings connus), insérer une gate de dédoublonnage **avant** la vérification coûteuse. Coût quasi nul, bénéfice énorme.
- **Audit adversarial réactif ≠ gate prédictif.** L'audit a détecté les doublons (correct), mais au mauvais étage — après l'investissement. La discipline "audit adversarial avant complétion" (déjà dans `procedure.md`) ne couvre pas le coût engagé entre génération et vérification.
- **Séparation des rôles cognitifs.** Le générateur de findings et le vérificateur de scope doivent être deux entités distinctes ; fusionnés, l'agent "achète" trop facilement ses propres hypothèses. Symétrie avec l'incident `uk_clml` (auto-audit renomme au lieu de résoudre) — 2e occurrence, candidat à formaliser.
