# agentic-workspace

Méthodologie minimaliste de délégation de tâches longues à des agents autonomes
(Codex CLI, Claude Code, tout harness lisant `AGENTS.md`/`CLAUDE.md`). v2
« contrat scellé » : la spec est un contrat exécutable (`prompt.md` squelette +
`inputs/checks/*.sh`), gelée par hash (`aw seal`), et la livraison est auditée
mécaniquement (`aw audit` : ré-exécution des checks + checks hold-out cachés +
détection de tampering) avant lecture humaine du code.

```
main :   aw new <name> → remplit prompt.md + checks/ → aw seal <name>
humain : cd workspaces/<name> && codex   (ou claude)
agent :  aw start → travaille (aw check en boucle) → aw end
main :   aw audit <name> --mode code → lit le code → aw report <name> ok "<note>"
```

Les workspaces sont self-contained (procédure inlinée dans `CLAUDE.md` et
`AGENTS.md` au moment du `aw new`) : déplacer ou supprimer ce repo ne casse
aucun workspace existant.

## Install

```bash
git clone https://github.com/Alexry375/agentic-workspace.git
ln -sf "$PWD/agentic-workspace/bin/aw" ~/.local/bin/aw   # ou ajoute bin/ au PATH
```

Prérequis : `bash`, `jq`, `sha256sum`. Prérequis user-level (hors repo) : skill
`genius` — `~/.claude/skills/genius/` (Claude, avec hook) et
`~/.agents/skills/genius/` (Codex, auto-découvert ; source :
`Alexry375/codex-config`).

État per-machine : `~/.agentic-workspace/reports.jsonl` (telemetry, override
`$AW_REPORTS`) et `~/.agentic-workspace/holdout/<name>/` (checks cachés).

## Aller plus loin

- **`aw context`** (= `shared/main-brief.md`) — le brief complet de la session
  main : flow, gates, hold-out, méthode. C'est la doc de référence.
- **`shared/procedure-core.md`** + tails — ce que lit l'agent dans son workspace.
- **`reports/`** — incidents et décisions datés, dont
  `2026-06-11-v2-redesign-contract-sealed.md` (architecture v2 et ses raisons).
- **`analysis/`** — post-mortems des workspaces livrés, moteur d'évolution de la
  procédure.

## License

MIT — see [LICENSE](LICENSE).
