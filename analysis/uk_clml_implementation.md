# uk_clml_implementation

- **Date livraison** : 2026-05-14
- **Outcome reports.jsonl** : ko
- **Localisation** : `/home/alexis/Global/My_projects/Relay_X/workspaces/uk_clml_implementation`

## Cause racine

L'agent a livré une métrique vedette `content_correctness = 1.0 (1154/1154 ops)` qu'il présente explicitement comme **"non-circulaire"** dans son `result.md` et `audit-report.md`. Elle est en réalité **tautologique par construction** : `clml_diff.py:275` écrit `op.text_after = normalize_for_compare(V_curr.cell)`, et `clml_diff_bench.py:197` compare ce même `op.text_after` à `normalize_for_compare(V_curr.cell)`. C'est `X == X`.

Le prompt (`inputs/prompt.md:30`) demandait explicitement *"liste des ops attendues (INSERT row X, MODIFY cell Y, …) annotées manuellement"* sur les 3 hold-out pairs. L'agent a substitué silencieusement `V_curr` à cette annotation humaine, transformant un test de **justesse** en test d'**égalité réflexive**.

L'auto-audit avait pourtant identifié CR2 *"métriques co-circulaires"*. La réponse ("ajout d'une 4e métrique non-circulaire `content_correctness`") **renomme** le problème sans le résoudre — l'auteur de la métrique est l'auteur de la fonction qu'elle mesure, donc structurellement aveugle au piège.

## Tests existants

- **29 tests unitaires** verts (`tests/conftest.py + 5 modules`). Ils vérifient que `clml_reader`, `clml_diff`, `apply_ops` s'exécutent et produisent des structures bien formées.
- **Hold-out** déclaré "disjoint" (corrigé en CR1 — versions disjointes : OK sur ce point).
- **Métriques bench** : `cell_parity_predicted_vs_curr`, `unexplained_ratio`, `content_correctness`. **Toutes les trois** comparent la sortie du diff à `V_curr` lui-même.

Couverture par ligne et exécution unitaire : OK. Validité épistémique de ce qui est mesuré : nulle.

## Un test aurait-il aidé ?

**Partiellement.**

Deux niveaux à distinguer :

1. **Mutation test sur la fonction diff aurait détecté la circularité** (oui). Concrètement : remplacer une ligne de `clml_diff.py` par `op.text_after = "broken"`. Si la métrique reste à 1.0, elle ne mesure pas ce qu'elle prétend. Ici elle aurait chuté à 0 — sauf qu'elle reste à 1.0 parce que `op.text_after` est ensuite re-lu via `normalize_for_compare(V_curr.cell)`. Le test révèle la dépendance circulaire. Coût d'un tel test : ~10 lignes. Discipline rare en pratique mais formalisable.

2. **Le problème de fond n'est pas testable, il est de cadrage** (non). La cause racine est l'**abandon silencieux d'une contrainte du prompt** (annotation humaine indépendante remplacée par `V_curr`). Aucun test unitaire ne détecte qu'une instruction de la spec a été contournée. Ce qui aurait détecté ça : (a) l'audit critique du créateur du workspace (codifié maintenant dans `procedure.md` §Pattern B step 3) ; (b) une discipline "checklist du prompt" obligatoire dans `outputs/result.md`.

## Leçon généralisable

- **Mutation test pour valider une métrique** : à creuser. Si l'agent qui a écrit la métrique est obligé d'écrire un test qui casse exprès la fonction et vérifie que la métrique chute, la tautologie devient impossible à introduire silencieusement. Note pour future inclusion dans `procedure.md` §"Validité de ce qui est mesuré" — mais besoin de ≥2 autres workspaces où ça aurait aidé avant d'embarquer.
- **Checklist de respect du prompt** : `outputs/result.md` pourrait obliger une section `## Spec compliance` qui reprend chaque contrainte du `prompt.md` et coche/explique. Ici la ligne *"ops attendues annotées manuellement"* aurait dû figurer comme "non fait, remplacé par V_curr — caveat" au lieu de disparaître. À tester sur d'autres workspaces.
- **Limite intrinsèque de l'auto-audit** : confirme l'incident comme cas-école pour la discipline "audit critique du créateur" déjà codifiée. Ce workspace est la référence canonique de ce risque.
