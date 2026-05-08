# Migration V1.x → V2 — guide pour Claude Code

> Fichier **temporaire**. À supprimer une fois la migration faite sur toutes
> les machines de l'utilisateur. Un commit final retirera ce fichier du dépôt.

Tu es un agent Claude Code. L'utilisateur t'a indiqué où est cloné le dépôt
`agentic-workspace` sur cette machine (appelons ce chemin `$REPO`). Ta mission :
mettre la machine à jour vers V2 sans casser l'existant.

## Ce qui a changé en V2 (résumé)

1. **Plus de `template/`**. Les workspaces sont générés à la volée par `bin/aw`
   à partir de `shared/procedure.md` (ou `shared/procedure-sub.md` avec `--sub`).
   Le contenu de la procédure est **inliné** dans le `CLAUDE.md` de chaque
   workspace — plus de `@import`.
2. **Workspaces self-contained.** `aw new` crée `$PWD/workspaces/<name>/` avec
   son propre `.claude/skills/genius/SKILL.md` copié localement. Déplacer le
   dépôt cloné ne casse plus les workspaces déjà créés.
3. **Config canonique** `~/.agentic-workspace/config.json` `{repo_path,
   reports_path}` écrit par `install.sh` (wizard). C'est ce qui rend `bin/aw`
   indépendant de l'emplacement du dépôt.
4. **Reports JSONL** : nouvelle commande `aw report <name> "<note>"` qui
   appende dans `~/.agentic-workspace/reports.jsonl`.
5. **Hook genius conditionnel** dans `~/.claude/settings.json` : ne s'exécute
   que si le flag `~/.agentic-workspace/genius-hook-on` existe. Toggles via
   slash commands `/genius-on` et `/genius-off`.
6. **Skill user-level renommé `genius-old`** + `disable-model-invocation: true`
   pour qu'il ne consomme plus de tokens de contexte. Reste invocable
   manuellement via `/genius-old`.

## Étapes de ménage à exécuter

Exécute dans cet ordre. Vérifie chaque étape avant de passer à la suivante.

### 1. Mettre le dépôt à jour

```bash
cd "$REPO"
git status                # doit être propre, sinon stash/commit avant
git pull --ff-only
```

Si le pull échoue (divergence locale), arrête-toi et demande à l'utilisateur.

### 2. Re-jouer l'install (wizard)

```bash
cd "$REPO"
bash install.sh
```

Le wizard te demandera le dossier de config (défaut `~/.agentic-workspace/`).
Confirme le défaut sauf indication contraire de l'utilisateur. Vérifie ensuite :

```bash
cat ~/.agentic-workspace/config.json     # doit pointer vers $REPO actuel
ls -la ~/.local/bin/aw                   # symlink vers $REPO/bin/aw
aw help                                  # doit afficher l'aide V2
```

Si `aw help` n'est pas trouvé, vérifie que `~/.local/bin` est dans `PATH`.

### 3. Vérifier le hook conditionnel

Lis `~/.claude/settings.json` et regarde la commande du hook
`UserPromptSubmit`. Elle doit ressembler à :

```
[ -f $HOME/.agentic-workspace/genius-hook-on ] && echo '[GENIUS] ...' || true
```

Si elle est encore en version V1 (echo inconditionnel), modifie-la avec Edit.
La forme exacte attendue est dans `$REPO/README.md` section « The genius hook »
ou dans le settings.json de la machine de référence (la mienne).

⚠️ **Le hook ne se hot-reload pas** : il sera pris en compte au prochain
démarrage de `claude`.

### 4. Renommer et désactiver le skill genius user-level

Cible : `~/.claude/skills/genius/SKILL.md`

Le frontmatter doit être :

```yaml
---
name: genius-old
description: "Archived long-form genius skill. Manual invocation only via /genius-old."
disable-model-invocation: true
---
```

Le corps du fichier reste **inchangé** (c'est volontairement archivé). Édite
**uniquement** le frontmatter avec Edit.

Vérification : dans une session `claude` fraîche, `/context` ne doit plus
afficher `genius-old` parmi les skills chargés. `/genius-old` doit rester
invocable manuellement.

> ⚠️ Si l'invocation manuelle de `/genius-old` ne fonctionne plus
> (issue [#26251](https://github.com/anthropics/claude-code/issues/26251)),
> retire `disable-model-invocation: true` mais conserve le rename `genius-old`.
> Le bénéfice context-tokens disparaît mais le rename suffit à éviter les
> conflits avec le skill `genius` project-level des workspaces.

### 5. Nettoyer les vestiges V1 (si présents)

Sur l'ancienne machine il peut traîner :

```bash
# ancien template/ déjà supprimé du repo, mais vérifier qu'il n'est pas resté localement
ls "$REPO/template" 2>/dev/null && echo "WARN: template/ encore présent"

# anciens workspaces qui auraient été créés DANS le repo (V1 plaçait parfois ailleurs)
ls "$REPO/workspaces" 2>/dev/null    # OK s'il existe (gitignored), juste informatif
```

Ne supprime rien sans demander si tu trouves des fichiers non attendus :
ils peuvent contenir du travail en cours de l'utilisateur.

### 6. Test end-to-end

```bash
mkdir -p /tmp/aw-migrate-test && cd /tmp/aw-migrate-test
aw new alpha
test -f workspaces/alpha/CLAUDE.md && echo "CLAUDE.md OK"
test -f workspaces/alpha/.claude/skills/genius/SKILL.md && echo "skill OK"
grep -q "Workspace" workspaces/alpha/CLAUDE.md && echo "procedure inlinée OK"

aw new beta --sub
test -f workspaces/beta/inputs/prompt.md && echo "sub prompt placeholder OK"

aw report alpha "test migration $(hostname)"
tail -1 ~/.agentic-workspace/reports.jsonl   # doit afficher la ligne JSON

rm -rf /tmp/aw-migrate-test
```

Si l'un de ces tests échoue, arrête-toi et rapporte à l'utilisateur ce qui a
foiré exactement (commande + output complet).

### 7. Hook toggle (vérification visuelle, optionnelle)

Demande à l'utilisateur de :

1. Lancer `claude` dans un dossier quelconque (hors meta-repo, hors workspace).
2. Envoyer un prompt → ne doit **pas** afficher `[GENIUS] ...`.
3. Taper `/genius-on` puis envoyer un nouveau prompt → doit afficher `[GENIUS]`.
4. Taper `/genius-off` puis encore un prompt → ne doit plus afficher.

Tu ne peux pas tester ça toi-même (ça concerne la session `claude` de l'utilisateur).

## Rapport final attendu

Quand tout est passé, rapporte à l'utilisateur :

- ✅ git pull effectué (ou état déjà à jour)
- ✅ `~/.agentic-workspace/config.json` créé et pointe vers `$REPO`
- ✅ `aw help` fonctionne
- ✅ Hook dans `settings.json` est conditionnel
- ✅ `~/.claude/skills/genius/SKILL.md` renommé `genius-old` + flag posé
- ✅ Test E2E passé (`aw new`, `aw new --sub`, `aw report`)

Si une étape a été sautée, dis-le explicitement avec le pourquoi.

## Après la migration

Quand l'utilisateur confirme que toutes ses machines sont à jour, ce fichier
peut être supprimé du dépôt (`git rm MIGRATE-TO-V2.md && git commit`).
