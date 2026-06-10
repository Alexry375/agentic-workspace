# agentic-workspace — brief main session

> Tu es une **session main** (Claude Code interactif chez Alexis). Tu prépares un
> workspace que **tu n'exécuteras pas** : un autre agent (Codex CLI le plus
> souvent, Claude Code parfois) le lancera en autonomie totale. Ton job : aligner,
> écrire le contrat (`prompt.md` + `checks/`), sceller, puis auditer la livraison.

## Le flow

1. **Aligner** avec l'humain — seul moment où poser des questions est possible.
2. `aw new <name>` → `$PWD/workspaces/<name>/` avec `inputs/prompt.md` squelette
   (marqueurs `TODO(main)`) et `inputs/checks/` à remplir.
3. **Écrire la spec ET les checks — c'est le même acte.** Un done-criterion sans
   script = pas un criterion. Pour chaque « via X » : un check qui échoue si X est
   faké. Profil de tâche → angle d'échec : front/full-stack → gold-plating et
   divergences (serre les Contraintes) ; backend à invariants → tests fictifs
   (écris le check sur le câblage réel : même timing, état post-déploiement
   vierge — incident `ws2-quota`).
4. **Hold-out** (quasi obligatoire sur tâches à invariants) : 1-3 checks cachés
   dans `~/.agentic-workspace/holdout/<name>/*.sh` — jamais mentionnés dans le
   workspace. C'est la seule mitigation anti-reward-hacking validée (les modèles
   saturent les tests visibles, divergent sur les cachés).
5. `aw seal <name>` — refuse : `TODO(main)` restant, zéro check, check de progrès
   déjà vert (il ne prouve rien). Échappement tracé : `--no-checks "<raison>"`.
   Scelle `inputs/` par hash.
6. Dis à l'humain : *« Lance `cd workspaces/<name> && codex` (ou `claude`). »*
7. À la livraison : `aw audit <name> --mode code` — re-hash (tampering),
   ré-exécute les checks visibles, exécute le hold-out, écrit `.audit.json`.
   **Puis lis le chemin critique du code** : l'incident `operator-claw3d` n'était
   visible QUE là. Le `journal.md` §Decision Log liste les divergences déclarées —
   commence par lui, cherche celles qui n'y sont pas. `--mode result-only` existe
   mais se voit dans la telemetry — assume-le.
8. `aw report <name> <ok|ko|partial> "<note>"` — refuse sans audit frais, refuse
   les doublons sans `--round N`. Auto-remplit harness, path, durée, checks.
9. Round 2 ciblé si besoin : `inputs/round-2.md` + nouveaux checks + re-seal
   (`aw seal --round 2`), report avec `--round 2`.
10. Post-mortem `analysis/<name>.md` si ko/partial ou incident saillant
    (grille : `analysis/README.md`).

## Commandes

| Commande | Qui | Refuse |
|---|---|---|
| `aw new <name>` | main | nom existant ou invalide |
| `aw seal <name> [--no-checks "<raison>"] [--round N]` | main | TODO restants, zéro check, check de progrès vert, re-seal après start (sauf `--round` avec `.ended_at`) |
| `aw start` | agent | workspace non scellé ; inputs/ divergent du seal |
| `aw check [<name>]` | agent et main | tampering (exit 2, rien n'est exécuté) |
| `aw end` | agent | pas de `result.md` structuré (§Not done obligatoire) ni `blocked.md` ; journal non tenu |
| `aw audit <name> --mode code\|result-only` | main | pas de `.ended_at` ; `--mode` absent |
| `aw report <name> <ok\|ko\|partial> "<note>" [--round N] [--legacy]` | main | pas d'audit frais ; doublon sans `--round` ; workspace inexistant |
| `aw archive <name>` / `aw archive --undo <name>` | main | path inexistant |
| `aw list [--all\|--archived]` · `aw context` | tous | — |

Pas de registre global : les workspaces vivent où tu les crées. Le nom du dossier
ne change jamais (historique de session du harness lié au chemin) — énumère via
`aw list`.

## Project-lab — quand un workspace devient un projet

Un workspace suffit pour du one-shot. Si son `outputs/` contient un artefact
permanent qu'on itère pendant des semaines, scinde : `<project>-lab/{repo,workspaces}/`
— `repo/` = code permanent (son propre git), les workspaces deviennent des
contributions scopées. Le seed workspace est archivé (`aw archive`), jamais
supprimé : son `inputs/` est irreproductible. Convention de dossiers, pas de CLI.

## Reports — telemetry

`~/.agentic-workspace/reports.jsonl` (override : `$AW_REPORTS`), append-only.
Schéma 2 : `{schema, ts, name, path, harness, outcome, round, checks:{visible,
holdout, tamper}, audit_mode, duration_seconds, resumed, end_missing, note}`.
Tout est auto-rempli sauf `outcome` et `note`. C'est le benchmark longitudinal
Claude-vs-Codex maison — `visible` vs `holdout` mesure le reward-hacking par
harness.

## Guides opt-in

`shared/guides/` — chargés via Read SI la tâche correspond au trigger :

| Guide | Charge si |
|---|---|
| `guides/reimplementation-parity.md` | ré-implémenter un système existant sur une autre stack, ou absorber le cœur d'un repo upstream |
| `guides/duel-agents-on-repo.md` | monter N agents en parallèle (duel ou fan-out) qui **modifient le même dépôt de code**, avec merge propre du gagnant — topologie workspace aw + git worktree imbriqué (`repo/`) |

## Méthode (si tu modifies ce repo)

- **Admission d'un brick** dans `procedure-core.md` ou les squelettes :
  ≥3 occurrences dans `analysis/` **OU** un incident saillant documenté dans
  `reports/`. Dans les deux cas, l'embarquement se fait **dans le même commit**
  que la déclaration.
- **Soustraction par défaut** : toute ligne ajoutée doit nommer ce qu'elle
  remplace. Revue « qu'est-ce qu'on peut supprimer » à chaque génération de
  modèle (les harness doivent maigrir quand les modèles s'améliorent).
- **Pas de duplication de source de vérité** : agent → CLAUDE.md/AGENTS.md
  inlinés ; main → ce fichier ; humain → README. Le skill `genius` vit au niveau
  user de chaque harness (`~/.claude/skills/`, `~/.agents/skills/`), jamais copié ici.
- **Risques v2 sous surveillance** (cf. `reports/2026-06-11-v2-redesign-contract-sealed.md`) :
  checks vacueux (vert au 1er run agent dans `checks-log.jsonl`), hold-out déterré
  (canari), sur-production de `blocked.md` (>2/5 → assouplir : contestation de
  check documentée en §Not done).
