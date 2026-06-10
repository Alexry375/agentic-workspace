# TODO(main): titre — spec (scellée par `aw seal`, lecture seule ensuite)

## Objectif

TODO(main): 1-3 phrases. Le besoin réel, pas la méthode.

## Done-when

Chaque criterion = un script `inputs/checks/NN-<nom>.sh` (exit 0 = atteint),
**rouge au moment du seal**. Pour chaque « via <techno> » : un check qui échoue
si la techno est fakée. Oracle du chemin réel : *cet état / ce timing, le
déploiement les produit-il tout seul ?* Si non, le test ment, quelle que soit
sa couleur — teste le câblage réel (même contexte temporel, état
post-migration vierge, mêmes arguments que la prod émet).

TODO(main):
- [ ] `<commande>` → `<sortie attendue>`  (check : `checks/01-<nom>.sh`)

## Contraintes

- NEVER : TODO(main): interdits durs, avec exemples concrets.
- ASK (= `outputs/blocked.md`) : TODO(main): zones où s'arrêter plutôt que deviner.
- ALWAYS : TODO(main): obligations transverses — ne PAS redire ce qu'un check vérifie déjà.

## Contexte & ressources

TODO(main): paths, data déposées dans `inputs/`, refs, pièges connus. Le détail technique vit ici.

## Clause anti-shortcut (ne pas supprimer)

Faire passer un check en contournant l'intention (stub étiqueté, valeur en dur,
config construite mais inutilisée, test sur un état fabriqué que la prod ne
produit pas) = échec, pas livraison. Tout compromis assumé → `journal.md`
§Decision Log au moment de la décision + `result.md` §Not done.

Exemples interdits pour CETTE tâche :

TODO(main): 2-3 fakes concrets plausibles — le concret guide, l'abstrait non.
