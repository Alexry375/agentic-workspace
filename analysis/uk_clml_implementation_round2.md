# uk_clml_implementation_round2

- **Date livraison** : non listé dans `reports.jsonl` (correctif post-round 1)
- **Outcome** : ok partiel (métrique non-circulaire, mais borne inférieure assumée)
- **Localisation** : `/home/alexis/Global/My_projects/Relay_X/workspaces/uk_clml_implementation_round2`
- **Réfère** : [[uk_clml_implementation]]

## Cause racine

**Round 2 corrige round 1 — partiellement, avec une nouvelle limite explicite et honnête.**

Round 1 livrait `content_correctness = 1.0 (1154/1154)` tautologique (`op.text_after = normalize_for_compare(V_curr.cell)` comparé au même `normalize_for_compare(V_curr.cell)` — X==X). Round 2 a reconstruit la métrique **indépendamment** via un oracle syntaxique : `extract_truth.py` (240 lignes, **zéro import de `clml_diff`**) classe les opérations attendues en parcourant les `ChangeId` nouveaux dans le XML, orthogonalement à l'algorithme `SequenceMatcher` du diff. Résultat hold-out : A=89.2 %, B=98.6 %, C=100 % — **non-tautologique**.

**Nouvelle limite** (audit-report I1) : l'oracle ne capture que les amendements marqués `<Addition>/<Substitution>` avec `ChangeId` nouveau. Les **consolidations éditoriales silencieuses** (amendement appliqué intermédiaire, rétranscrit plain en V_curr sans balise) échappent. Donc `precision` est une **borne inférieure**, pas une mesure absolue — explicitement qualifié dans `benchmark_report_v3.md`. Honnête, mais le chiffre reste minorant.

## Tests existants

1. **29 tests unitaires round 1 réutilisés intacts** (`clml_stack/tests/`) — pass confirmé.
2. **Oracle truth** exécuté sur hold-out : 158 ops (A), 73 ops (B), 1 op (C) extraites du XML → annotations JSON gelées.
3. **Métrique v3** sur 8 paires : train (5) sans oracle (métriques structurelles `unexplained`, `parity_pred`, baseline) ; hold-out (3) vs oracle (recall, exact_recall, row_recall, precision_lower_bound).
4. **Garde-fou post-audit I2** : `body_rows_integrity` (extract_truth.body_rows vs clml_reader.parse indexing) = OK 8/8 paires.
5. **Edge case train_02 unexplained=2/2701** documenté : rows vides repealed, fallback index-align → no MODIFY_CELL.

## Un test aurait-il aidé ?

Trois tests **complémentaires** auraient resserré l'incertitude résiduelle :
1. **Test différentiel `body_rows`** : assertion symétrique `extract_truth.body_rows(tab) == clml_reader.body_rows(tab)` — isole la duplication logique signalée I2.
2. **Annotation humaine d'un extra-échantillon** (50 ops hold-out random) → calibrer la fraction "vraie modif sans ChangeId vs faux positif diff" → passer de `precision_lower_bound ≥ 15 %` à une estimate vraie.
3. **Mutation test sur `apply_ops`** : réinjecter les truth ops dans le diff et vérifier `V_prev + truth_ops == V_curr` bitwise — détecte si truth-walker se trompe sur texte ou row_index.

Aucun de ces tests n'est cruciale (round 2 n'est pas cassé sans eux), mais ils auraient fait passer d'une borne inférieure prudente à une mesure calibrée.

## Leçon généralisable

- **Correctif post-incident = reconstruire la métrique indépendamment, pas patcher l'ancienne.** Round 2 a choisi d'écrire un oracle disjoint plutôt que de débugger `content_correctness` — le bon choix. Patcher une métrique structurellement circulaire conduit à `uk_clml round 1` qui a *renommé* le problème (4e métrique encore circulaire). Réécrire plutôt que rapiécer.
- **Oracle incomplet > métrique tautologique.** "89 % sur amendements marqués" est honnête et progresse ; "100 % sur X==X" n'apprend rien. Borne inférieure assumée et documentée est un signe de maturité méthodologique.
- **Post-incident pattern viable** : (a) réutiliser le code core (non-cassé en round 1, juste mal évalué), (b) réécrire le bench, (c) audit adversarial documente la limite résiduelle. À codifier comme template "round 2 après incident métrique".
- **Confirme et renforce le pattern n°1** (métrique sans référence indépendante) : round 2 = solution exemplaire — oracle disjoint + ground truth syntaxique vérifiable. La discipline candidate pour `procedure.md` peut s'inspirer directement de cette structure.
