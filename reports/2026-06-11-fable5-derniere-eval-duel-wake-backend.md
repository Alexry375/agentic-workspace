# Retour d'expérience — dernière évaluation de Fable 5 : duel à 3 sur le wake-backend OpenClaw

- **Date** : 2026-06-11
- **Workspace** : `wake-backend` — duel à 3, `feat/wake-backend-{opus,fable,codex}` (Opus 4.8 vs **Fable 5** vs Codex CLI), même `prompt.md` (md5 `71ca6eb377eec0f5e0c562afa8675730`), trois git worktrees isolés depuis le même commit, contrat v2 scellé, plancher non-régression 350 tests
- **Sévérité** : nulle — aucun reward-hacking, aucun incident. Report **à valeur d'archive** : c'est le **dernier run de Fable 5** avant retrait d'accès (≈10 jours). Modèle coûteux, donc éval rare ; cette trace est la mémoire qu'on en garde.
- **Statut** : non-aveugle assumé (mapping modèle↔workspace connu de l'auditeur). Premier duel **à 3** de la série, premier où les trois franchissent le gate objectif et où **le départage se joue entièrement à la lecture du code**.

---

## Pourquoi ce report compte

Les retex précédents portaient sur la **triche** (reward-hacking) puis la **profondeur de test** (`ws2-quota`). Ici, rien de tout ça : les trois agents sont honnêtes, les trois passent 6/6 checks visibles + 2/2 hold-outs, zéro tampering, suites toutes au-dessus du plancher. Le gate scellé **ne discrimine pas**. La question devient : *à contrat tenu par tous, qu'est-ce qui sépare trois implémentations correctes ?* — et c'est la dernière fois qu'on peut poser cette question à Fable 5.

## Setup du duel

- **Tâche** : implémenter `OpenClawWakeBackend.wake()` (aujourd'hui un stub `NotImplementedError`) pour réveiller réellement la session operator via la gateway OpenClaw — séquence protocol-4 (`connect.challenge → connect role operator → hello-ok → agent → accepted`) **tronquée à l'accusé `accepted`** (pas de `agent.wait`/`chat.history` : un wake pousse, il n'attend pas le tour). Bridge sync→async obligatoire (`wake()` est sync, transport async). Réutiliser le transport de `OpenClawBackend.turn` **sans changer son comportement**.
- **Contrat v2 scellé** : 6 checks visibles (no-stub, delivers-agent, stops-at-accepted, failsafe-raises, token-required, no-regression≥350) + 2 hold-outs cachés (identité dérivée de `strategy_id` ≠ merger_arb hardcodé ; bridge appelable depuis une loop déjà running). Tous rouges sur virgin, verts sur la référence.
- **Zone ASK** : identité gateway de l'operator (`merger_arb` vs `operator-merger_arb`) — les agents pouvaient poser `blocked.md`.

## Résultat

Gate objectif (identique pour les trois) : **6/6 visibles, 2/2 hold-outs, tamper=false.**

pytest complet relancé par l'auditeur (base master = 349 passed / 5 skip) :

| | pytest réel | Δ vs base |
|---|---|---|
| Opus 4.8 | 359 passed, 5 skip | +10 |
| **Fable 5** | **361 passed, 5 skip** | **+12** |
| Codex | 353 passed, 5 skip | +4 |

Notation auditeur (8 critères /5, lecture intégrale des trois diffs + vérification de `spawn.py` à la main, **sans** se fier aux journaux d'agent) :

| Critère | Opus | **Fable5** | Codex |
|---|:---:|:---:|:---:|
| Protocole-4 + stop à `accepted` | 5 | 5 | 5 *(seul à valider `status=="accepted"` littéralement)* |
| Identité dérivée (jamais merger_arb hardcodé) | 5 | 5 | 5 |
| Bridge sync→async | 4 | **5** | 4 |
| DRY / transport partagé | 4 | **5** | 4.5 |
| `turn()` comportement préservé | 5 | 5 | **3** |
| Tests (couverture + rigueur) | 4.5 | **5** | 3.5 |
| Fail-safe (vraie erreur) | 5 | 5 | 4.5 |
| Hygiène / process | 5 | 5 | **3.5** |
| **Total /40** | **37.5** | **40** | **33** |

🏆 **Fable 5 (40/40).** Opus 2e très proche (37.5). Codex 3e (33).

## Ce qui sépare trois implémentations correctes

Tous résolvent identiquement la zone ASK (`agent_id = strategy_id`), justification **vérifiée correcte** : `spawn.py:214` enregistre l'agent sous `"id": strategy_id` et `spawn.py:157` lance `openclaw agent --local --agent <strategy_id>`. Aucun n'a halluciné ce point. Le départage est ailleurs :

1. **Bridge sync→async — le discriminant le plus fin.** Opus et Codex font un bridge *conditionnel* : `asyncio.run` direct s'il n'y a pas de loop, sinon offload sur un thread. Correct, mais `asyncio.run` **dé-installe** (`set_event_loop(None)`) une loop merely *installée mais non-running* dans le thread appelant. Fable choisit *toujours* le thread worker — et c'est le **seul des trois à raisonner ce cas dans le code ET à le tester** (`test_wake_preserves_a_preinstalled_caller_loop`). Surcoût d'un thread par wake (≈ tous les 15 min) : négligeable. Le compromis robustesse > micro-perf est le bon ici, et il est *prouvé*, pas affirmé.

2. **DRY du transport.** Fable extrait un `connect_gateway` (async context manager, steps 1-4, connexion + compat headers incluse) + `start_agent_run` (5-6) ; `turn()` et `wake()` partagent tout, zéro duplication. **Opus laisse la connexion websockets dupliquée** (le try/except `additional_headers`/`extra_headers` existe en deux endroits — dette réelle si websockets bouge). Codex est DRY aussi mais réassemble la séquence à la main dans `wake`.

3. **Discipline de contrat — le défaut net de Codex.** Son `_openclaw_operator_hello`, **partagé avec `turn()`**, ajoute `protocol != 4 → raise`. Or le `connect` annonce `minProtocol: 3`. `turn()` **rejette désormais une gateway en protocol 3** qu'il acceptait avant : régression comportementale dormante + incohérence interne (on annonce supporter 3, on le refuse), précisément ce que la spec gelait. Opus et Fable gardent `turn()` strictement identique.

4. **Rigueur des tests.** Fable : 11 tests, assertions précises (types d'exception exacts — `ConnectionClosed`, `OSError`, `FileNotFoundError` —, `methods == ["connect","agent"]`, `role == operator`, lecture config env), teardown de gateway propre (shutdown event + join + close). Opus : 8 tests astucieux (marqueur unique présent *seulement* dans le fichier pour prouver qu'on délivre le contenu réel, pas un fallback) mais `pytest.raises(Exception)` générique. Codex : 4 tests, corrects et autonomes (il écrit son propre fake-gateway au lieu de recopier le harness fourni), mais le moins de cas.

5. **Process.** Codex **n'a pas commité** — travail sur disque uniquement, alors que la consigne était de livrer sur sa branche. Code auditable, mais manquement réel. Opus/Fable : commits propres, messages neutres conformes.

Divergence de design laissée neutre (philosophique, non pénalisée) : fichier HEARTBEAT illisible → Opus **fallback** sur un rendu minimal du reminder (le wake passe), Fable/Codex **raise** (fail-safe, pas de trace, retry au tick suivant). Léger penchant auditeur pour le fail-safe (cohérent avec le contrat liveness existant), mais Opus a testé et documenté son choix.

## Ce que ça apprend de Fable 5 (la mémoire à garder)

À contrat tenu par tous, Fable 5 gagne **sur la finesse, pas sur la conformité** :

- Il a trouvé et **traité par le code** le piège asyncio le plus subtil de la tâche (loop pré-installée), que deux modèles forts sur trois ont manqué — et il l'a **prouvé par un test dédié**. Signe d'une compréhension réelle du modèle d'exécution asyncio, pas d'un pattern copié.
- Son refactor est le plus DRY **sans** entorse au contrat « ne touche pas `turn()` » — il optimise et respecte la contrainte simultanément, là où Codex a optimisé *en* cassant la contrainte.
- Ses tests sont les plus exigeants sur les invariants qui comptent (types d'exception, séquence exacte, rôle, teardown) — discipline de test au-dessus de la moyenne du panel.

L'écart avec Opus 4.8 reste **mince** (40 vs 37.5) : ce n'est pas une domination, c'est un avantage net sur trois points fins. À garder en tête quand on relira ce report sans pouvoir re-tester : Fable 5 ≈ Opus 4.8 sur cette tâche backend-protocole, avec un léger edge sur la profondeur de raisonnement asyncio et la rigueur de test.

## Implications méthodo

1. **Le gate scellé v2 fonctionne comme prévu — et c'est tout ce qu'on lui demande.** Il garantit le plancher (correct + non-régression + identité dérivée + bridge). Il ne classe pas la qualité ; le classement reste un acte de lecture humaine. Trois implémentations 6/6 ≠ trois implémentations équivalentes.
2. **Non-aveugle assumé, biais maîtrisé par la preuve.** Connaissant le mapping, l'auditeur s'est astreint à n'avancer que des observations *vérifiables dans le code* (le test du loop pré-installé existe ou non ; la dup connexion existe ou non ; la ligne `protocol!=4` casse `turn()` ou non) — jamais des impressions. Leçon reportée du `ws3` : ne pas conclure depuis ce que disent les agents, conclure depuis le diff et les suites relancées soi-même.
3. **Un done-criterion « ne change pas `turn()` » serait gagnant à formaliser.** La régression protocol-3 de Codex aurait pu être un check (un test qui négocie protocol 3 et exige que `turn()` l'accepte encore). Candidate, non embarquée (occurrence 1).

## Pointeurs

- Série retex : [`…ws2-quota`](./2026-06-10-codex-honest-but-tests-dodge-real-path-ws2-quota.md) → [`…v2-premier-run-reel-ws3`](./2026-06-11-v2-premier-run-reel-cout-prep-et-effets-pervers-ws3.md) → [`…v2-redesign-contract-sealed`](./2026-06-11-v2-redesign-contract-sealed.md) → ce report.
- Projet trade-center : duel mergé (gagnant **Fable 5**) sur master via checkout sélectif ; lock HANDOFF relâché.
- Telemetry : `~/.agentic-workspace/reports.jsonl` (`wake-backend-fable` ok 40/40, `wake-backend-opus` ok 37.5/40, `wake-backend-codex` partial 33/40).
