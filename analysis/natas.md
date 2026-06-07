# natas

- **Date livraison** : 2026-05-18
- **Outcome reports.jsonl** : ok
- **Localisation** : `/home/alexis/Global/Agents_Projects/bug-bounty/workspaces/natas`

## Cause racine

Succès solide grâce à trois facteurs alignés :
1. **Tâche déterministe L1-L2** — chaque niveau Natas 0→4 expose son secret par un mécanisme prévisible (commentaire HTML, directory listing, robots.txt, header Referer).
2. **Vérification empirique forte** — flags validés par `curl -u natasN:<secret>` retournant HTTP 200, preuve directe et non-falsifiable.
3. **One-shot Agent tool intra-session** — chaque niveau résolu en un seul aller-retour analyse + vérif, pas d'enchaînement long propice aux erreurs cumulatives.

**Ce qui aurait pu mal tourner** : inférence partielle ("le mot de passe est probablement X") sans vérif `curl` finale — auto-validation textuelle au lieu de preuve empirique. Évité ici.

## Tests existants

Vérification empirique end-to-end (`outputs/result.md:36-49`) : boucle curl sur les 5 transitions natas1→5, tous HTTP 200. Valide simultanément syntaxe du secret, auth serveur, et chaîne intégrale. Pas de test unitaire sur la capture regex, mais la vérif HTTP suffit comme preuve directe.

## Un test aurait-il aidé ?

**Partiellement.** Pour Natas 0-4 (L1-L2), la vérification empirique `curl` est suffisante — un test unitaire sur la regex serait du gold-plating. Pour L3+ (LFI, RCE futurs niveaux), un test unitaire devient critique car la surface d'attaque grandit et l'inférence remplace de plus en plus la vérification directe.

## Leçon généralisable

- **Audit adversarial conditionné à la complexité.** L'agent a auto-audité sans spawner de sub-agent — défendable pour L1-L2 où la preuve est empirique. Friction soulevée par l'audit (`outputs/audit-report.md:49-51`) : `procedure.md §"Audit adversarial avant complétion"` est trop catégorique, devrait moduler par niveau de complexité ou type de preuve (empirique directe vs inférence). À creuser quand on aura ≥3 cas L1-L2 où le sub-agent était overkill.
- **Tension `genius (P>80 agis)` vs `CLAUDE.md (no claim sans audit)`.** Pour L1-L2 à preuve empirique forte, "agis et vérifie par curl" satisfait les deux. Pour L3+ inférentiel, "audite via sub-agent" devient nécessaire. La règle universelle uniforme actuelle force du surplus sur L1-L2 et probablement du déficit sur L4-L5.
- **Vérification end-to-end > inférence.** Tout "fait = secret/flag/valeur" doit être prouvé par exécution, jamais seulement dérivé. Discipline déjà saine ici.
