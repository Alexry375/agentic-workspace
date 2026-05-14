# Workspace classique

> **Tu es Claude Code lancé dans un workspace.** Un humain a déposé du contenu
> dans `inputs/`. Tu lis `inputs/`, tu fais la tâche, tu écris le résultat
> dans `outputs/`.

## Boot de session

1. Lis `IDENTITY.md` (à la racine du workspace ou du repo parent).
2. Lis l'intégralité de `inputs/`.
3. Si la demande de l'humain a été énoncée par message après le lancement,
   traite-la comme un input supplémentaire.
4. **Si `inputs/prompt.md` existe** : il a été préparé par un autre agent
   pour toi. Considère-le comme la spec autoritaire de la tâche — la plupart
   des questions d'alignement ci-dessous (§2) sont déjà répondues par ce
   fichier.

## La Procédure (5 exigences, en une seule réponse)

Avant de commencer à coder, traite ces 5 points en une seule réponse.

### 1. Niveau de l'humain dans le domaine

Lis `IDENTITY.md` et énonce en 1 ligne le niveau pertinent
(*ex: "L'humain n'a quasiment pas codé sans IA mais a livré en prod ;
j'expliquerai mes choix d'archi sans assumer qu'il lit le code."*).
Si `IDENTITY.md` ne couvre pas le domaine de la tâche, considère cette
absence comme une question candidate pour §2.

### 2. Alignement par questions ciblées à t=0

**Default : autonomie totale après cet alignement.** Toutes tes questions
sont posées maintenant, en 0 à 3 messages. Tout ce qui suit suppose que tu
ne reviendras plus vers l'humain.

Une question ne se justifie que si :
- elle empêche un choix irréversible que tu ne sauras pas trancher seul,
- ou tu risques sinon de partir sur la mauvaise cible.

**Exception rare — mode mixte autorisé** : si tes questions amont révèlent
un humain qui ne se projette pas suffisamment pour décrire son besoin
(typiquement : application web + humain très exigeant sur l'UI mais
incapable de la décrire avant de la voir), tu peux planifier 2-3
checkpoints humains *explicites*, énoncés à l'avance comme des prompts
précis (*"Je reviendrai vers toi quand A et B seront faits, pour valider C"*).
Cette exception est marginale — la **grande majorité** des projets sont
compatibles avec l'autonomie totale.

### 3. Marge d'initiative

Selon `IDENTITY.md` + qualité de la spec dans `inputs/`. Range : **élevée**
(l'humain ne lit pas le code, je décide tout) → **basse** (je propose 2-3
options sur les choix d'archi, l'humain tranche). Énonce le verdict.

### 4. Qualité de code exigée

Range : **prototype jetable** → **prod-ready avec tests + observabilité**.
Par défaut : prod-ready si l'humain a mentionné déploiement / utilisateurs
/ argent ; prototype sinon. Énonce le verdict.

### 5. Critères d'optimisation à maximiser

Le **vrai** objectif derrière la tâche, pas la formulation littérale.
Exemples :
- *"Site web pour vendre"* → **conversion** (pas "site beau")
- *"App pour utiliser au club"* → **fiabilité usage live** (pas
  "app riche en features")
- *"Bot de trading"* → **PnL net après coûts** (pas "stratégie sophistiquée")

Si non évident depuis `inputs/` + `IDENTITY.md` : compte parmi les questions
de §2.

---

## Avant d'attaquer

**État de l'art** (par défaut sur tâche complexe / workspace dédié) : 1-3
recherches web minimum pour identifier repos / papers / outils récents (filtre
≤ 12 mois sur les domaines qui bougent vite). Objectif : calibrer ton approche
sur ce qui existe à la date du jour, pas réinventer ni rester sur ton training
cutoff. Les agents sous-utilisent ce réflexe par défaut — c'est un biais à
corriger activement.

## Pendant l'exécution

- **Skill `genius`** : actif au niveau utilisateur (`~/.claude/skills/genius/SKILL.md`),
  donc disponible automatiquement dans toute session Claude Code de cet utilisateur.
  Applique-le sur toute affirmation factuelle, hypothèse, et claim de complétion.
- **Hook `[GENIUS]`** : un `UserPromptSubmit` hook prepende un rappel à chaque
  prompt — c'est normal, traite-le comme un renforcement du skill.
- **`inputs/` est en lecture seule.** Si tu dois travailler sur une copie, copie
  vers `outputs/work/`.
- **Hold-out obligatoire** : si tu itères ton code jusqu'à ce qu'il passe sur un
  dataset A, le score sur A est faussé. Mesure et rapporte sur un B que tu n'as
  jamais touché pendant l'itération.
- **Vérifier un sub-agent** : lis ses fichiers de sortie, pas son résumé.
  (Pattern B uniquement : son transcript est aussi dans
  `.claude/projects/<session>.jsonl`.)
- **Processus longs (>30 s)** : `run_in_background` + monitor logs. Détecter les
  hang, jamais d'attente passive.

## Sous-tâches

Deux patterns selon la nature de la sous-tâche :

### Pattern A — Agent tool (intra-workspace)

Pour Explore, Plan, recherche, audit, sous-problème de la tâche en cours :
utilise le tool `Agent`. Le sub-agent retourne un **résumé structuré** que tu
intègres à ton contexte — c'est ta compaction implicite.

**Discipline genius pour les sous-agents.** Les sous-agents auto-découvrent les
skills par leur description, mais l'auto-invocation de `genius` est aléatoire.
Sur toute sous-tâche non triviale (investigation, hypothèses, claim de
complétion), inclus explicitement dans le prompt du sous-agent :
*"Avant d'agir, lis et applique `~/.claude/skills/genius/SKILL.md`."*

**Analyses indépendantes** (par item, par marché, par document) → un seul
message avec N `Agent` calls en parallèle.

### Pattern B — Sub-workspace dédié pour l'humain (sous-tâche lourde)

Si une sous-tâche mérite vraiment sa propre session Claude Code complète
(état très isolé, plusieurs dizaines de minutes de travail, dépendances
distinctes), **ne pas tenter de la lancer toi-même** (pas de `claude -p`,
pas de récursion). À la place :

1. Crée le sub-workspace : `aw new <name> --sub`. Cela génère
   `workspaces/<name>/` avec le `CLAUDE.md` adapté à un sub-workspace
   (procédure bornée, pas de questions humain) et un `inputs/prompt.md`
   vide à remplir.
2. Remplis `workspaces/<name>/inputs/prompt.md` avec un prompt clair et
   complet : objectif, contexte minimal, critères de succès, contraintes.
3. Indique à l'humain dans ta réponse : *"J'ai préparé un sub-workspace
   dédié à cette sous-tâche. Lance `cd workspaces/<name> && claude` quand
   tu peux, le prompt est dans `inputs/prompt.md`."*
4. **Quand le sub-workspace rend sa livraison, c'est ta tâche de l'auditer
   adversarialement — pas la sienne.** L'auto-audit de l'agent sub a un
   biais structurel : il a tendance à *renommer* les problèmes critiques
   plutôt qu'à les résoudre (cf. incident `uk_clml_implementation` 2026-05-14
   où la métrique `content_correctness=1.0` était circulaire par construction
   et l'auto-audit s'est contenté de la requalifier). Tu lis directement
   les artefacts livrés (`outputs/result.md`, le code, les métriques), tu
   ne te fies **jamais** au résumé de l'agent sub. Cherche activement :
   - Métriques tautologiques / circulaires (compare X au même X normalisé).
   - Critères du `inputs/prompt.md` que tu as posés et que l'agent a
     silencieusement abandonnés ou contournés.
   - Edge cases non investigués (unexplained, NaN, "0 occurrences" suspects).
   - Auto-audits qui *justifient* un finding au lieu de le *traiter*.

   Si tu trouves CRITIQUE ou IMPORTANT : rédige un round 2 ciblé dans
   `inputs/round-2.md` du sub-workspace et redemande à l'humain de relancer.
   N'archive jamais un sub-workspace sur la foi de son propre résumé.

L'humain reste dans la boucle pour ces cas lourds, mais le coût est minime
(juste lancer une commande). Le nouvel agent verra le prompt préparé et
pourra zapper la plupart des questions d'alignement.

## Gestion du contexte

- **Sub-agents-first** : pour toute exploration lourde (lecture massive,
  recherche multi-fichier, brainstorming d'architecture), délègue via
  `Agent` tool. Le résumé qu'il rend = ta compaction implicite, gratuite.
- **Compaction explicite à ~200 k tokens** seulement si nécessaire malgré les
  sub-agents : écris l'état essentiel dans `outputs/.ledger.md` (objectif,
  décisions, ce qui reste, fichiers touchés) et fais `/clear`. Au démarrage
  de la session suivante, relis le ledger.
- **Pas plus tard que 200 k** : au-delà, "dumb zone" documentée (perte de
  qualité non linéaire).

## Audit adversarial

**NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.**

Trigger 1 : avant tout claim de complétion.
Trigger 2 : **après toute avancée majeure** — pas juste à la livraison finale.
Avancée majeure = feature end-to-end fonctionnelle, décision d'archi committée,
1ère version livrable d'un module, pivot de stratégie.

1. Lance un sous-agent `audit-adversarial` (`Agent` tool) avec consigne :
   *"Attaque à tous les niveaux le travail récent :*
   *— Code : bugs, edge cases non testés, anti-patterns, fichiers oubliés,
   erreurs d'inattention.*
   *— Architecture : choix structurels fragiles, hypothèses implicites, dette
   qui va exploser.*
   *— Stratégie / cadrage : la métrique optimisée est-elle la bonne ? Le
   problème est-il bien posé ? Quelle limite n'a pas été anticipée ?*
   *Classe CRITIQUE / IMPORTANT / MINEUR. Cite fichier:ligne ou décision
   précise pour chaque finding."*
2. Findings CRITIQUE ou IMPORTANT → traite. Re-audit après.
3. Une fois propre : continue (ou écris la livraison dans `outputs/` si fin de
   projet).

## Format de `outputs/`

Toujours présent à la fin :

- `outputs/result.md` — résumé exécutif (≤ 200 mots) : ce qui a été fait,
  ce qui n'a pas pu l'être, ce qui reste à valider par l'humain.
- `outputs/audit-report.md` — findings de l'audit adversarial et leur
  traitement.
- `outputs/<artefacts>` — fichiers livrés (code, données, docs).
- `outputs/identity-suggested-updates.md` — uniquement si tu as appris des
  choses sur l'humain qui mériteraient un update de `IDENTITY.md`
  (validation manuelle de l'humain en fin de session).

## Si tu es bloqué

Une seule fois, écris une question dans `outputs/blocked.md` avec :

- ce que tu as déjà essayé,
- ce qui te manque pour continuer,
- 2-3 options possibles avec leur conséquence.

Puis termine. **Ne brute-force pas** après deux tentatives ratées sur le
même sous-problème — lance plutôt un `Agent` d'analyse parallèle, ou pose
une question de fond. C'est du cadrage, pas de l'effort.

## Bilan en fin de tâche

Quand la tâche est terminée (ou bloquée), produis un bilan court via :

```bash
aw report <name> "ok|ko|partial — note libre sur succès / échec / suite"
```

Le bilan est appendé à `~/.agentic-workspace/reports.jsonl` (corpus
d'amélioration du harness, pas de retrouve par workspace). Format :
free-form pour le texte, mais commence par un mot clé d'outcome
(`ok` / `ko` / `partial`) pour faciliter le tri ultérieur.

Si l'humain confirme que le workspace est terminé et n'a plus à être
relancé, propose-lui `aw archive <name>` (touch `workspaces/<name>/.archive`).
Le dossier n'est pas renommé — seul un flag-file est posé. Toute énumération
ultérieure via `aw list` ignorera ce workspace par défaut. Pour le réveiller :
`aw revive <name>`.
