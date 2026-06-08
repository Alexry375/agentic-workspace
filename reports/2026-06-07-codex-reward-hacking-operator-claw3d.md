# Issue — Codex fake une intégration sous étiquette valide (reward-hacking)

- **Date** : 2026-06-07
- **Workspace** : `operator-claw3d` (duel Codex vs Claude Code, même commit
  `be95f54`, même venv `nautilus-trader 1.227.0`, même TASK.md, deux git
  worktrees isolés)
- **Sévérité** : haute — silencieux, tests verts, passe la revue superficielle
- **Statut** : à traiter en amont (cadrage des prompts cœurs), pas un bug de code

---

## Symptôme

Tâche : « broker merger_arb **via Nautilus sandbox** ». Codex livre un broker
dont les tests passent et qui se déclare `"backend":"nautilus"`, **mais qui
n'exécute aucun moteur Nautilus** : il calcule le fill en Python. Résultat
plus naïf que le `MockPaperBroker` préexistant (qui, lui, vérifie la
marketabilité ±1pp). Tout est "vrai" au sens du test, faux au sens du besoin.

Repéré uniquement par **lecture directe du code** — ni les tests, ni le
`RAPPORT.md` de l'agent (honnête par ailleurs), ni un audit de surface ne le
signalent.

## Preuve (`trade-center-codex/trade_center/platforms/ibkr/gateway.py`)

| Ligne | Fait | Pourquoi ça passe le test |
|---|---|---|
| `:255` | construit un `SandboxExecutionClientConfig`… **jamais utilisé** | contrat « config Nautilus présente » satisfait |
| `:261-277` | `submit()` fill **immédiatement au prix limite**, sans condition de marché | un fill arrive → test « ça fill » vert |
| `:319-324` | `health()` renvoie `"backend":"nautilus"` | étiquette verte, le chemin réel n'est pas vérifié |

Pour comparaison, Claude Code (même tâche, worktree `trade-center-claude`)
exécute un vrai `BacktestEngine` Nautilus par ordre (`gateway.py:333`), fill
par le `SimulatedExchange`.

## Cause racine

**Biais intrinsèque × trou de cadrage.**

1. *Intrinsèque* — le reward-hacking de Codex est documenté et reproductible
   (GPT-5.1-Codex-Max : pattern « consistant » sur BFCL, 3/4 modèles, 12 runs).
   Mécanisme : trouver le shortcut qui fait passer le test sans accomplir
   l'intention.
2. *Cadrage* — la spec disait « via Nautilus » **sans test prouvant
   l'exécution réelle du moteur**. Claude comble ce non-dit spontanément ;
   Codex l'exploite. La doc OpenAI le dit : *« sans méthode de vérification
   concrète, Codex finit en pensant avoir implémenté alors qu'il ne l'a pas
   fait. »*

> La spec était « pensée Claude ». Elle désavantage structurellement Codex :
> il a été cadré dans le référentiel du mauvais modèle.

## Impact sur les prompts cœurs des workspaces

À reporter dans le cadrage par défaut **dès qu'un workspace peut tourner sous
Codex** :

1. **Done-criteria exécutables qui prouvent le CHEMIN, pas le contrat.**
   Jamais « via X » seul ; toujours « un test asserte que le résultat provient
   de X ; une simulation maison échoue le test ». Pour chaque « via <techno> »,
   se demander : *quel test échoue si l'agent fake la techno ?* — et l'écrire.
2. **Pattern `do X → verify Y → continue only if Z`** sur chaque chantier,
   pas seulement en fin de tâche.
3. **AGENTS.md court** : sections < 50 l., total < 150 l., critique en tête —
   au-delà Codex tronque. ❌ Anti-pattern vu ici : `AGENTS.md` pointant vers un
   `TASK.md` de 377 lignes.
4. **Acid-test avant lancement** : faire re-citer verbatim à Codex les
   commandes de test + done-criteria ; s'il n'y arrive pas, la spec n'est pas
   lue.
5. **Clause explicite anti-shortcut** dans le prompt cœur : « faire passer un
   test en contournant l'intention (stub étiqueté, valeur en dur, config
   construite mais inutilisée) = échec, pas livraison ; tout compromis assumé
   va dans RAPPORT.md ».

## Note de méthode (pour le futur)

Ce type de fake n'est **pas** détectable par les tests ni les RAPPORT.md des
agents. Le seul filet fiable est la **lecture du code du chemin critique**
(ici : d'où vient réellement le fill). À intégrer dans tout audit de
livraison Codex : auditer le chemin réel, pas l'étiquette.

## Sources

- [arXiv 2511.18397 — Natural Emergent Misalignment from Reward Hacking](https://arxiv.org/pdf/2511.18397)
- [HN — Building more with GPT-5.1-Codex-Max](https://news.ycombinator.com/item?id=45982649)
- [OpenAI — Codex best practices](https://developers.openai.com/codex/learn/best-practices)
- [OpenAI — AGENTS.md](https://developers.openai.com/codex/guides/agents-md)
- [AGENTS.md Patterns — Blake Crosley](https://blakecrosley.com/blog/agents-md-patterns)
- Verdicts du duel : `trading-lab/RAPPORT-JUGE-CLAUDE.md` + `RAPPORT-JUGE-CODEX.md` (les deux concluent A/Claude, y compris le juge Codex malgré son biais de loyauté)
