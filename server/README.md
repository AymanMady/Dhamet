# Serveur Dhamet

Serveur multijoueur **autoritaire** de Dhamet (phases 8 à 11) : comptes,
parties en ligne par WebSocket, classement Elo et tournois. Il implémente le
contrat [`docs/multiplayer.md`](../docs/multiplayer.md) ; les écarts sont
listés plus bas.

- NestJS 11 (TypeScript strict), WebSocket brut (`@nestjs/platform-ws`).
- TypeORM : PostgreSQL 16 en développement et en production, sql.js en
  mémoire pour les tests automatisés.
- **Les règles viennent uniquement du moteur Dart** (`packages/dhamet_engine`),
  compilé en JavaScript. Il n'y a pas de second moteur.

## Démarrage rapide

Prérequis : Node 22, npm 10, Dart SDK 3.13 (pour compiler le moteur),
Docker.

```bash
cd server
npm ci
cp .env.example .env            # puis choisir un JWT_SECRET
docker compose up -d db         # PostgreSQL 16 sur localhost:5436
npm run start:dev               # compile le moteur, puis API sur :3000
```

Tout en conteneurs (l'image compile le moteur Dart puis l'application) :

```bash
docker compose up -d --build    # db + api ; JWT_SECRET est obligatoire
docker compose down             # -v pour effacer aussi la base
```

## Commandes

| Commande | Rôle |
|---|---|
| `npm run build:engine` | `dart pub get` + `dart compile js -O2` du pont → `src/engine/generated/dhamet_engine.js` (ignoré par git) |
| `npm run build` | moteur puis `nest build` → `dist/` |
| `npm start` | `node dist/main` |
| `npm run start:dev` | moteur puis Nest en mode watch |
| `npm run lint` / `npm run format` | ESLint (typescript-eslint strict) / Prettier |
| `npm test` | tests unitaires (Jest) |
| `npm run test:e2e` | tests de bout en bout (Jest + supertest + client `ws`, base sql.js) |
| `npm run migration:run` | applique les migrations (après `npm run build`) |
| `npm run migration:generate -- src/database/migrations/Nom` | génère une migration depuis les entités (base démarrée, après `npm run build`) |
| `cd engine_bridge && dart test` | tests Dart du pont |

`build`, `test`, `test:e2e` et `start:dev` recompilent le moteur d'abord
(scripts `pre*`), ce qui demande le SDK Dart.

## Architecture

```text
server/
├── engine_bridge/            Paquet Dart : le moteur exposé à Node.js
│   ├── lib/engine_registry.dart   API JSON (parties ouvertes par id)
│   ├── bin/main.dart              point d'entrée dart2js (dart:js_interop)
│   ├── tool/build.dart            compile + préambule Node + module.exports
│   └── test/                      tests Dart du registre
├── src/
│   ├── engine/               EngineService : wrapper typé du bundle
│   ├── auth/                 inscription, connexion, invités, JWT, scrypt
│   ├── users/                entité User, profils
│   ├── ranking/              Elo, historique (Ranking), leaderboard
│   ├── games/                Game, GamePlayer, Move ; REST des parties
│   ├── rooms/                salons en mémoire, passerelle WebSocket, pendule
│   ├── tournaments/          round robin (méthode du cercle), classement
│   ├── database/             options TypeORM, DataSource CLI, migrations
│   └── config/               lecture et validation de l'environnement
└── test/                     tests e2e
```

Dépendances entre modules : `rooms` → `games` → `ranking` → `users` ;
`tournaments` → `rooms` ; `auth` est global. Les tournois apprennent le
début et la fin des parties par un écouteur (`GameLifecycleListener`) que
`GameplayService` notifie : pas de dépendance circulaire.

### Le pont vers le moteur Dart

`engine_bridge/bin/main.dart` publie avec `dart:js_interop` un objet
`dhametEngine` ; `tool/build.dart` le compile avec `dart compile js -O2`,
préfixe le préambule `node_preamble` (globals `self`, `scheduleImmediate`,
etc. attendus par dart2js) et termine par `module.exports =
self.dhametEngine`. Le résultat est un module CommonJS chargé par
`EngineService` avec `require`. Chargement et fonctionnement vérifiés sous
Node 22 (tests Jest et image Docker).

L'API échange des chaînes JSON et ne lève pas d'exception Dart : les refus
attendus reviennent sous la forme `{"ok": false, "error": {code, message}}`.

| Fonction | Rôle |
|---|---|
| `create(id)` | nouvelle partie, `DhametRules.standard`, `UndoPolicy.disabled` |
| `load(id, gameJson)` | ouvre une partie sauvegardée (rejouée et vérifiée) |
| `play(id, moveJson, isoTimestamp)` | joue un coup : `ILLEGAL_MOVE` / `GAME_OVER`, sinon la copie du coup par le moteur + l'état |
| `resign(id, color)`, `loseOnTime(id, color)` | résultats déclarés |
| `snapshot(id)` | `{currentPlayer, plyCount, result, pieceCounts, game}` |
| `legalMoves(id)` | `[{move, notation}]` |
| `close(id)`, `size()` | libère une partie, nombre de parties ouvertes |

**Choix : un registre de parties côté Dart** plutôt que des appels sans
état. Un appel sans état devrait reconstruire la partie par
`Game.fromJson`, qui rejoue et revérifie tout l'historique à chaque coup.
Mesures sous Node 22 (bundle `-O2`, 40 parties aléatoires, 4 430 coups, sur
la machine de développement chargée) :

| Opération | Temps moyen |
|---|---|
| `play` (vérification, historique, fin de partie, **et** JSON complet de la partie) | ~0,54 ms (max 7 ms) |
| `legalMoves` | ~0,07 ms |
| `load` d'une partie de 111 coups (rejeu vérifié) | ~5,3 ms |

Le registre évite donc ~5 ms par coup en fin de partie et un coût
quadratique sur la partie. Les parties en cours vivant de toute façon en
mémoire (salons actifs), le registre suit leur cycle de vie : `create` au
démarrage, `close` à la fin.

### Autorité du serveur

Pour `game:move`, dans l'ordre du contrat : validation du message
(`INVALID_MESSAGE`), salon (`ROOM_NOT_FOUND`), appartenance
(`NOT_IN_ROOM`), partie en cours (`GAME_NOT_STARTED` / `GAME_OVER`), trait
(`NOT_YOUR_TURN`), `ply` (`STALE_PLY`), puis légalité par le moteur
(`ILLEGAL_MOVE`). Le serveur horodate le coup, le joue avec le moteur,
enregistre la ligne `Move` et le JSON `Game`, puis diffuse **la copie du
coup produite par le moteur** (jamais celle du client). Captures, fin de
partie et résultat sont toujours recalculés par le moteur.

Chaque salon traite ses opérations une par une (file `SerialQueue`) : coups,
abandons, pendule et forfaits ne s'entremêlent pas. Les fins de partie
(mises à jour d'Elo) et les résultats de tournoi passent aussi par des
files : le serveur est **mono-instance** (salons en mémoire). Passer à
plusieurs instances demanderait un état partagé (Redis…) et des sessions
collantes.

### Base de données

Entités portables (aucun type propre à PostgreSQL : `simple-json` → `text`,
`uuid` → `varchar` sous SQLite) : `User`, `Game`, `GamePlayer`, `Move`,
`Room`, `Ranking`, `Tournament`, `TournamentPlayer`, `TournamentMatch`.

- **Production / développement** : le schéma vient des migrations
  (`src/database/migrations`), appliquées au démarrage
  (`DB_MIGRATIONS_RUN=true` par défaut). `DB_SYNCHRONIZE=true` n'est à
  utiliser qu'en développement, pour essayer une modification d'entité.
- **Tests** : sql.js en mémoire, schéma synchronisé.
- Le processus Node tourne en UTC (`TZ=UTC`) : les colonnes `timestamp`
  PostgreSQL sont lues et écrites en UTC.
- Au démarrage, les parties restées `playing` passent en `aborted` et les
  salons non terminés en `finished` (ils ne vivaient qu'en mémoire) ; les
  rencontres de tournoi sans résultat reçoivent un nouveau salon.

## Configuration

Voir [`.env.example`](.env.example).

| Variable | Défaut | Rôle |
|---|---|---|
| `PORT` | 3000 | port HTTP et WebSocket |
| `JWT_SECRET` | secret de dev | **obligatoire** si `NODE_ENV=production` |
| `JWT_EXPIRES_IN_SECONDS` | 2 592 000 (30 j) | durée des jetons |
| `DATABASE_URL` ou `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | `localhost:5436`, `dhamet`/`dhamet`/`dhamet` | PostgreSQL |
| `DB_TYPE` | `postgres` | `sqljs` pour les tests |
| `DB_MIGRATIONS_RUN` / `DB_SYNCHRONIZE` | `true` / `false` | gestion du schéma |
| `RECONNECT_GRACE_SECONDS` | 60 | délai de reconnexion (décimales permises) |
| `CORS_ORIGINS` | `*` | origines autorisées, séparées par des virgules |
| `AUTH_THROTTLE_LIMIT` / `AUTH_THROTTLE_TTL_SECONDS` | 20 / 60 | limite de débit de `/api/auth/*` |
| `DB_HOST_PORT`, `API_PORT` | 5436, 3000 | ports publiés par docker compose |

Le port PostgreSQL publié par `docker-compose.yml` est **5436** : 5432 et
5433 sont déjà pris par d'autres projets sur la machine de développement.

## Tests

- **Unitaires** (`src/**/*.spec.ts`) : Elo, codes de salon, appariements
  round robin (chaque paire une fois, couleurs équilibrées à une près),
  pendule, hachage des mots de passe, configuration, **parité avec le moteur
  Dart** (3 premiers coups `d4-e5 e4-e5 f4-e5`, ouverture traditionnelle
  acceptée coup par coup puis exactement `d3xd5 e4xc4 e3xc5`, coups illégaux
  et malformés refusés, abandon, temps, aller-retour JSON, sauvegarde
  falsifiée refusée) et **ordre de validation des coups** (codes d'erreur).
- **E2E** (`test/*.e2e-spec.ts`, application complète sur un port
  aléatoire) : inscription, connexion, invités, `/users/me`, 409, 401, 400 ;
  partie complète entre deux clients WebSocket (création, code, prêt,
  `game:started`, coups diffusés, `NOT_YOUR_TURN`, `STALE_PLY`,
  `ILLEGAL_MOVE`, `NOT_IN_ROOM`, `ROOM_FULL`, `INVALID_MESSAGE`,
  `GAME_OVER`, abandon et variations Elo, invités non classés) ; une partie
  aléatoire jouée jusqu'à sa fin réglementaire par deux clients qui rejouent
  les coups avec leur propre moteur ; classement ; `GET /api/games/:id`
  rejoué par le moteur ; reconnexion dans le délai (`game:sync`,
  `player:reconnected`) et forfait au-delà ; pendule qui tombe
  (`timeout`) ; tournoi (création, inscriptions, départ, salons, résultat et
  classement, fin du tournoi) ; fermeture `4401` sans jeton valide.

## Deviations from docs/multiplayer.md

Choix faits là où le contrat est muet ou ambigu :

1. **Code d'erreur supplémentaire `INTERNAL_ERROR`** pour une panne
   inattendue du serveur (le contrat ne prévoit aucun code pour ce cas).
2. **Message invalide ou coup malformé.** Un `data` qui ne respecte pas le
   schéma (`code` absent, `ply` non entier ou négatif, `move` qui n'est pas
   un objet, option de salon invalide) donne `INVALID_MESSAGE`, avant toute
   autre vérification. Un objet `move` que le moteur ne sait pas lire (case
   hors plateau, pièce inconnue…) est traité à l'étape 5 : `ILLEGAL_MOVE`.
   Une trame non JSON ou un événement inconnu donnent `INVALID_MESSAGE`
   (avec `event: null` si la trame n'est pas lisible).
3. **`graceSeconds`** vaut `RECONNECT_GRACE_SECONDS` (60 par défaut, comme
   le contrat).
4. **Parties classées.** Un salon créé par un invité n'est jamais classé
   (`room.rated = false`). Si un invité rejoint un salon classé, la partie
   ne l'est pas (`gameSummary.rated = false`, pas de `ratingChanges`) ; le
   `rated` du salon reste celui demandé.
5. **Elo.** Les classements sont des entiers : la variation des Blancs est
   arrondie à l'entier le plus proche et celle des Noirs est son opposée
   (aucun point créé ni perdu).
6. **Classement.** `GET /api/leaderboard` ne liste que les comptes non
   invités ; `limit` va de 1 à 200 ; égalités départagées par ancienneté.
7. **Routes publiques.** Les lectures (`/users/:id`, `/users/:id/games`,
   `/games/:id`, `/leaderboard`, `GET /tournaments…`) ne demandent pas de
   jeton ; `/users/me` et les écritures des tournois en demandent un.
8. **Salons.**
   - `color` vaut `"random"` et `rated` vaut `false` par défaut. Le code
     est accepté en minuscules.
   - `room:join` par un membre du salon équivaut à `room:rejoin`.
   - `room:ready` pendant la partie est ignoré ; après la fin, il renvoie
     `GAME_OVER`.
   - `game:sync` avant le début renvoie `GAME_NOT_STARTED` ; après la fin,
     il renvoie la partie finale.
   - Quitter un salon en attente libère la place. L'hôte qui part passe la
     main à l'autre joueur, et un salon vide est fermé.
   - Dans un salon en attente, un joueur déconnecté perd son statut « prêt ».
     Un salon en attente sans aucun joueur connecté est fermé après le délai
     de grâce (sauf salon de tournoi).
   - Un salon terminé reste en mémoire pendant le délai de grâce
     (`game:sync`, `room:rejoin`), puis son code est libéré ; la partie
     reste consultable par `GET /api/games/:id`.
9. **Diffusion.** Les événements de salon et de partie vont à toutes les
   connexions ouvertes des membres (un compte peut en avoir plusieurs).
   `game:sync`, la réponse à `room:rejoin`, `pong` et `error` ne vont qu'à
   la connexion qui a fait la demande. Un joueur qui garde une autre
   connexion ouverte n'est pas considéré comme déconnecté.
10. **Pendule.** `initialSeconds` entre 0,1 et 10 800, `incrementSeconds`
    entre 0 et 600. `clocks` est en millisecondes entières. Si un coup
    arrive alors que le temps de son auteur est écoulé, la partie se termine
    par `timeout` et le coup est refusé avec `GAME_OVER`.
11. **Tournois.**
    - `start` par un autre que le créateur renvoie 403 ; `join` hors
      inscriptions ou dans un tournoi complet renvoie 400. S'inscrire deux
      fois ne change rien (200). Il faut au moins 2 joueurs, et `maxPlayers`
      va de 2 à 16.
    - Les invités peuvent s'inscrire ; leurs parties ne sont pas classées.
    - Ordre d'appariement : ordre d'inscription (`seed`). Avec un nombre
      impair de joueurs, un joueur est exempt à chaque ronde, **sans point**.
    - Classement : score décroissant, puis ordre d'inscription. Le tournoi
      passe à `finished` quand toutes les rencontres ont un résultat.
    - Les places d'un salon de tournoi sont fixes (couleurs données par la
      méthode du cercle, `hostId` = Blancs). `room:leave` n'y retire que
      l'état « prêt », et le salon n'expire pas.
12. **Modèle de données**, compléments d'implémentation :
    - un `id` uuid pour `Room`, `GamePlayer`, `Ranking`, `TournamentPlayer`
      (un code de salon n'est unique que parmi les salons actifs) ;
    - `User.usernameKey` (nom en minuscules, unique) pour l'unicité sans
      tenir compte de la casse ;
    - `Game.plyCount`, `Room.tournamentMatchId`, `TournamentPlayer.seed` ;
    - `GamePlayer.ratingAfter` reste `null` pour une partie non classée.
13. **Statut `aborted`** : attribué au démarrage du serveur aux parties
    restées en cours lors de l'exécution précédente.
14. **Invités** : `invite_` suivi de 4 caractères `[a-z0-9]` (plus en cas
    de collision). Sans mot de passe, leur jeton est leur seul identifiant.

## Limites connues

- Une seule instance de serveur (salons, pendules et files en mémoire).
- Pas de proposition de nulle en ligne (`end.draw` est NEEDS_VERIFICATION
  et désactivé dans `DhametRules.standard`) ; le demi-point de nulle est
  prévu dans le classement et les tournois, mais ne peut pas survenir avec
  les règles standard.
- Pas de revanche dans un même salon : une nouvelle partie demande un
  nouveau salon.
- Élimination directe (`singleElimination`) : réservée, renvoie 400.
