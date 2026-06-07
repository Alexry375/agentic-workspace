# webapp-cinematic

- **Date livraison** : 2026-05-13
- **Outcome reports.jsonl** : ko
- **Localisation** : `/home/alexis/Global/Agents_Projects/n7-club-ia-sand/workspaces/n7-slides-web/workspaces/webapp-cinematic`

## Cause racine

Choix d'architecture incompatible avec la spec dès le départ : l'agent a rendu l'UI via `<Html transform>` de drei superposé au laptop 3D. Le `<Html>` reste une couche 2D surimposée, incapable de devenir une vraie surface zoomable contenue dans le maillage du laptop. La spec exigeait explicitement *"l'écran prend tout le viewport"* à localT ≈0.35, ce qui demande une texture rendue dans la géométrie 3D (RenderTexture / texture-to-mesh), pas un overlay DOM. L'agent a livré ce que l'overlay permet (transitions de phases, span=3 OK) sans relire la contrainte de zoom-fill et donc sans détecter que sa stack ne peut pas y répondre.

## Tests existants

Aucun test automatisé. Validation = inspection visuelle des 4 captures d'écran (`outputs/screenshots/`) sur les phases-clés de la timeline. Les captures montrent un rendu fonctionnel (vues qui défilent, tube cyan, transitions) mais ne révèlent pas que la `.device-screen` reste contrainte par le chassis CSS au lieu d'occuper ~95 % du viewport au pic du zoom.

## Un test aurait-il aidé ?

**Partiellement.** Un test géométrique aurait attrapé le symptôme : assertion sur `bbox(.device-screen) / viewport ≥ 0.9` à localT=0.35. Coût : ~10 lignes Playwright. Aurait forcé l'agent à constater l'écart **avant** la livraison au lieu d'attendre le retour humain. Mais le problème de fond est de cadrage — l'agent n'a pas vu que sa stack (`Html transform`) ne pouvait *physiquement pas* satisfaire la contrainte. Aucun test n'attrape un mauvais choix d'archi en amont ; ça relève d'un audit "spec ↔ choix de stack" avant écriture du premier composant.

## Leçon généralisable

- **Mesures géométriques > captures visuelles** pour toute spec qui dit "occupe le viewport / fill / cover". Une métrique chiffrée (px réels / px viewport) expose l'écart d'ordre de grandeur que la capture floue à la résolution thumbnail masque.
- **Audit "spec ↔ archi" avant code** : pour les specs visuelles 3D ou layout, un mini-test mental — *"ce que je vais écrire peut-il géométriquement atteindre cette contrainte ?"* — vaut une heure de code à refaire. Candidat à formaliser quand on aura ≥2 autres incidents du même type.
- **Symétrie avec `font-size-fda`** : pas de chiffre référent → métrique acceptée trop facilement.
