# Design — le Dhamet sur le sable

Le design reproduit une image de référence générée avec Gemini : une partie
jouée dans le sable devant des maisons en banco. On y voit des bâtonnets
plantés, des cailloux et des planches de bois patiné en guise de boutons.
L'image sert de **référence artistique** et n'est pas embarquée dans
l'application. Tout est redessiné par le code (`CustomPainter`), sans
aucune image bitmap. Le rendu reste net à toutes les tailles, et chaque
élément reste interactif.

## De l'image au code

| Élément de l'image | Rendu | Où |
|---|---|---|
| Sable (grain, taches, rides du vent, petits cailloux) | Procédural, déterministe (graine) | `core/widgets/sand/sand_texture.dart` (`paintSand`, `SandPainter`) |
| Arrière-plan flou (ciel, murs en banco) | Horizon peint et flouté, brume qui le fond dans le sable, vignettage | `core/widgets/sand/sand_background.dart` |
| Aire de jeu lissée à la main | Carré au bord irrégulier, bourrelet de sable | `board/board_surface_painter.dart` |
| Lignes tracées au doigt | Sillons ombrés et éclairés, légèrement tremblés, qui dépassent aux extrémités. Les lignes traditionnellement non tracées (rangées 2, 4, 6, 8 et colonnes b, d, f, h) sont plus légères | `board/board_surface_painter.dart` |
| Trous (positions) | Petit creux à chaque intersection | `board/sand_marks.dart` |
| Bâtonnets (pièces claires) | Bâtonnet planté debout : écorce, nœud, pointe taillée, petit tas de sable au pied, ombre portée | `pieces/piece_renderer.dart` |
| Cailloux (pièces foncées) | Caillou au contour irrégulier : dôme éclairé, mouchetures, ombre de contact | `pieces/piece_renderer.dart` |
| Lumière | Soleil en haut à gauche, ombres vers le bas à droite (`BoardGeometry.shadowDirection`) | tous les peintres |
| Planches « NEW GAME » | `WoodButton` : planche patinée, veinage, nœud, clous, texte gravé ; elle s'enfonce quand on appuie | `core/widgets/wood_button.dart` |
| Petites icônes du coin (bâtonnets, cailloux) | Compteurs de pièces et de Sultans dans les panneaux des joueurs | `hud/game_panels.dart` |
| Main qui saisit une pièce | Pas de main dessinée : la pièce sélectionnée se soulève (ombre détachée, légère mise à l'échelle) | `board/board_layers.dart` |

Chaque pièce a ses petites imperfections (inclinaison, longueur, teinte,
contour), tirées d'une graine (`PieceLook`). `PieceVariants` garde cette
apparence attachée à la pièce quand elle se déplace : un caillou garde sa
forme d'une intersection à l'autre. Ce suivi est purement visuel, le moteur
ne connaît pas l'identité des pièces.

**Sultan.** Sur le sable, on superpose un second pion (docs/rules.md § 8).
L'application dessine donc deux bâtonnets croisés, liés par une cordelette
indigo, ou un caillou clair posé sur le caillou sombre. C'est un choix
visuel, pas une règle.

## Architecture

```text
dhamet_engine            règles (pur Dart) — inchangé
      ↓
GameController / GameSession   état de la partie, sélection, IA
      ↓
board/       DhametBoard : géométrie, sable et tracé, indications, sémantique
      ↓
pieces/      PieceRenderer (bâtonnets, cailloux, Sultans), PieceLook,
             PieceVariants, PieceIcon
      ↓
hud/         PlayerPanel, GameStatus, GameActions, PauseMenu, ResultSign,
             CaptureChoicePanel, DeveloperPanel
      ↓
animations/  MoveTimeline (chronologie pure, testée), effets de sable
```

Tous ces dossiers sont dans `lib/features/game/presentation/`. Ce qui est
partagé au-delà du jeu se trouve dans `lib/core/widgets/` : le sable,
`SandBackground`, `SandPlate`, `WoodButton` et `RasterizedPaint`. Les couleurs de la scène sont
dans `BoardPalette` (`app/theme/app_theme.dart`), avec deux ambiances :
**midi** (thème clair) et **crépuscule** (thème sombre). Les matières des
pièces et des planches sont dans `AppColors`.

`DhametBoard` reste purement visuel : il signale les taps et ne décide
jamais de ce qui est légal. Un tap sur le haut d'un bâtonnet, qui dépasse
de son intersection, sélectionne ce bâtonnet (`BoardGeometry.positionAt`).

## Couches de rendu et performances

Le plateau est peint en couches superposées. Chacune a son
`RepaintBoundary` et ne se repeint que lorsque c'est nécessaire :

1. **Sable et tracé** : peints une seule fois dans une image
   (`RasterizedPaint`), refaite seulement si la taille ou le thème changent.
2. **Indications sous les pièces** : traînée du dernier coup, anneaux,
   creux des destinations.
3. **Pièces au repos** : elles aussi gardées en image, refaite seulement
   quand la position ou la sélection changent. Toutes les ombres sont
   peintes d'abord, puis les pièces, de l'arrière vers l'avant.
4. **Effets** : pièce soulevée, croix sur les pièces à prendre, animation
   du coup. C'est la seule couche repeinte à chaque image d'une animation.
5. **Sémantique** : une zone par intersection pour les lecteurs d'écran.

Pourquoi des images : Impeller, le moteur de rendu par défaut sur
Android, n'a pas de cache raster. Sans elles, les milliers de grains de
sable et les ombres floutées des 80 pièces seraient redessinés à chaque
image d'une animation. L'arrière-plan (`SandBackground`) suit le même
principe. Aucune animation ne tourne en boucle : l'écran est au repos entre
deux actions.

## Indications

| Situation | Marque |
|---|---|
| Pièce sélectionnée | Soulevée, anneau indigo tracé autour de son pied |
| Destination | Creux dans le sable, point indigo au fond |
| Prise possible | Anneau ocre sur l'arrivée, chemin pointillé au doigt, croix ocre sur les pièces prises |
| Prise obligatoire | Anneau ocre en pointillés autour des pièces qui doivent prendre |
| Dernier coup | Traînée dans le sable, empreinte au départ, halo doré à l'arrivée, creux là où des pièces ont été prises |

Les marques diffèrent par leur forme, pas seulement par leur couleur.

## Animations

La chronologie d'un coup (`MoveTimeline`) :

1. la pièce est soulevée ;
2. elle suit son chemin et saute par-dessus chaque pièce prise ;
3. chaque pièce prise se soulève et s'efface, dans une bouffée de sable, et
   laisse un creux ;
4. la pièce est reposée, avec une petite bouffée de sable ;
5. un nouveau Sultan reçoit sa seconde pièce, dans un anneau doré.

En fin de partie, une planche « Victoire » ou « Défaite » tombe sur le
plateau. Les animations respectent le réglage « Animations » et l'option
système « réduire les animations ».

## Responsive

- Le plateau est toujours carré (`AspectRatio`), jamais déformé, et prend
  toute la place disponible.
- En **portrait**, le HUD tient en trois rangées :
  - en haut : bouton retour, panneau de l'adversaire, bouton pause ;
  - au-dessus du plateau : le statut ;
  - en bas : le panneau du joueur et les planches d'action.
- Sur **petit téléphone** (hauteur < 640), les espacements sont réduits et la
  pastille « Au trait » ne garde que son icône.
- En **paysage** et sur **tablette** large, le HUD passe dans un panneau
  latéral.
- En arabe et en hassaniya, la mise en page est inversée (RTL). La lumière,
  elle, ne change pas de côté.
