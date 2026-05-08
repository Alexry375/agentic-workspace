---
name: genius
description: "Use when investigating bugs, making architectural decisions, or claiming behavior of existing code. Verify before probabilizing. Skip trivial L1 lookups."
---

# Genius

Avant toute affirmation ou fix : **sépare claim factuel et interprétation**.

## 1. Classifier

| Niveau | Type | Action |
|---|---|---|
| L1 | Syntaxe / typo / claim factuel direct | Read/Grep d'abord, puis affirme. **Pas de probas.** |
| L2 | Logique / état | Hypothèses → vérifie la moins chère → fix |
| L3 | Architecture | Propose 2-3 approches → l'humain choisit → implémente |
| L4 | Méta / environnement | STOP code. Infra (RAM, réseau, perms). |
| L5 | Multi-systèmes complexe | Invoquer `superpowers:brainstorming` |

Sortie : `Classification: L[N] — [type]`

## 2. Vérifiable ou interprétable ?

**Avant d'écrire `P=X%`, pose-toi la question : est-ce vérifiable par Read / Grep / Bash / WebFetch maintenant ?**

- **Oui → vérifie. Cite `fichier:ligne` ou la commande + output. Pas de proba.**
- **Non, vraie interprétation → hypothèses bayésiennes (§3).**

Si tu te surprends à hedger sur quelque chose que tu pourrais lire → **arrête, lis, reviens avec la réponse vérifiée**.

## 3. Hypothèses bayésiennes (interprétation seulement)

```
1. [hypothèse] — P=X% — Évidence : [fichier:ligne ou observation précise]
2. ...
3. ...
```

Règles dures :
- **Pas d'évidence par hypothèse → la proba ne s'écrit pas.**
- **Zone 40-70 % interdite** sans verification step explicite (genre "je vérifie X").
- Si "je vérifie X" écrit → l'action suivante **doit** être Read/Grep/Bash sur X. Sinon = engagement non tenu = restart §1.
- Après chaque vérification, **mets à jour les probas**. Si elles ne bougent pas, tu confirmais, tu n'investiguais pas.

## 4. Iron Law avant claim

**NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.**

Avant d'écrire `done`, `tests passent`, `fixé`, `marche` : commande exécutée + output cité **dans la même réponse**, ou comportement observé + élément précis vu (capture, valeur, log).

## 5. Impact Report (fix complexes uniquement)

```
BEFORE: [comportement observable actuel]
AFTER:  [ce qui change]
RISK:   [ce qui peut casser]
VERIFY: [commande de test concrète]
```

## Red Flags → restart §1

- "C'est évidemment X" sans Read/Grep préalable
- Proposition de fix < 10 s après énoncé du problème
- Proba sans `fichier:ligne` ou observation citée
- Claim `done` sans evidence dans la même réponse
- "Je vérifie X" écrit puis action suivante ≠ vérifier X
- Confidence sans alternative listée
