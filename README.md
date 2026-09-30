# Dhamet — ظامت

Application mobile du **Dhamet mauritanien** (ظامت, aussi appelé Srand /
اصرند), jeu de plateau traditionnel de la famille de l'alquerque et des
dames.

> **État du projet : phase 2 bis, noyau du jeu.** Sont en place, en pur
> Dart et testés :
>
> - le moteur de règles ;
> - la fin de partie ;
> - l'historique, avec annuler / rétablir ;
> - la sauvegarde JSON.
>
> L'interface, l'IA et le multijoueur viendront dans les phases suivantes
> (voir [Roadmap](#roadmap)).

## Description

Objectifs :

- jouer à deux sur le même appareil, contre l'IA, et plus tard en ligne
  (partie privée par code, puis matchmaking, classement et tournois) ;
- respecter fidèlement les règles traditionnelles et l'identité culturelle
  du jeu ;
- fonctionner **hors ligne** pour le jeu local, l'IA, le tutoriel et
  l'historique ;
- proposer l'arabe (avec le RTL), le français, l'anglais et le hassaniya.

## Règles

Référence complète, avec le statut de chaque règle (`CONFIRMED`, `LIKELY`,
`VARIANT`, `NEEDS_VERIFICATION`) : **[docs/rules.md](docs/rules.md)**.

En bref :

- plateau de 9 × 9 intersections au tracé d'alquerque (14 diagonales) ;
- 40 pièces par camp, centre vide ;
- le pion avance d'un pas, tout droit ou en diagonale ;
- la prise se fait par saut court, dans toutes les directions ;
- la prise est obligatoire, la rafle maximale est imposée et les pièces
  prises sont retirées immédiatement ;
- un pion qui termine son coup sur la dernière rangée devient **Sultan**,
  qui se déplace et prend à distance ;
- on gagne en prenant toutes les pièces adverses ou en bloquant
  l'adversaire.

Les règles incertaines (premier joueur, soufflé/Souvlet, demi-tour du
Sultan, nulles…) sont paramétrables dans `DhametRules` et listées dans
`dhametRuleCatalog`. Les tableaux récapitulatifs de
[docs/rules.md](docs/rules.md) sont :

- [Confirmed Rules](docs/rules.md#confirmed-rules) ;
- [Unconfirmed Rules](docs/rules.md#unconfirmed-rules) ;
- [Configurable Rules](docs/rules.md#configurable-rules).

## Architecture

```text
dhamet/
├── packages/
│   └── dhamet_engine/        Moteur de règles — pur Dart, sans Flutter
│       ├── lib/src/board/    Position, Direction, BoardTopology (graphe), Board
│       ├── lib/src/pieces/   Player, Piece
│       ├── lib/src/rules/    DhametRules, SouvletRule, DrawRules, OpeningRule, catalogue
│       ├── lib/src/moves/    Move, MoveGenerator, CaptureResolver, TraditionalEncounter
│       ├── lib/src/state/    GameState
│       ├── lib/src/game/     Game, GameHistory, MoveRecord, GameEndDetector,
│       │                     GameResult, UndoPolicy
│       ├── lib/src/serialization/  Lecture JSON défensive
│       ├── benchmark/        Mesures de performance
│       └── test/             Tests du moteur
├── lib/                      Application Flutter (phase 4+)
├── docs/rules.md             Règles et sources
└── android/, ios/
```

Principes :

- **Le moteur est un package Dart séparé.** Il ne peut pas dépendre de
  Flutter, se teste avec `dart test` et pourra servir à des outils ou à la
  validation côté serveur.
- **Le moteur est la seule source de vérité.** L'interface, l'IA et le
  serveur passent tous par `MoveGenerator` et `GameState.play()`.
- **Les états sont immuables.** Jouer un coup renvoie un nouveau
  `GameState`, ce qui simplifie l'historique, l'annulation et la recherche
  de l'IA.
- **Les règles sont paramétrables.** Chaque règle incertaine correspond à un
  paramètre de `DhametRules`.

Architecture prévue de l'application (phase 4+) : `lib/app` (router,
thème), `lib/core` (constantes, erreurs, localisation) et
`lib/features/{game,ai,multiplayer,profile,settings,tutorial}`, chacun
découpé en `domain/`, `data/` et `presentation/`. L'IA ira dans un package
séparé, `packages/dhamet_ai`.

## Installation

Prérequis : Flutter 3.47+ (Dart 3.13+).

```bash
flutter pub get
(cd packages/dhamet_engine && dart pub get)
```

## Development

```bash
dart format .
flutter analyze
(cd packages/dhamet_engine && dart analyze)
```

## Tests

```bash
# Moteur (rapide, sans Flutter)
cd packages/dhamet_engine
dart test
dart test --coverage-path=coverage/lcov.info   # couverture

# Application
flutter test
```

Les tests du moteur couvrent :

- le plateau : positions, connexions, 14 diagonales, points ouverts et
  fermés ;
- les déplacements des pions et du Sultan ;
- les prises : simples, obligatoires, arrière, latérales, multiples et
  majoritaires ;
- la promotion ;
- les exemples chiffrés des sources, dont l'ouverture traditionnelle
  « rencontre » ;
- la fin de partie : élimination, blocage, nulles optionnelles ;
- l'historique et l'annulation : après une capture, une rafle, une
  promotion ou un coup de Sultan, redo, invalidation du redo, comparaison
  à un modèle de référence ;
- la sérialisation : allers-retours, formats figés, sauvegardes
  corrompues ;
- des parties aléatoires qui vérifient les invariants à chaque coup, pour
  plusieurs jeux de règles.

Mesures de performance (compilé AOT, comme une version release) :

```bash
cd packages/dhamet_engine
dart compile exe benchmark/engine_benchmark.dart -o /tmp/dhamet_bench
/tmp/dhamet_bench
```

## Build Android

```bash
flutter build apk --debug
```

Identifiant d'application provisoire : `mr.dhamet.dhamet`.

## Build iOS

```bash
flutter build ios --debug --no-codesign   # macOS + Xcode requis
```

## Game Engine

```dart
import 'package:dhamet_engine/dhamet_engine.dart';

var state = GameState.initial();              // Blancs au trait
print(state.legalMoves);                      // [d4-e5, e4-e5, f4-e5]
state = state.play(state.legalMoves.first);   // vérifie la légalité
print(state.board);                           // diagramme texte
```

- `BoardTopology` : graphe explicite des lignes (`adjacency`, `ray`,
  `segments` pour dessiner le plateau).
- `MoveGenerator` : coups légaux (prise obligatoire, rafle maximale).
- `CaptureResolver` : rafles complètes d'une pièce.
- `DhametRules` : règles paramétrables ; `dhametRuleCatalog` : statut de
  chaque règle.

### Partie, historique, annuler / rétablir

```dart
var game = Game.start(undoPolicy: UndoPolicy.unlimited); // partie locale
game = game.play(game.state.legalMoves.first, timestamp: DateTime.now());
game = game.undo();          // état précédent exact, sans recalcul
game = game.redo();
print(game.result);          // null tant que la partie continue
```

- `Game` est une session immuable : historique, politique d'annulation et
  résultat.
  - Méthodes : `play`, `undo`, `redo`, `resign`, `loseOnTime`, et
    `agreeToDraw` si les règles l'autorisent.
- `GameHistory` et `MoveRecord` conservent pour chaque coup :
  - le joueur, le départ, l'arrivée et la pièce ;
  - les positions **et** les pièces capturées ;
  - la promotion et l'horodatage ;
  - l'**état avant et l'état après**.

  Annuler et rétablir ne font que déplacer un curseur entre des états
  enregistrés. Jouer après une annulation efface les coups annulés.
- `UndoPolicy` : `disabled` par défaut, à garder pour les parties en ligne
  ou compétitives ; `unlimited` ou `limited(n)` pour les parties locales.
- `GameEndDetector` détecte, dans cet ordre :
  - l'élimination ;
  - le blocage ;
  - la répétition, en option.

  Les nulles sont désactivées par défaut (`DrawRules.none`).

### Sauvegarde (JSON)

`Game.toJson()` / `Game.fromJson()`, avec un `toJson` / `fromJson` pour
chaque type : `GameState`, `Board`, `Piece`, `Player`, `Position`, `Move`,
`DhametRules`, `GameHistory`, `GameResult` et `UndoPolicy`.

```json
{
  "format": "dhamet.game",
  "version": 1,
  "undoPolicy": {"enabled": true, "maxDepth": null},
  "declaredResult": null,
  "history": {
    "initialState": {
      "board": ["bbbbbbbbb", "…", "bbbb.wwww", "…", "wwwwwwwww"],
      "currentPlayer": "white", "plyCount": 0, "rules": {"…": "…"},
      "lastMove": null
    },
    "moves": [{
      "move": {"piece": "w", "from": "d4", "path": ["e5"], "captured": [], "promotes": false},
      "capturedPieces": [], "timestamp": "2026-09-30T10:00:00.000Z"
    }],
    "cursor": 1
  }
}
```

- Le plateau est écrit en 9 lignes de 9 symboles, rangée 9 en premier :
  `.` vide, `w`/`b` pion, `W`/`B` Sultan.
- Seuls l'état initial et les coups sont stockés. Au chargement, chaque coup
  est **rejoué et revérifié**. Un coup illégal, des pièces capturées
  incohérentes ou un format inconnu lèvent une `FormatException`.
- Un paramètre de règle absent prend sa valeur par défaut, ce qui garde les
  anciennes sauvegardes lisibles.
- Taille : environ 130 octets par coup.

### Performances

Mesurées sur 40 parties aléatoires (4 416 coups), compilé AOT sur un
poste Linux de développement :

| Opération | Temps |
|---|---|
| Génération des coups légaux | ~33 µs / position |
| Appliquer un coup (sans vérification) | ~3,4 µs |
| Appliquer un coup vérifié (génération + contrôle) | ~31 µs |
| `Game.play` (vérification + historique + fin de partie) | ~57 µs |
| Annuler / rétablir | < 1 µs |
| Sauvegarder une partie (`toJson` + `jsonEncode`) | ~0,4 ms |
| Charger une partie (`jsonDecode` + rejeu vérifié) | ~3 ms |

## AI

Phase 5, pas encore commencée : Minimax avec élagage alpha-bêta, niveaux
Facile, Moyen, Difficile et Expert, calculs dans un isolate. L'IA
utilisera exclusivement `MoveGenerator`.

## Multiplayer

Phases 8 et 9, pas encore commencées : serveur NestJS + WebSocket
**autoritaire**, qui revalide chaque coup (joueur, tour, légalité, état de
la partie). Le moteur étant en Dart, deux pistes sont possibles côté
serveur : compiler le moteur en JavaScript, ou en faire un portage
TypeScript validé par des vecteurs de test communs générés depuis ce
moteur.

## Localization

Phase 7, pas encore commencée : arabe (RTL), français, anglais et
hassaniya. Aucun texte ne sera codé en dur dans les widgets.

## Roadmap

| Phase | Contenu | État |
|---|---|---|
| 1 | Recherche des règles, `docs/rules.md` | ✅ (questions ouvertes listées) |
| 2 | Moteur : Board, Position, Piece, Player, GameState, Move, MoveGenerator | ✅ |
| 2 bis | GameEndDetector, historique, undo/redo, sérialisation, SouvletRule, OpeningRule | ✅ |
| 3 | Consolidation des tests du moteur | ✅ (couverture ≈ 99 %) |
| 4 | Interface locale : accueil, partie, résultat, paramètres | à faire |
| 5 | IA : Minimax, alpha-bêta, évaluation, niveaux | à faire |
| 6 | Persistance hors ligne : historique, sauvegarde, reprise | format JSON prêt ; stockage à faire |
| 7 | Localisation : ar, fr, en, hassaniya | à faire |
| 8 | Backend NestJS + WebSocket | à faire |
| 9 | Jeu en ligne : salons, invitations, reconnexion | à faire |
| 10 | Classement | à faire |
| 11 | Tournois | à faire |

## Rules Sources

Détail et discussion de chaque source dans
[docs/rules.md § 15](docs/rules.md#15-sources) :

- « Strand ou Dhamet », jeuxstrategieter.free.fr (règle détaillée, soufflé,
  ouverture) ;
- « Dhamet », Wikipédia (fr), qui cite Ol Bah, *Jeux et Stratégie* n° 27
  (1984), et Mascort, *Les Jeux du Sahara* (2021) ;
- « Zamma », Wikipedia (en), Mats Winther, mindsports.nl et *World of
  Abstract Games* ;
- presse arabe : Noonpost, Al-Araby Al-Jadeed et Sky News Arabia
  (terminologie hassaniya, Fédération mauritanienne de Dhamet).
