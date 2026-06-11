# Retex — v2 « contrat scellé », premier lot complet en conditions réelles (WS3 operator-liveness)

- **Date** : 2026-06-11
- **Déclencheur** : premier usage de bout-en-bout de la v2 sur un vrai lot — **8
  workspaces** d'un duel inter-modèles (tâche backend `operator-liveness`, ~200–700
  lignes Python), dont **4 sous v2** (surface imposée + checks scriptés + holdouts)
  et 4 sous v1 (surface libre, audit manuel), comme groupe témoin.
- **Auteur** : main (Claude Code, côté orchestrateur + auditeur du duel).
- **Complément de** : `2026-06-11-v2-redesign-contract-sealed.md` (la décision
  d'architecture). Ce report ne re-théorise pas la v2 — il rapporte ce qu'elle a
  **coûté et produit** une fois branchée, avec des chiffres.

---

## TL;DR

La v2 **tient ses promesses sur l'auditabilité et l'anti-reward-hacking** : les
holdouts cachés ont parfaitement discriminé, l'audit était reproductible, l'anti-
shortcut était propre chez les 4 agents v2. **Mais** le ratio coût/bénéfice penche
négatif pour ce type de tâche, pour trois raisons mesurées :

1. **Coût de préparation élevé et frontal** : écrire les checks + concevoir une
   surface stable + vérifier le rouge-sur-vierge a pris nettement plus de temps que
   préparer un prompt v1 en prose — **avant** qu'un seul agent démarre.
2. **Deux effets pervers non anticipés** : (a) fournir les checks a fait **chuter
   les tests internes** des agents (v2 : 3 agents sur 4 → **0 test** ; v1 : 9–28
   tests) ; (b) la **surface imposée bride le jugement de design**, qui était
   justement le signal le plus discriminant en duel.
3. **Friction runtime** : un check fragile (faux-rouge structurel, §3) a pollué la
   session des **4** agents v2 en cours, pas seulement le temps de l'écrire.

Le constat fonctionnel d'Alexis — *« ça a pris plus de temps à préparer ET ça a
freiné la progression »* — est **confirmé et objectivable**. Reco principale :
rendre le contrat scellé **optionnel par tâche** et **réduire le coût des checks**
(helpers + check no-regression canonique), plutôt que l'imposer partout.

---

## 1. Ce qui a coûté du temps — la préparation

La v2 déplace le travail vers l'amont : le done-criteria n'est plus une phrase, c'est
un script qui doit être **rouge sur vierge pour la bonne raison**. Pour WS3 ça a
voulu dire, avant tout lancement :

- Écrire **6 checks** bash (`01-reminder-states` … `06-shipped-no-regression`) +
  **2 holdouts** cachés (`h1` isolation, `h2` bornes à la seconde).
- **Concevoir une surface stable imposée** (noms de fonctions, dataclass, table,
  migration) — *nécessaire* pour qu'**un** check puisse taper sur **4**
  implémentations différentes. C'est le poste de coût caché : sans surface imposée,
  un check par implémentation = ingérable.
- Vérifier que chaque check est **rouge sur vierge** — et pour la bonne raison (cf.
  §3, ce n'est pas garanti par le gate).

En v1 (témoin), la préparation = un prompt en prose + des ancres `path:line`. Bien
plus rapide à produire. **L'écart de temps de prép v1→v2 est réel et important**, et
il est payé intégralement **avant** que la moindre session d'agent tourne — donc en
temps mort de throughput.

> Le design doc présente « done-criteria = scripts » comme un gain (et c'en est un à
> l'audit). Il ne chiffre pas le **coût d'écriture** pour la main, ni le fait que la
> surface imposée est un **prérequis** dès qu'on veut N implémentations comparables.

## 2. Ce qui a freiné les agents — deux effets pervers

### 2.a — Fournir les checks tue l'incitation à tester (donnée)

| Lot | Tests internes écrits par l'agent |
|-----|-----------------------------------|
| **v2** (checks fournis) | **0, 0, 0, 19** — 3 agents sur 4 à zéro |
| **v1** (pas de checks) | **14, 28, 18, 9** — les 4 en ont écrit |

En v2, 3 des 4 agents ont traité **les checks fournis comme leur suite de tests** et
n'ont rien ajouté (plancher de non-régression atteint *pile*, surface neuve sans
couverture interne). En v1, privés de filet, les 4 ont construit une vraie
couverture. **Le contrat scellé, en donnant les tests, retire la raison d'en
écrire.** C'est une partie directe du « ça freine la qualité ».

### 2.b — La surface imposée bride le jugement de design

Pour que les checks soient uniformes, on impose les noms. Conséquence en duel : les
4 v2 ont **la même surface** → on perd la dimension « où placer la logique, quelle
convention, quelle modélisation » — qui était, dans le lot v1, **le signal le plus
discriminant** (les meilleurs s'y séparaient nettement des autres). v2 mesure
**bien la correction**, **mal le jugement de conception**.

## 3. Faux-rouge structurel — un angle mort du gate `aw seal`

Le gate #3 du seal exige « chaque check de progrès **rouge** sur le workspace
vierge ». Nécessaire, mais **insuffisant** : un check peut être rouge pour une raison
**parasite** qui ne virera **jamais** au vert, même sur le bon code.

Cas vécu, check `06-shipped-no-regression.sh` : il faisait `pytest -q` et cherchait
la ligne « N passed ». Or le repo cible a `addopts = "-q"` **scellé dans
`pyproject.toml`** → le flag du check s'ajoute → `-qq` → pytest **supprime la ligne
« N passed »** → le `grep` échoue **toujours**, succès comme échec. Le check était
donc rouge sur vierge (gate satisfait) **et serait resté rouge sur le code correct**.

Conséquences concrètes :
- Les **4** agents v2 ont vu `06` rouge en boucle malgré un code juste. **Friction
  runtime** : certains ont modifié `pyproject.toml` (hors surface) pour le verdir,
  un a tracé la divergence — du bruit et du temps perdu, démultiplié par 4.
- Le seal ne l'a **pas détecté** : il vérifie « rouge sur vierge », pas « vire au
  vert sur l'état-cible ».

Correctif appliqué de mon côté : lancer pytest avec `-o addopts="-q"` pour
neutraliser le `addopts` scellé. Mais **le gate aurait dû l'attraper**.

## 4. Ce qui a très bien marché (à préserver absolument)

La v2 n'est pas à jeter — son cœur fonctionne :

- **Holdouts cachés = signal en or.** `h1` (isolation par `strategy_id` + double
  effet fichier/DB) et `h2` (bornes exactes à la seconde) ont été passés par les
  **4** v2 → preuve **objective** de correction, impossible à reward-hacker (jamais
  mentionnés dans le workspace). C'est la meilleure brique de la v2, exactement
  comme la littérature (SpecBench/ImpossibleBench) le prédisait.
- **Auditabilité reproductible.** À l'audit, rejouer 6 checks + 2 holdouts
  **uniformément** sur 4 implémentations = rapide, déterministe, non subjectif. En
  v1, l'audit manuel était plus lent et plus discutable.
- **Le gate « rouge sur vierge » a fait son travail** dans l'autre sens : mon check
  `06` était initialement **quasi-vert** au seal (332 passed est déjà le plancher
  sur vierge) — le gate m'a forcé à le durcir (`import liveness` + count). Le
  mécanisme attrape les checks non-discriminants.
- **Anti-shortcut propre chez les 4 v2** (clause + NEVER/ASK/ALWAYS + holdouts) :
  aucun mock du livrable, trace en table requêtée, états réellement dérivés de
  `now`. Le cadrage anti-shortcut de la v2 **tient**.

## 5. Confrontation aux risques que le design doc avait anticipés

- **Risque 1 « théâtre de contrat » (checks vacueux verts au 1er run)** : pas
  observé sous cette forme, mais sa **face cachée** l'a été — un check **toujours
  rouge** par fragilité structurelle (§3). À ajouter à la surveillance.
- **Risque 3 « sur-production de blocked.md »** : observé **1×**, mais pour une
  cause différente (migration v1→v2 en cours de lot — voir §6), pas par rigidité du
  contrat. La règle « contester un check dans §Not done et livrer quand même »
  n'aurait pas aidé ici.

## 6. Incident annexe — l'upgrade de CLI casse les workspaces déjà montés

Basculer le symlink `aw` vers la v2 **pendant** qu'existaient des workspaces v1 non
scellés a fait **refuser `aw start`** (« spec non scellée »). L'agent concerné a
écrit `blocked.md` (bon réflexe), mais c'est une friction évitable. → **Versionner
le workspace** (champ version au `aw new`) pour que la CLI applique le comportement
de la version qui l'a créé, ou offrir un mode compat.

## 7. Recommandations (priorisées)

1. **Rendre le contrat scellé optionnel par tâche.** Deux modes : *(a)* « léger »
   (prose v1 + 1–2 holdouts cachés) pour le design ouvert / les duels de conception
   et les tâches peu scriptables ; *(b)* « scellé complet » pour les tâches
   backend-invariantes à fort risque de reward-hacking. Le **holdout** est le
   commun dénominateur à garder dans les deux. *(le coût de prép des checks ne se
   justifie pas partout.)*
2. **Durcir le gate seal contre les faux-rouges structurels.** En plus de « rouge
   sur vierge », **avertir** sur les checks qui dépendent de la config scellée du
   repo (`addopts`, `pytest.ini`, `conftest`) ; idéalement, exiger une preuve que le
   check **vire au vert** sur un état-cible fourni par la main (un patch-témoin), ou
   au moins le recommander.
3. **Fournir un check `no-regression` canonique** dans `aw` (qui neutralise
   `addopts` via `-o addopts=…` et parse le count proprement) — pour que chaque
   orchestrateur ne réécrive pas le check 06 buggé. Plus largement : une petite
   **bibliothèque de checks** réutilisables (table existe, migration round-trip,
   spy backend, no-regression) réduirait massivement le coût de prép (§1).
4. **Contrer la chute des tests internes (§2.a).** Soit un done-criterion standard
   « tes propres tests ajoutent ≥ N cas » (vérifiable par delta de count), soit une
   ligne explicite dans le squelette `prompt.md` : *« les checks fournis ne sont pas
   ta suite de tests — ils sont le minimum ; ajoute ta couverture »*.
5. **Documenter le compromis surface imposée (§2.b).** Marquer clairement que le
   contrat scellé convient aux tâches **backend-invariantes**, pas aux tâches où le
   **jugement de design** est le livrable (ni aux duels de conception). Piste plus
   ambitieuse : checks « comportementaux » via un **point d'entrée unique** que
   l'agent câble lui-même (un adaptateur), pour ne pas figer toute la surface.
6. **Versionner les workspaces (§6)** pour qu'un upgrade de CLI ne casse pas l'existant.

## 8. Verdict

La v2 est une **vraie avancée pour la mesure** (holdouts + auditabilité + anti-
shortcut), et il faut la garder pour ce à quoi elle excelle. Mais sur ce lot elle a
**coûté plus en préparation** et **freiné les agents** (0 test, design bridé, bruit
du faux-rouge) — exactement le ressenti d'Alexis. Le bon cap n'est pas « v1 ou v2 »
mais **« holdout partout, contrat scellé là où il paie »** + **réduire le coût des
checks** pour que la v2 cesse d'être un impôt fixe sur chaque tâche.

> Réserve : **n = 1 lot, 1 famille de tâche** (backend Python). Les effets mesurés
> (chute des tests, friction du faux-rouge) sont nets, mais leur généralité demande
> 2–3 lots de natures différentes pour être confirmée.
