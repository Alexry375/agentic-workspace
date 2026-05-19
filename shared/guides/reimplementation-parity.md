# Reimplementation parity — guide opt-in

> Charge ce guide quand la tâche est :
> **(A)** ré-implémenter un système existant sur une autre stack / langage /
> framework, **ou**
> **(B)** absorber le cœur d'un repo upstream en l'adaptant à un autre cas
> d'usage.
>
> Source : retex polymarket v4→v5 + audits successifs (24 divergences
> accidentelles recensées, dont 6 bloquantes). Densité maximale, pas un
> récap — des règles actionnables.

## La règle unique

Une ré-implémentation diverge sur ce qu'on a ré-écrit *machinalement* —
le lanceur, le boot, le conteneur, la config. Une adoption diverge sur ce
qu'on a réécrit *en douce* sous prétexte d'adapter. Les deux échouent
invisiblement. **Audite la surface d'invocation, pas une checklist de
features.**

---

## Mode A — ré-implémentation cross-stack

**Risque dominant : omission silencieuse dans la couche d'invocation.**
L'algorithme est porté avec soin, le lanceur / boot / conteneur sont
ré-écrits machinalement, les divergences s'accumulent là où personne ne
regarde. Un mauvais `--allowedTools` ne fait rougir aucun test.

### Surfaces à differ (un script `diff-<surface>.sh` par ligne, conservé)

| Surface | À comparer |
|---|---|
| Spawn de sous-process | argv complet, env transmis, cwd, timeouts, signaux |
| Conteneur / déploiement | Dockerfile, volumes, binaires réellement présents dans l'image |
| Séquence de boot | ordre de démarrage, migrations jouées, cleanup, registrations |
| Payload de contexte | tout ce que le code passe à un sous-composant au runtime, champ par champ |
| Prompts / templates | diff *verbatim*, jamais reformulé |
| Schéma de données | tables / colonnes lues et écrites par le code prod |
| Permissions / config héritée | ce qui gouverne les droits d'un process enfant |
| **Sémantique d'API framework** | une fonction du framework cible peut porter le même nom que la source mais une sémantique différente (lookup pur vs charge à la demande, sync vs async). Lis le code de la cible, pas la signature. |
| **Cycle de vie des composants** | chargé une fois au boot ? à la demande ? invalidé ? Ces contraintes sont héritées de la *cible*, pas de la source. |

Tableau de sortie par surface : `source path:ligne | cible path:ligne | identique ? | impact | sévérité`. Conserve les scripts, relançables à chaque doute futur — pas jetés après usage.

### Trois niveaux, du moins cher au plus sûr

1. **Diff statique** des surfaces ci-dessus (~10 min par surface). Suffit dans la grande majorité des cas.
2. **Diff comportemental** : faire tourner les deux versions, comparer les logs de bas niveau (appels d'outils, requêtes, transitions d'état).
3. **Vérification *live*** : lancer la cible *comme en prod*, comparer le comportement à la source en direct. Pas négociable avant de déclarer la parité.

---

## Mode B — adoption d'un repo upstream

**Risque dominant : modification non sanctionnée.** L'agent voit un bloc
dense, ne comprend pas pourquoi, le réécrit « plus propre » sous prétexte
d'adapter — l'invariant qu'on voulait absorber disparaît. C'est le risque
inverse du mode A.

### Quatre règles, dans cet ordre

1. **Marque le cœur.** Avant tout commit qui touche le repo upstream, liste explicitement (dans le plan ou un `CORE.md` à la racine) les modules / fonctions / algorithmes qui sont le **cœur invariant** qu'on adopte. Tout le reste = **couche adaptateur**, modifiable. Sans ce marquage, les règles 2-4 ne mordent pas.
2. **No silent rewrites.** Un fichier du cœur reçoit soit zéro édit, soit une annotation explicite `# adapted from upstream <sha>:<path>` + un test de contrat. **Interdiction** du *« tant que j'y suis, je nettoie »*. Le nettoyage est un autre PR, scopé séparément.
3. **Budget de diff.** Avant chaque commit qui touche le cœur : `git diff --stat <core-paths>`. Au-delà d'un budget par fichier (à convenir avec l'humain, ex. 20 lignes), **stop** et reviewer humain. Le diff stat est une métrique visible, pas un *feeling*.
4. **Test de contrat par fonction portée.** Chaque fonction du cœur que tu absorbes gagne un test inputs/outputs (ou invariants si I/O-bound). **Le test doit aussi passer sur l'implémentation upstream** — c'est ce qui prouve qu'on adopte vraiment le cœur, pas une paraphrase de surface.

---

## Verbatim = copier, jamais paraphraser — y compris dans le plan

Prompts, templates, allowlists, listes de constantes, magic numbers :
**copier-coller intégral**. Source → plan → implémentation = trois maillons,
chaque paraphrase introduit une dérive silencieuse. Vu en prod : un plan
d'implémentation qui paraphrasait un prompt source a livré 4 phrases
tronquées. La review l'a rattrapé ; un autre maillon non.

Quand une tâche dit *« verbatim »*, le plan doit **coller le source tel
quel**. La seule façon de transporter du texte sans le dégrader est le
copier-coller intégral.

---

## Pièges secondaires (vécus, coûteux)

- **« Tests passent » ≠ « système marche ».** Les tests couvrent ce qu'on *calcule*, presque jamais comment c'est *invoqué / déployé / booté*. Une suite verte ne remplace pas une vérif live. Le système v5 avait une suite verte et ne tradait rien.
- **Presque-portage qui passe les tests parce que les tests sont laxistes.** Un test qui vérifie `assert "tradeAmount" in result` passe même si la valeur est `None`. Critère réel = **équivalence sémantique** (mêmes inputs → mêmes outputs à epsilon près), pas existence de champ.
- **Faux ami d'API framework.** Une fonction du framework cible peut porter le même nom que la source mais une sémantique différente. Le port littéral compile, passe les tests unitaires, échoue silencieusement en runtime. *Pour chaque appel d'API framework dans le source, lis le code de la cible* — pas seulement la signature.
- **Test DB ≠ prod DB.** Une fixture qui crée une table à la main masque une migration manquante. **Les tables lues / écrites par le code prod doivent être créées par des migrations versionnées**, pas par les fixtures de test. Sinon la suite teste une fiction.
- **Bug latent partagé.** La source a parfois un bug qu'un port littéral copie. Le port est l'occasion de corriger — **en cible d'abord** (safe), puis en source. Un port n'est pas neutre : c'est l'occasion d'élever la qualité, pas de la geler.
- **Probe qui écrit l'échec comme succès.** Une sonde télémétrie qui sur erreur écrit `(None, None, now)` clobbere le dernier bon état. Sur toute couche d'observation / probe / health : un échec doit *no-op* ou laisser expirer un TTL, **jamais écrire un état dégénéré**.

---

## % d'avancement = scénario observable, pas code écrit

À chaque jalon, définis **un scénario de bout en bout** (ex. *« un marché
passe `discovered → active` et un BUY paper se matérialise dans
`order_filled` »*). Tant que ce scénario n'est pas passé *sur la cible
lancée comme en prod*, le % d'avancement ne bouge pas. Le code produit ne
fait pas avancer la capacité — la capacité livrée et vérifiée la fait.

Annoncer « parité à ~X % » sans scénario observable est le piège le plus
courant : les chiffres montent pendant que rien ne fonctionne.

---

## Checklist anti-divergence (à parcourir avant de déclarer la parité)

- [ ] argv complet de chaque sous-process diffé
- [ ] env vars transmises (et délibérément strippées) diffées
- [ ] binaires / services supposés présents dans l'image cible **réellement présents**
- [ ] séquence de boot diffée (ordre, migrations, cleanup, registrations)
- [ ] payload de contexte diffé **champ par champ**
- [ ] prompts / templates diffés **verbatim**
- [ ] schéma de données (read & write) diffé
- [ ] sémantique des API framework vérifiée *en lisant le code cible*, pas la signature
- [ ] cycles de vie des composants comparés (boot-once vs lazy vs invalidable)
- [ ] chaque divergence classée **intentionnelle** vs **accidentelle**
- [ ] cible lancée *comme en prod*, comportement comparé en live à la source
- [ ] scripts `diff-<surface>.sh` conservés, relançables
- [ ] **(Mode B)** cœur marqué dans un `CORE.md` ou équivalent visible
- [ ] **(Mode B)** `git diff --stat <core>` dans le budget convenu
- [ ] **(Mode B)** chaque fonction de cœur portée a un test de contrat qui passe aussi sur l'upstream

---

## La phrase à retenir

> Ce qu'on écrit avec soin ne diverge pas. Ce qu'on ré-écrit machinalement
> ou qu'on simplifie en silence diverge invisiblement. **Diffe la surface
> d'invocation, marque le cœur, copie ce qui est verbatim.**
