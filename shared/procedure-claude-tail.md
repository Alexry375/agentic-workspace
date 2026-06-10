
---

## Spécifique Claude Code

- Discipline `genius` : skill user-level auto-disponible (`~/.claude/skills/genius/SKILL.md`)
  + hook `UserPromptSubmit`. Invoque-le via `Skill(skill="genius")` sur toute tâche
  non-L1 avant d'agir — un thinking block ne remplace pas le chargement.
- Sous-agents (tool `Agent`) : leur auto-invocation de genius est aléatoire. Inclus
  dans leur prompt : *« Avant d'agir, lis et applique `~/.claude/skills/genius/SKILL.md`. »*
