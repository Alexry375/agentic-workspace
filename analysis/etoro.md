# etoro

- **Date livraison** : 2026-05-18
- **Outcome reports.jsonl** : partial
- **Localisation** : `/home/alexis/Global/Agents_Projects/bug-bounty/workspaces/etoro`

## Cause racine

L'agent a engagé un modèle ping-pong (humain capture refresh token → agent teste) sans **mesurer au préalable la fenêtre de validité du token**. Le `refresh.sh` capturé pointait sur le mauvais endpoint (`outputs/harness-findings.md:144-180` — H-6), mais la fragilité n'a été détectée qu'**après** le départ de l'humain → fenêtre courte de validité (H-5) → blocage jusqu'au lendemain. Un test trivial — ping GET avec le token, attendre 10 min, re-ping → SessionExpired ou non — aurait révélé la durée de vie *avant* d'engager la capture longue.

## Tests existants

- **Audit adversarial post-hoc** (`outputs/audit-report.md`) : a détecté la compression x40 du batch2 (H-7), mais après production.
- **Scope gate** (H-1, H-2, H-3) : listait les exclusions, mais zéro probe proactif de Bugcrowd (aurait révélé le SPA gated).
- **Zéro test de fenêtre token.** Aucune vérification de durée de vie avant capture humaine.

## Un test aurait-il aidé ?

**Oui, deux tests précis** :
1. **Probe de faisabilité Bugcrowd** (15 s de `WebFetch` au boot) : aurait éliminé H-1 sans aller-retour humain.
2. **Test de fenêtre token** : ping GET + attente 5-10 min + re-ping avant la demande de capture. Coût 10 min, économise 2-3 tours bloquants si la capture échoue.

Le test de validation de l'artefact `refresh.sh` (H-6) lui-même est difficile à automatiser sans navigateur — c'est de la **procédure** (faire valider la capture par l'agent avant le départ humain), pas du test.

## Leçon généralisable

- **Mesurer une fenêtre de validité avant de demander la capture d'un artefact éphémère.** Sinon, l'agent engage l'humain en blind et bloque la session si l'artefact pourrit avant validation.
- **Probe de faisabilité < relance humaine.** Si vérifier la praticabilité coûte < 1 min et un aller-retour humain coûte 5 min + attente, toujours probe. Pattern : `WebFetch` ou `curl` sec au boot avant de proposer le plan complet.
- **Ping-pong en 3 phases** : (1) mesure des contraintes (fenêtre, dépendances), (2) demande de capture *avec critères d'auto-validation*, (3) validation agent **avant** le départ humain. Jamais laisser un artefact critique franchir l'absence sans accusé de réception.
