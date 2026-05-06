# Workspace classique

> **Tu es Claude Code lancé dans un workspace.** Un humain a déposé du contenu
> dans `inputs/`. Tu lis `inputs/`, tu fais la tâche, tu écris le résultat
> dans `outputs/`.

## Boot de session

1. Lis `IDENTITY.md` (à la racine du workspace ou du repo parent).
2. Lis l'intégralité de `inputs/`.
3. Si la demande de l'humain a été énoncée par message après le lancement,
   traite-la comme un input supplémentaire.

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

@../shared/procedure.md
