# audit-conformite

- **Date livraison** : 2026-05-22
- **Outcome reports.jsonl** : partial
- **Localisation** : `/home/alexis/Global/My_projects/Relay_X/table_recherche/audit-marketing/workspaces/audit-conformite`

## Cause racine

Le tool `Agent` n'était pas exposé au runtime du workspace, alors que le prompt (`inputs/prompt.md:31-41`) spécifiait une cascade multi-modèles Haiku → Sonnet → Opus pour la phase analyse. L'orchestrateur Opus a détecté l'absence **tardivement** (après le harvest déterministe de 20 pages, déjà investi) et a basculé sur le fallback mono-Opus séquentiel — comportement autorisé par le prompt (*"la livraison prime"*). Le partial n'est donc pas une faute de l'agent mais une **détection tardive d'une contrainte d'environnement** : l'absence aurait pu être probée en 30 secondes au boot.

## Tests existants

Aucun test de capabilité au démarrage. Le `harvest.log` valide la phase déterministe (20 pages crawlées ✓), `candidates.json:4` admet rétrospectivement l'indisponibilité du tool `Agent`, mais aucune trace d'une tentative *early* (Agent call factice) pour vérifier le runtime avant d'engager la stratégie complète.

## Un test aurait-il aidé ?

**Oui, partiellement** — un **capability probe** au boot (lancer un `Agent` call trivial sur un document factice) aurait détecté l'indisponibilité en < 1 min au lieu d'après le harvest. Type : smoke test d'environnement, pas test fonctionnel. Aurait permis (a) abort + report immédiat, ou (b) basculement plan B annoncé d'emblée. Le résultat livré n'aurait pas changé (le fallback était prévu), mais le **temps perdu et la transparence** auraient été meilleurs. Note : l'auto-audit du workspace montre que le vrai impact qualité venait d'**un périmètre non-exploré** (checkout non crawlé) plus que de l'absence du tool — le multi-modèles aurait apporté du polish, pas de la couverture.

## Leçon généralisable

- **Capability probe au boot** : tout prompt qui repose sur un tool spécifique (Agent, MCP, WebFetch authentifié) doit ouvrir par un test factice de ce tool. Coût ~30 s, évite d'investir 30 min sur une stratégie morte. Symétrie avec `etoro` (probe de faisabilité Bugcrowd) — **2e occurrence**, candidat à 3.
- **Fallback codifié + validé à l'exécution.** Ici le fallback était dans le prompt (*"la livraison prime"*) — bon. Manquait : la validation **active** du chemin nominal au boot.
- **Impact qualité ≠ contrainte technique apparente.** L'agent a expliqué le partial par l'absence de tool, mais le vrai trou de couverture (checkout) n'avait rien à voir. Discipline : séparer dans le report *"contrainte d'environnement"* et *"trou de scope"* — éviter que la première serve d'alibi à la seconde.
