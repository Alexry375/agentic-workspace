
---

## Spécifique Codex

### Discipline genius

Codex auto-découvre les skills depuis `~/.agents/skills/`, `.agents/skills/` (repo), `/etc/codex/skills`. Vérifie au boot que `genius` est listé. Si absent : demande à la main de l'installer (source : `Alexry375/codex-config`). Ne procède pas sur une tâche non-L1 sans avoir la table L1-L5 + le format bayésien en contexte.

Pas de hook équivalent au `UserPromptSubmit` Claude — c'est à toi d'invoquer la discipline en début de session et à chaque red flag (cf. SKILL.md §Red Flags).

### Délégation intra-session

Pas de tool nommé. Demande explicite en langage naturel à toi-même / au manager Codex :

> *"Spawn N subagents in parallel, one per <unit>. Each: <task>. Wait for all, then summarize as <format>."*

Codex orchestre (spawn, routing, wait, close) et te rend une réponse consolidée. **Source autoritative** : <https://developers.openai.com/codex/subagents>.

**Discipline genius pour le sous-agent** : inclus dans son prompt : *"Avant d'agir, lis et applique `~/.agents/skills/genius/SKILL.md`."*

Pour un batch sur fichiers : `spawn_agents_on_csv` (expérimental, voir doc).
