# regulatory_landscape_cosmetics

- **Date livraison** : 2026-05-08
- **Outcome reports.jsonl** : ok (audit adversarial 6.5/10)
- **Localisation** : `/home/alexis/Global/My_projects/Relay_X/workspaces/regulatory_landscape_cosmetics`

## Cause racine

Dispatch de 18 sub-agents Claude Code en parallèle, chacun cartographiant **une juridiction** via WebSearch + WebFetch + samples PDF/xlsx. Architecture massivement parallèle = couverture rapide, empirisme strict (URL testées datées 2026-05-08). **Mais zéro cross-check inter-agents** : chaque agent écrit sa fiche pays sans connaître les claims des autres. L'erreur Brunei (Annex VI/VII inversés) a échappé à la livraison initiale car aucun mécanisme ne comparait les fiches ASEAN entre elles ; l'audit adversarial (un sub-agent dédié post-livraison) l'a détectée par lecture comparative ligne-par-ligne contre les 9 autres fiches ASEAN harmonisées.

## Tests existants

- **Sources citées systématiquement** : chaque fiche contient section "Sources investiguées" (URL + date test + HTTP code). Bonne traçabilité.
- **Samples binaires téléchargés** dans `outputs/samples/`.
- **Audit adversarial post-livraison** : un sub-agent passant après les 18 — a détecté 11 incohérences (4 C, 11 I/M). Brunei détectée par grep "Annex VI" sur le corpus ASEAN entier.
- **Aucun cross-check inter-juridictions automatisé** côté production.

## Un test aurait-il aidé ?

**Oui, partiellement.** Trois pistes complémentaires :
1. **Citation check structurel** : `grep -E "Annex (VI|VII)" outputs/asean/*.md` → tableau consolidé, divergences saillantes en 10 s.
2. **Cross-validation par source autoritative unique** : charger l'ACD harmonisée HSA une fois, valider chaque fiche pays contre ce gold-standard.
3. **Audit adversarial à 50 % de couverture, pas en fin.** Aurait détecté Brunei + Inde I10 + chiffres IECIC incohérents bien avant la livraison complète.

**Limite des tests** : certaines erreurs (faisabilité réelle d'une API, qualité d'un PDF) ne sont détectables que par humain — pas par structure.

## Leçon généralisable

- **Recherche multi-sources parallèle ⇒ cross-check structuré obligatoire.** Sans mécanisme inter-fiches, chaque sub-agent est aveugle aux contradictions globales. Pattern : **table de claims consolidée** + audit adversarial à mi-parcours.
- **Source autoritative unique = filet le plus efficace** sur les domaines harmonisés (EU 1223, ACD, GMC Mercosur). Si une fiche pays diverge du gold-standard, soit la fiche se trompe, soit la juridiction dévie réellement — les deux méritent investigation.
- **Optimisme systématique sur les sources non-testées** : finding I7 "tous PDF notés 'Bon' sans test pdfplumber" = biais structurel quand l'agent n'a pas la contrainte de **prouver** l'extractabilité. Discipline : un test par claim de faisabilité.
