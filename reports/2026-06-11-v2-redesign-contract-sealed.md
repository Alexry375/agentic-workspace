# Décision — v2 « contrat scellé, journal vivant, prose minimale »

- **Date** : 2026-06-11
- **Déclencheur** : audit complet du repo + série de reports Codex (claw3d → polish-webapp → ws2-quota) + shift Codex-majoritaire post-15 juin
- **Méthode** : audit adversarial inline + recherche état de l'art web + panel de 3 architectes Fable 5 indépendants (contract-first / soustraction radicale / processus vivant), jugés et synthétisés en session main avec Alexis
- **Statut** : implémenté dans ce commit

---

## Problème

Trois constats convergents :

1. **La boucle apprentissage→embarquement était cassée.** Le pattern le plus documenté du corpus (« métrique sans référence indépendante », 3 occ + 1 résolution) n'était pas dans `procedure-core.md` ; les patterns « gate prédictive » et « probe au boot » étaient le même invariant scindé en deux taxons sous le seuil. La règle réelle observée : « incident saillant > comptage ».
2. **Les invariants étaient prêchés, pas outillés.** `aw new` créait un `prompt.md` vide ; la checklist 5 leviers vivait dans un brief que la main devait *penser* à lire ; 1/3 des reports post-pivot avait `duration: null` ; `aw report` acceptait un workspace inexistant ; l'audit main n'était pas tracé (mode de défaillance exact d'uk_clml).
3. **L'angle d'échec se déplace plus vite que la prose.** Série Codex : malhonnête (claw3d, étiquette ≠ chemin) → honnête mais infidèle (polish-webapp, gold-plating + divergence non déclarée) → honnête mais **tests fictifs** (ws2-quota : entrées de confort qui esquivent le câblage réel — 2 bugs sous suite verte, 11/20).

Littérature à l'appui : ETH Zurich (fichiers de contexte gras = -20 % de perf), SpecBench/ImpossibleBench (les modèles saturent les tests visibles, seuls les **tests cachés** discriminent), Anthropic harness engineering (l'auto-évaluation se loue elle-même ; evaluator externe obligatoire ; les harness doivent maigrir à chaque génération).

## Principe directeur v2

**Tout invariant vit soit dans un artefact généré, soit dans un refus mécanique du CLI — jamais dans de la prose qu'il faut se rappeler de lire. La fidélité n'est plus demandée, elle est mesurée.**

## Les mécanismes (convergence unanime du panel)

1. `prompt.md` **squelette généré** (sections obligatoires, marqueurs `TODO(main)`), plus jamais vide.
2. Done-criteria = **scripts** `inputs/checks/NN-*.sh`, écrits par la main, boucle de feedback de l'agent, **ré-exécutés mécaniquement à l'audit**.
3. `inputs/` **scellé par hash** (`aw seal`) — tampering détectable à coût nul. Au seal, chaque check de progrès doit être **rouge** (un check vert sur workspace vierge ne prouve rien). Échappement tracé : `--no-checks "<raison>"`.
4. **Hold-out côté auditeur** (`~/.agentic-workspace/holdout/<name>/`), jamais mentionné dans le workspace — seule mitigation anti-reward-hacking validée par la littérature. Quasi obligatoire sur tâches à invariants (leçon ws2-quota : le check caché rejoue le câblage réel).
5. **Journal vivant minimal** (`outputs/journal.md`) : §Decision Log (divergence déclarée *au moment où elle est prise*) + §Reprise (résumabilité après mort de session). Pas de Progress/Surprises horodatés — théâtre de process sur des tâches de 20 min-3 h.
6. `aw end` **refuse** une livraison sans `result.md` structuré (§Not done obligatoire) ; `aw report` fallback sur mtime d'`outputs/` si `.ended_at` manque (plus de duration null, l'oubli laisse une signature).
7. `aw audit --mode code|result-only` **trace le mode d'audit** ; `aw report` refuse sans audit frais, refuse les doublons sans `--round`, auto-remplit harness/path/durée/checks/tamper.
8. **Schéma reports v2** : `{schema:2, ts, name, path, harness, outcome, round, checks:{visible,holdout,tamper}, audit_mode, duration_seconds, resumed, end_missing, note}` — benchmark longitudinal Claude-vs-Codex maison.
9. **Prose divisée par ~3** : une source par audience (agent → CLAUDE.md/AGENTS.md inlinés ; main → main-brief.md ; humain → README court). ONBOARDING.md, install.sh, config.json supprimés (`bin/aw` auto-localisé par `readlink -f`).
10. **Règle d'admission honnête** : « n≥3 occurrences OU incident saillant documenté dans reports/ » — c'est la pratique réelle. Patterns embarqués dans ce commit : référence indépendante des métriques, probe avant engagement, chemin réel des tests (6ᵉ levier, ws2-quota), diff minimal.

## Arbitrages tranchés (divergences du panel)

- **Gate côté main (`aw seal`)**, pas côté agent : la spec faible est attrapée avant de coûter un lancement de session ; un lint dans `aw start` seul concentre le point de défaillance chez l'agent.
- **Tails harness gardés mais dégraissés** (~6 lignes) : le bootstrap genius diffère réellement par harness ; les capacités natives (sous-agents, background, web) sortent de la prose (anti-pattern ETH).
- **Audit adversarial interne réduit à une ligne** conditionnelle (tâches longues / à invariants) : il a raté son blind spot 2× (uk_clml, relay_x) mais attrapé des vrais bugs 1× (minishell) — on garde le filet sans le rituel.
- **Pas de capture tokens/transcripts** (fragile multi-harness), **pas de LLM-as-judge** (hackable), **pas de sandbox** (détection certaine > prévention chère pour un opérateur solo).

## Risques suivis (auto-critiques du panel, tests les moins chers)

1. **Théâtre de contrat** (checks vacueux pour passer le seal) : surveiller dans `checks-log.jsonl` les checks verts dès le premier run de l'agent ; compter les `--no-checks`.
2. **Hold-out déterré** (l'agent va le lire) : canari token unique dans le holdout des 2-3 premiers runs Codex, grep transcript/outputs.
3. **Sur-production de blocked.md** (contrat scellé trop rigide) : seuil décidé d'avance — >2/5 runs bloqués pour défaut de contrat → règle « l'agent peut contester un check dans §Not done avec preuve et livrer quand même ».

## Suivi

- **Premier retex d'usage réel** (2026-06-11, lot de 8 workspaces WS3) :
  `reports/2026-06-11-v2-premier-run-reel-cout-prep-et-effets-pervers-ws3.md`.
  Confirme holdouts + auditabilité + anti-shortcut ; documente trois angles non
  anticipés ici : **coût de prép des checks**, **chute des tests internes** (3/4
  agents → 0 test quand les checks sont fournis), **faux-rouge structurel** (un
  check rouge-sur-vierge pour une raison parasite — `addopts="-q"` → `-qq` —
  passe le gate seal sans jamais virer au vert). Touche directement les risques 1
  et 3 ci-dessus.

## Pointeurs

- Série fondatrice : `2026-06-07-codex-reward-hacking-operator-claw3d.md` → `2026-06-09-codex-anti-shortcut-cadrage-confirmed-polish-webapp.md` → `2026-06-10-codex-honest-but-tests-dodge-real-path-ws2-quota.md`
- Patterns sources : `analysis/README.md` §Patterns émergents (1, 2+3 fusionnés, 4, 6ᵉ levier)
- Les 3 propositions complètes du panel : transcripts session main 2026-06-11
