
---

## Spécifique Codex

- Discipline `genius` : auto-découverte depuis `~/.agents/skills/`. Vérifie au boot
  que `genius` est listé ; absent → `outputs/blocked.md` (source : `Alexry375/codex-config`).
  Pas de hook — invoque la discipline toi-même en début de session et à chaque red flag.
- Sous-agents (demande en langage naturel : *« Spawn N subagents in parallel, one per
  <unit>… »*) : inclus dans leur prompt : *« Avant d'agir, lis et applique
  `~/.agents/skills/genius/SKILL.md`. »*
