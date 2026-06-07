# font-size-fda

- **Date livraison** : 2026-05-08
- **Outcome reports.jsonl** : partial (reporté sous `font-size-fda-compliance`)
- **Localisation** : `/home/alexis/Global/My_projects/Relay_X/workspaces/font-size-fda`

## Cause racine

Spec intrinsèquement faible — *"≥90 % classification"* — acceptée telle quelle. La métrique mesure l'accuracy globale sur dataset stratifié (33 % non-conforme / 33 % borderline / 33 % conforme, `synth_gen.py:71-74`) sans baseline triviale ni F-score : un dummy classifier prédisant la classe dominante atteint déjà ~60 %. L'agent a livré 87.5 % d'accuracy honnêtement mesurée, mais **sans référent**, on ne sait pas si c'est *significativement supérieur à dummy*. Et **zéro annotation humaine indépendante** sur images réelles — le ground-truth est entièrement synthétique (`synth_gen.py:301-334`), ce qui valide la robustesse du VLM *sur la synthèse*, pas sur le cas FDA réel.

## Tests existants

- **Hold-out stratifié** : 30 images, 6 ratios cap/seuil → distribution équilibrée. Bon contre le mono-classe trivial mais ne suffit pas.
- **Accuracy per-mention + globale + confusion matrix** (`run_eval.py`). Métriques honnêtes, présentation propre.
- **Aucune baseline triviale, aucune annotation humaine sur image réelle.**

## Un test aurait-il aidé ?

**Partiellement.**
- **Oui** : (1) **baseline dummy** (prédire conforme partout) → expose l'écart réel entre signal et bruit, ~5 lignes ; (2) **sanity-check distribution** (min_class / max_class > 0.3) → bloque toute dérive mono-classe future ; (3) **annotation humaine sur 5-10 images réelles** → valide que la synthèse capture l'enjeu réglementaire.
- **Non pour la spec faible elle-même** : aucun test ne répare *"≥90 % accuracy"* mal cadré. Ça relève de l'audit "métrique ↔ objectif" en amont, côté main.

## Leçon généralisable

- **Baseline triviale obligatoire** avant d'accepter toute métrique de classification. *"Modèle X = 87.5 %, dummy = 60 %, écart = 27.5pts"* est défendable ; *"X = 87.5 %"* seul est creux. **Symétrie directe avec `uk_clml`** (métrique tautologique) et `objets-trouves-v2` (22/26 faux positifs masqués sans eval set) — **3e occurrence du pattern "métrique acceptée sans référence indépendante"**, candidat fort pour `procedure.md`.
- **Classification déséquilibrée → F1 ou precision/recall**, jamais accuracy nue, surtout en domaine réglementaire où le coût des faux négatifs n'est pas symétrique.
- **Synthèse ≠ réalité.** Exiger annotation humaine croisée sur ≥5 vrais cas avant complétion d'un pipeline VLM. La synthèse reproductible n'est pas la synthèse réaliste — Gemini peut briller sur l'une et dériver sur l'autre.
