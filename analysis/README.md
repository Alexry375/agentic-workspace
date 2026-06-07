# analysis/ — méta-études des workspaces terminés

Pour piloter l'évolution de `procedure.md` autrement qu'à l'aveugle : on
parcourt les workspaces `ok` / `ko` / `partial` du `reports.jsonl`, on
reconstruit la cause racine de chaque livraison qui a fait défaut, et on
juge si une discipline ajoutée (test, audit, prompt) aurait changé l'issue.

## Grille

Chaque analyse vit dans `analysis/<workspace-name>.md` et suit ce schéma :

```markdown
# <workspace-name>

- **Date livraison** : YYYY-MM-DD
- **Outcome reports.jsonl** : ok / ko / partial
- **Localisation** : `/path/to/workspace`

## Cause racine

<Une à trois phrases : qu'est-ce qui a vraiment fait défaut ? On parle du
problème de fond, pas du symptôme rapporté.>

## Tests existants

<Ce qui était en place côté validation au moment de la livraison
(unitaires ? intégration ? métriques ? hold-out ?).>

## Un test aurait-il aidé ?

<oui / non / partiellement>

<Si oui : type précis (unit / intégration / mutation / validité métrique /
E2E visuel / annotation humaine) + formulation concrète. Si non : ce qui
aurait aidé à la place (audit, prompt, contrainte de cadrage).>

## Leçon généralisable

<Ce qui mérite éventuellement d'entrer dans procedure.md, ou de rester en
note ici. ≥3 occurrences avant inclusion.>
```

## Workflow

1. Lire `inputs/prompt.md`, `outputs/result.md`, `outputs/audit-report.md`,
   les artefacts livrés (code, données), et la ligne reports.jsonl
   correspondante.
2. Rédiger `analysis/<name>.md` selon la grille.
3. `touch <workspace>/.analyzed` pour marquer le workspace.
4. Mettre à jour l'index ci-dessous.

## Source de vérité

L'index ci-dessous est canonique. Le flag `.analyzed` à la racine du
workspace est une commodité locale (peut être absent ou divergent — fais
confiance à ce fichier).

## Index

| Workspace | Outcome | Cause racine résumée | Test aurait aidé ? |
|---|---|---|---|
| [uk_clml_implementation](uk_clml_implementation.md) | ko | Métrique "non-circulaire" `content_correctness` était en fait circulaire (X==X via même `normalize_for_compare`) | partiellement — mutation test sur la fonction diff l'aurait détecté ; cause de fond = annotation humaine indépendante silencieusement abandonnée |
| [webapp-cinematic](webapp-cinematic.md) | ko | Choix archi `<Html transform>` incompatible avec spec "écran prend tout le viewport" (overlay 2D ≠ texture 3D zoomable) | partiellement — assertion géométrique `bbox/viewport ≥ 0.9` aurait attrapé le symptôme ; pas le mauvais choix de stack en amont |
| [objets-trouves](objets-trouves.md) | partial | Agent a livré un scaffold A→F au lieu d'un pipeline qui produit une shortlist réelle ; Phase A en `DRY_RUN=True` | partiellement — un E2E `run --fixtures && test -s shortlist*.md` aurait piégé "scaffold ≠ exécution" |
| [objets-trouves-v2](objets-trouves-v2.md) | partial | Phase B rattachait au référentiel sans valider la cohérence du triplet (marque + focale + monture) → 22/26 faux positifs | oui critique — eval set annoté de 20-30 cas + test unitaire lens-mismatch |
| [bounty](bounty.md) | partial | Pas de gate de dédoublonnage vs corpus d'exclusion V12 avant PoC → 4/5 findings hors-scope, ~600k tokens gaspillés | oui — gate scope-check L1 avant toute vérification coûteuse |
| [etoro](etoro.md) | partial | Modèle ping-pong engagé sans mesurer la fenêtre de validité du refresh token → capture échoue après départ humain | oui — probe de durée de vie + faisabilité avant capture humaine |
| [font-size-fda](font-size-fda.md) | partial | Métrique `≥90% accuracy` acceptée sans baseline triviale ni annotation humaine sur images réelles (ground-truth 100 % synthétique) | partiellement — baseline dummy + sanity-check distribution + annotation humaine sur ≥5 cas réels |
| [audit-conformite](audit-conformite.md) | partial | Tool `Agent` indispo détecté tardivement (après harvest) → bascule fallback mono-Opus | oui — capability probe au boot (~30 s) sur tout tool critique |
| [natas](natas.md) | ok | Tâche L1-L2 déterministe + vérif empirique `curl` HTTP 200 = preuve directe ; one-shot Agent intra-session | partiellement — pour L1-L2 la vérif empirique suffit ; tests unitaires deviennent critiques en L3+ inférentiel |
| [relay_x_formex_finalize](relay_x_formex_finalize.md) | ok | Solide globalement ; mini-incident sur suppression `pictogrammes/` validée par sub-agent d'audit qui a vérifié au mauvais path | oui — test prérequis déclaratif avant toute action destructive (~5 lignes) |
| [audit-monsantorin](audit-monsantorin.md) | ok | Audit textuel pur, 12 findings tracés ligne-par-ligne, risque hallu ≈ 0 % car méthode non-spéculative | partiellement — 4/12 findings dynamiques gagneraient à exécution (B2/B3/B7/B8) ; lecture suffit pour 8/12 |

## Patterns émergents

11 analyses au 2026-06-07. Récurrences solides (≥3 occurrences = admission `procedure.md` envisageable) :

### 1. Métrique acceptée sans référence indépendante — **3 occurrences ⇒ candidat embarquement**

- `uk_clml` : `content_correctness=1.0` tautologique (X==X)
- `font-size-fda` : `accuracy=87.5 %` sans baseline triviale ni annotation humaine
- `objets-trouves-v2` : flips livrés sans eval set annoté → 22/26 faux positifs masqués

**Discipline candidate** : avant toute claim de métrique, exiger en `result.md` (a) baseline triviale chiffrée, OU (b) ground-truth indépendant de la fonction mesurée, OU (c) eval set annoté avec taux de bruit mesuré. Mutation test pour la circularité quand la métrique est un score sur une fonction qu'on a soi-même écrite.

### 2. Gate prédictive avant action coûteuse ou destructive — **2 occurrences ⇒ veille**

- `bounty` : pas de dédoublonnage scope avant PoC → 4/5 hors-scope, ~600k tokens
- `relay_x_formex_finalize` : pas de prérequis vérifié avant suppression `pictogrammes/` → perte versioning

**Forme** : un test/`grep`/check exécuté **avant** l'engagement de ressources (build, suppression, capture humaine), pas en audit post-hoc. Voir si on retrouve l'invariant dans un 3e workspace.

### 3. Probe de capabilité / faisabilité au boot — **2 occurrences ⇒ veille**

- `audit-conformite` : tool `Agent` indispo découvert après harvest
- `etoro` : Bugcrowd SPA gated découvert après proposition + relance humaine

**Forme** : 30 s de smoke test au démarrage sur tout tool ou ressource externe critique avant d'engager le plan complet.

### 4. Scaffold-only vs livraison exécutée — **1 occurrence claire (+ 1 voisine)**

- `objets-trouves` : pipeline construit, jamais exécuté contre données réelles
- (voisin) `bounty` : 5 PoC techniquement verts mais sur findings non-éligibles

**Forme candidate** : critère DoD "artefact daté en `outputs/`" pour toute spec demandant un résultat exécutif.

### 5. Auto-audit qui rate son propre blind spot — **2 occurrences**

- `uk_clml` : auto-audit renomme "métrique circulaire" en ajoutant une 4e métrique encore circulaire
- `relay_x_formex_finalize` : sub-agent d'audit checke `du -sh` au mauvais path → valide suppression dangereuse

**Discipline existante** : Pattern B step 3 de `procedure.md` (audit critique du créateur à la livraison) couvre la cible. À surveiller : la même blind spot peut frapper le sub-agent d'audit lui-même.
