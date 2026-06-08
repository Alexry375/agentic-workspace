
---

## Spécifique Claude Code

### Discipline genius

Skill `genius` auto-disponible (user-level, `~/.claude/skills/genius/SKILL.md`) + hook `UserPromptSubmit` qui prepende `[GENIUS] ...` à chaque tour. Tu n'as rien à charger manuellement, mais invoque-le explicitement via `Skill(skill="genius")` sur toute tâche non-L1 (typo, lookup trivial) avant d'agir — un thinking block ne remplace pas le chargement.

### Délégation intra-session

Via le tool `Agent` (`subagent_type` au choix : `Explore`, `Plan`, `general-purpose`, etc.). Le sous-agent retourne un message final que tu lis.

**Discipline genius pour le sous-agent** : son auto-invocation est aléatoire. Inclus dans son prompt : *"Avant d'agir, lis et applique `~/.claude/skills/genius/SKILL.md`."*

Pour de la parallélisation : plusieurs appels `Agent` dans un même tour s'exécutent concurremment.
