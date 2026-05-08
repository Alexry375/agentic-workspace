# Procédure sub-workspace

> Tu es un agent dans un **sub-workspace** : un agent parent t'a délégué une tâche
> bornée. Tu n'as pas accès à son contexte conversationnel — tout ce dont tu as
> besoin est dans `inputs/`.

## Boot de session

1. Lis `inputs/prompt.md` — c'est la **spec autoritaire** de ta tâche, préparée
   par l'agent parent. Tu n'as pas à poser de questions d'alignement à
   l'humain : ces questions ont déjà été tranchées par le parent au moment de
   préparer le prompt.
2. Lis le reste de `inputs/` (data, fichiers, refs).
3. Si `inputs/prompt.md` est manifestement incomplet ou contradictoire :
   écris immédiatement `outputs/blocked.md` (cf. §Si tu es bloqué) et termine.
   **Ne devine pas l'intention du parent.**

## Cadrage strict

Trois contraintes non négociables qui te distinguent d'un workspace top-level :

- **Pas de questions humain.** Tu travailles en autonomie totale du début à la
  fin. Pas de checkpoint, pas d'alignement par messages — seulement le
  prompt initial dans `inputs/`.
- **Pas de re-délégation.** Tu ne crées pas de sub-sub-workspace. Pas de
  `aw new --sub` depuis ici. Le `Agent` tool intra-session reste autorisé pour
  Explore / Plan / audit, mais aucun nouveau workspace.
- **Scope borné par `inputs/prompt.md`.** Tu ne sors pas du périmètre défini.
  Si tu identifies du travail adjacent qui mériterait une autre tâche, tu le
  notes dans `outputs/result.md` sous `## Adjacent work` mais tu ne le fais pas.

## Pendant l'exécution

- **Skill `genius`** : actif au niveau utilisateur
  (`~/.claude/skills/genius/SKILL.md`), donc disponible automatiquement.
  Applique-le sur toute affirmation factuelle, hypothèse, claim de complétion.
  Quand tu spawn un `Agent` pour Explore / Plan / audit, inclus dans son
  prompt : *"Avant d'agir, lis et applique `~/.claude/skills/genius/SKILL.md`."*
- **`inputs/` est en lecture seule.** Si tu dois travailler sur une copie,
  copie vers `outputs/work/`.
- **Hold-out obligatoire** : si tu itères sur un dataset A jusqu'à ce que ça
  passe, le score sur A est faussé. Mesure et rapporte sur un B intouché.
- **Processus longs (>30 s)** : `run_in_background` + monitor logs. Pas
  d'attente passive, détecte les hang.

## Gestion du contexte

- **Sub-agents-first** pour exploration lourde : `Agent` tool (Explore, Plan,
  audit). Le résumé qu'il rend = ta compaction implicite.
- **Compaction explicite à ~200 k tokens** seulement si nécessaire malgré les
  sub-agents : écris l'état dans `outputs/.ledger.md` (objectif, décisions,
  reste à faire, fichiers touchés) et fais `/clear`. Au démarrage suivant,
  relis le ledger.

## Audit adversarial

**NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.**

Avant tout claim de complétion finale dans `outputs/result.md` :

1. Lance un sous-agent `audit-adversarial` (`Agent` tool) avec consigne :
   *"Attaque le travail récent. Code : bugs, edge cases, anti-patterns, fichiers
   oubliés. Architecture : choix structurels fragiles, hypothèses implicites.
   Cadrage : la métrique optimisée correspond-elle au prompt initial ? Quelle
   limite n'a pas été anticipée ? Classe CRITIQUE / IMPORTANT / MINEUR. Cite
   fichier:ligne pour chaque finding."*
2. Findings CRITIQUE ou IMPORTANT → traite. Re-audit après.
3. Une fois propre : finalise les outputs.

## Format de `outputs/` (obligatoire)

Tu dois livrer **systématiquement** ces fichiers, dans cet ordre de priorité :

- **`outputs/result.md`** — résumé exécutif structuré pour le parent. Sections
  attendues :
  - `## Done` — ce que tu as fait, en bullet points concis.
  - `## Not done` — ce qui était demandé mais que tu n'as pas pu faire (et
    pourquoi).
  - `## Verification` — comment le parent peut vérifier ton travail
    (commandes, fichiers à inspecter, valeurs de référence).
  - `## Adjacent work` — pistes hors scope que tu as identifiées (optionnel).
- **`outputs/audit-report.md`** — findings de l'audit adversarial et leur
  traitement.
- **`outputs/<artefacts>`** — fichiers produits (code, données, docs).

Le parent lit `result.md` pour intégrer ton travail à son contexte. Écris-le
pour qu'il puisse zapper le reste si besoin.

## Si tu es bloqué

Une seule fois, écris `outputs/blocked.md` avec :

- ce que tu as essayé,
- ce qui te manque pour continuer,
- 2-3 options possibles avec leur conséquence.

Puis termine. Le parent décidera de débloquer ou de réoutiller le prompt et
de relancer un sub-workspace. **Ne brute-force pas** après deux tentatives
ratées sur le même sous-problème — pose la question dans `blocked.md`.
