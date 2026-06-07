# relay_x_formex_finalize

- **Date livraison** : 2026-05-08
- **Outcome reports.jsonl** : ok (2e entrée, post-corrections)
- **Localisation** : `/home/alexis/Global/My_projects/Relay_X/workspaces/relay_x_formex_finalize`

## Cause racine

**Ce qui a marché** :
1. Bug lxml `id()` instability diagnostiqué finement — `id()` retourne un wrapper Python instable à chaque accès lxml, fix via `tree.getpath()` (XPath stable, `formex_reader.py:454-478`, commit `4ac815f`). Test régression `test_extract_quoted_tables_dedup_stable_under_lxml_id_churn` ajouté ensuite (commit `9dbbc9a`).
2. Critique C2 audit (garde serveur `kind=eurlex` manquante) corrigée.

**Mini-incident S1 — décision contestable** : suppression de `pictogrammes/` (178 fichiers, ~5.6 Go) sans prérequis explicite validé. Le sub-agent d'audit a vérifié `du -sh etiquettes/` **au mauvais path** (faux-positif C1, `audit-report.md:11`), donc l'audit a marqué la suppression *"Décision assumée"* sans bloquer. Perte de versioning GitHub d'un POC actif.

## Tests existants

**163 tests** sur `formex_stack`, dont 13 dans `test_formex_reader.py`. **Golden** : 10/13 paires bootstrap passent (3 fail préexistantes commit `0737d33`). Couverture solide sur le pipeline parse → apply (bootstrap + e2e webapp API). **Mais** zéro test côté "garde-fous workspace" — suppression de répertoires, conservation de POCs actifs, vérif de backups.

## Un test aurait-il aidé ?

**Sur `pictogrammes/`** : **oui** — un test de prérequis déclaratif aurait stoppé la suppression :
```python
def test_pictogrammes_safe_to_remove():
    assert (Path.home() / "Global/My_projects/Relay_X/etiquettes").exists(), \
        "pictogrammes/ supprimable seulement si etiquettes/ existe localement"
```
Le test aurait échoué pour la même raison que le sub-agent (mauvais path), avec un message explicite → blocage. ~5 lignes.

**Sur lxml `id()`** : **oui, et déjà fait** — mais **après** le fix. Discipline TDD aurait écrit le test d'abord ; ici on a eu de la chance d'attraper la régression.

## Leçon généralisable

- **Prérequis critiques = tests déclaratifs, pas vérifs ad-hoc.** Toute action destructive (suppression dossier, drop table, rm cache) doit avoir un test prérequis qui échoue si l'invariant n'est pas vérifié — exécuté **avant** l'action, pas en post-audit. Symétrie avec `bounty` (gate scope-check) — **2e occurrence du pattern "gate prédictive avant action coûteuse/destructive"**.
- **Audit avec sub-agent peut hériter des mêmes blind spots.** Le sub-agent d'audit a checké le mauvais path → l'audit a validé une décision dangereuse. Discipline : pour les actions destructives, l'audit doit **citer le chemin exact** vérifié, traçable.
- **TDD sur bugs d'instabilité infra.** lxml id() churn = bug subtil que la TDD aurait forcé à diagnostiquer rigoureusement. Ici le diagnostic est venu d'abord puis le test — bon résultat, mauvaise discipline.
