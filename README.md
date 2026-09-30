# Dhamet — ظامت

Application mobile du **Dhamet mauritanien** (ظامت, aussi appelé Srand /
اصرند), jeu de plateau traditionnel de la famille de l'alquerque et des
dames.

> **État du projet : phase 2, moteur de jeu.** Le moteur de règles (pur
> Dart) et ses tests sont en place. L'interface, l'IA, la persistance et le
> multijoueur viendront dans les phases suivantes (voir [Roadmap](#roadmap)).

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
`dhametRuleCatalog`.

## Architecture

```text
dhamet/
├── packages/
│   └── dhamet_engine/        Moteur de règles — pur Dart, sans Flutter
│       ├── lib/src/board/    Position, Direction, BoardTopology (graphe), Board
│       ├── lib/src/pieces/   Player, Piece
│       ├── lib/src/rules/    DhametRules (paramètres), catalogue des règles
│       ├── lib/src/moves/    Move, MoveGenerator, CaptureResolver, mouvements
│       ├── lib/src/state/    GameState
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
- des parties aléatoires qui vérifient les invariants à chaque coup, pour
  plusieurs jeux de règles.

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
| 2 bis | GameEndDetector, historique, undo/redo, SouvletRule | à faire |
| 3 | Consolidation des tests du moteur | en cours |
| 4 | Interface locale : accueil, partie, résultat, paramètres | à faire |
| 5 | IA : Minimax, alpha-bêta, évaluation, niveaux | à faire |
| 6 | Persistance hors ligne : historique, sauvegarde, reprise | à faire |
| 7 | Localisation : ar, fr, en, hassaniya | à faire |
| 8 | Backend NestJS + WebSocket | à faire |
| 9 | Jeu en ligne : salons, invitations, reconnexion | à faire |
| 10 | Classement | à faire |
| 11 | Tournois | à faire |

## Rules Sources

Détail et discussion de chaque source dans
[docs/rules.md § 16](docs/rules.md#16-sources) :

- « Strand ou Dhamet », jeuxstrategieter.free.fr (règle détaillée, soufflé,
  ouverture) ;
- « Dhamet », Wikipédia (fr), qui cite Ol Bah, *Jeux et Stratégie* n° 27
  (1984), et Mascort, *Les Jeux du Sahara* (2021) ;
- « Zamma », Wikipedia (en), Mats Winther, mindsports.nl et *World of
  Abstract Games* ;
- presse arabe : Noonpost, Al-Araby Al-Jadeed et Sky News Arabia
  (terminologie hassaniya, Fédération mauritanienne de Dhamet).
