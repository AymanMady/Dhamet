# Multijoueur — contrat client / serveur

Ce document est le **contrat** entre l'application Flutter (`lib/`) et le
serveur NestJS (`server/`). Toute évolution du protocole doit d'abord être
reportée ici.

## Principes

- **Le serveur fait autorité.** Il ne fait jamais confiance au client : il
  revérifie l'authentification, l'appartenance au salon, le tour, la
  légalité du coup, les captures et l'état de la partie.
- **Les règles ont une seule source.** Le serveur utilise le moteur Dart
  (`packages/dhamet_engine`) compilé en JavaScript, via le pont
  `server/engine_bridge`. Il n'existe pas de second moteur à maintenir.
- **Formats de données.** `Move`, `GameState`, `DhametRules`, `GameResult`
  et `Game` utilisent le JSON du moteur (voir `README.md`, section
  « Sauvegarde »).
- **Règles en ligne.** Les parties en ligne se jouent en
  `DhametRules.standard`, et `UndoPolicy.disabled` s'applique toujours.
  L'annulation est impossible en ligne.

## Authentification (REST)

Préfixe : `/api`. Le corps et les réponses sont en JSON. Les routes
protégées attendent l'en-tête `Authorization: Bearer <token>` (JWT).

| Méthode | Route | Corps | Réponse |
|---|---|---|---|
| POST | `/api/auth/register` | `{username, password}` | `201 {token, user}` |
| POST | `/api/auth/login` | `{username, password}` | `200 {token, user}` |
| POST | `/api/auth/guest` | `{username?}` | `201 {token, user}` (compte invité, sans mot de passe) |
| GET | `/api/users/me` | — | `200 user` |
| DELETE | `/api/users/me` | — | `204` sans corps (suppression du compte, voir plus bas) |
| GET | `/api/users/:id` | — | `200 user` (profil public) |

`user` = `{id, username, isGuest, rating, wins, losses, draws, gamesPlayed, createdAt}`.

- `username` : de 3 à 20 caractères parmi `[A-Za-z0-9_]`, unique sans tenir
  compte de la casse.
- `password` : au moins 8 caractères.
- Un invité sans `username` reçoit un nom `invite_XXXX`.

Erreurs : `{statusCode, message, error}` au format Nest. Codes utilisés :
400 (données invalides), 401 (non authentifié, jeton expiré ou compte
supprimé), 404, 409 (nom déjà pris).

### Suppression de compte

`DELETE /api/users/me` supprime le compte du jeton, invité compris
(exigence de Google Play : un compte créé dans l'application doit pouvoir
y être supprimé). Elle n'est jamais refusée : pas de `409`. Avant de la
confirmer, le client doit donc prévenir le joueur qu'une partie en cours et
ses rencontres de tournoi restantes seront perdues.

- Le compte est **anonymisé**, pas effacé : son nom devient `deleted_`
  suivi de 4 caractères `[a-z0-9]` (plus en cas de collision), et son mot de
  passe et son avatar sont effacés. Les parties, classements et tournois des
  autres joueurs restent intacts et le montrent sous ce nom.
- L'ancien nom redevient libre pour une nouvelle inscription.
- Le compte ne peut plus servir : ses jetons reçoivent `401` (REST) et la
  fermeture `4401` (WebSocket), et ses connexions ouvertes sont fermées avec
  ce code. La connexion par mot de passe échoue (`401`).
  `GET /api/users/:id` et `GET /api/users/:id/games` renvoient `404`, et le
  compte disparaît du classement.
- **Partie en cours** : elle est perdue par abandon
  (`GameEndReason.resignation`), comme avec `room:leave`. L'adversaire
  reçoit `game:over` (et `ratingChanges` si elle est classée).
- **Salon en attente** : le compte le quitte comme avec `room:leave`.
  L'autre joueur devient hôte et un salon vide est fermé.
- **Tournoi pas encore commencé** : l'inscription est retirée. Un tournoi
  que le compte a créé est supprimé, car personne d'autre ne pourrait le
  démarrer (`GET /api/tournaments/:id` renvoie alors `404`).
- **Tournoi en cours** : chaque rencontre du compte sans résultat est
  perdue par abandon. `result` vaut `{winner: <couleur de l'adversaire>,
  reason: "resignation"}` et l'adversaire marque 1 point ; `gameId` reste
  `null` si la partie n'avait pas commencé. Les salons de ces rencontres
  sont fermés : l'adversaire présent reçoit `room:updated` avec
  `status: "finished"`. Le tournoi se termine quand toutes les rencontres
  ont un résultat, comme d'habitude.

## Classement et parties (REST)

| Méthode | Route | Réponse |
|---|---|---|
| GET | `/api/leaderboard?limit=50&offset=0` | `200 [{rank, user}]`, trié par `rating` décroissant |
| GET | `/api/users/:id/games?limit=20` | `200 [gameSummary]` |
| GET | `/api/games/:id` | `200 {summary, game}`, où `game` est le JSON `Game` du moteur (pour revoir la partie) |

`gameSummary` = `{id, roomCode, white: user, black: user, status, result, rated, startedAt, finishedAt, plyCount}`.

- `status` vaut `"playing"`, `"finished"` ou `"aborted"`.
- `result` est un `GameResult` du moteur ou `null`.

### Classement Elo

- Tout nouveau compte démarre à **1200**.
- Seules les parties `rated` comptent, c'est-à-dire les salons créés avec
  `rated: true` entre deux comptes non invités.
- La mise à jour se fait à la fin de la partie, avec **K = 32** :
  `score` vaut 1 pour une victoire, 0,5 pour une nulle et 0 pour une
  défaite, et `attendu = 1 / (1 + 10^((Rb - Ra)/400))`.
- `wins`, `losses` et `draws` sont mis à jour pour **toute** partie en ligne
  terminée, classée ou non.

## Tournois (REST) — architecture extensible

| Méthode | Route | Corps | Réponse |
|---|---|---|---|
| POST | `/api/tournaments` | `{name, format, maxPlayers}` | `201 tournament` |
| GET | `/api/tournaments` | — | `200 [tournament]` |
| GET | `/api/tournaments/:id` | — | `200 tournament` (joueurs, rondes, classement) |
| POST | `/api/tournaments/:id/join` | — | `200 tournament` |
| POST | `/api/tournaments/:id/start` | — | `200 tournament` (créateur seulement) |

- `format` vaut `"roundRobin"` (seul format implémenté) ou
  `"singleElimination"` (réservé, qui renvoie 400 pour l'instant).
- Au démarrage, le serveur génère les rondes par la méthode du cercle. Pour
  chaque rencontre, il crée un **salon privé classé**, dont le code figure
  dans `tournament.rounds[].matches[].roomCode`.
- Le résultat d'une partie de tournoi met à jour `matches[].result` et le
  classement : 1 point pour une victoire, 0,5 pour une nulle.

`tournament` = `{id, name, format, status, maxPlayers, createdBy: user, players: [{user, score}], rounds: [{number, matches: [{id, white: user, black: user, roomCode, gameId, result}]}], createdAt}`.

`status` vaut `"registering"`, `"running"` ou `"finished"`.

## Temps réel (WebSocket)

Connexion : `ws://<hôte>:<port>/ws?token=<JWT>`, en WebSocket brut (pas de
Socket.IO). Un jeton absent ou invalide, ou celui d'un compte supprimé,
provoque la fermeture avec le code `4401`. Les connexions ouvertes d'un
compte sont fermées avec ce code quand il est supprimé.

Chaque message, dans un sens comme dans l'autre, est un objet JSON
`{"event": "<nom>", "data": {...}}`.

### Événements client → serveur

| Événement | `data` | Effet |
|---|---|---|
| `room:create` | `{color?: "white"\|"black"\|"random", rated?: bool, timeControl?: {initialSeconds, incrementSeconds}}` | Crée un salon privé. Réponse `room:updated`. |
| `room:join` | `{code}` | Rejoint un salon en attente. Réponse `room:updated` à tous les membres. |
| `room:leave` | `{code}` | Quitte le salon. Pendant une partie, cela équivaut à un abandon. |
| `room:ready` | `{code, ready}` | Quand les deux joueurs sont prêts, la partie démarre (`game:started`). |
| `room:rejoin` | `{code}` | Reconnexion. Réponse `game:sync`, ou `room:updated` si aucune partie n'est en cours. |
| `game:move` | `{code, ply, move}` | `ply` est le nombre de coups déjà joués attendu par le client, et `move` un `Move` JSON. |
| `game:resign` | `{code}` | Abandon. |
| `game:sync` | `{code}` | Demande l'état complet. Réponse `game:sync`. |
| `ping` | `{}` | Réponse `pong`. |

### Événements serveur → client

| Événement | `data` |
|---|---|
| `room:updated` | `{room}` |
| `game:started` | `{room, gameId, game}`, où `game` est le JSON `Game` initial |
| `game:moved` | `{code, gameId, ply, move, clocks?}`. `ply` est le nombre de coups **après** ce coup. Chaque client applique `move` avec son propre moteur ; en cas d'écart, il envoie `game:sync`. |
| `game:sync` | `{room, gameId, game, clocks?}`, avec le JSON `Game` complet |
| `game:over` | `{code, gameId, result, ratingChanges?: {<userId>: delta}}` |
| `player:disconnected` | `{code, userId, graceSeconds}` |
| `player:reconnected` | `{code, userId}` |
| `pong` | `{}` |
| `error` | `{code, message, event}` |

- `room` = `{code, status, hostId, rated, timeControl, players: [{user, color, ready, connected}], gameId}`.
- `room.status` vaut `"waiting"`, `"playing"` ou `"finished"`.
- `clocks` = `{white: ms, black: ms}`, présent seulement avec une
  `timeControl`.

### Codes d'erreur (`error.data.code`)

`UNAUTHENTICATED`, `ROOM_NOT_FOUND`, `ROOM_FULL`, `NOT_IN_ROOM`,
`GAME_NOT_STARTED`, `GAME_OVER`, `NOT_YOUR_TURN`, `STALE_PLY`,
`ILLEGAL_MOVE`, `INVALID_MESSAGE`.

### Codes de salon

Un code compte 6 caractères pris dans `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`,
sans `I`, `O`, `0` ni `1` pour éviter les confusions. Exemple : `ABC123`
n'est pas possible, mais `ABC234` l'est. Le code est unique parmi les
salons actifs.

### Validation d'un coup (`game:move`)

Le serveur refuse le coup avec le code d'erreur correspondant si l'une de
ces conditions n'est pas remplie :

1. l'utilisateur est authentifié et membre du salon ;
2. une partie est en cours et n'est pas terminée (sinon `GAME_OVER`) ;
3. la couleur de l'utilisateur est celle du trait (sinon `NOT_YOUR_TURN`) ;
4. `ply` est égal au nombre de coups joués (sinon `STALE_PLY`, et le client
   doit se resynchroniser) ;
5. le coup fait partie des coups légaux calculés par le moteur, ce qui
   couvre les prises obligatoires et la rafle maximale (sinon
   `ILLEGAL_MOVE`).

Une fois le coup accepté, le serveur l'applique avec le moteur, l'horodate,
le sauvegarde et diffuse `game:moved`. Si la partie se termine, il diffuse
aussi `game:over` et met à jour le classement.

### Reconnexion

1. **Déconnexion d'un joueur pendant une partie** : le délai de retour
   (60 s) commence. Après un court délai d'annonce (5 s), le serveur marque
   le joueur `connected: false` et diffuse `player:disconnected`.
   `graceSeconds` est alors le temps qui lui reste, 55 s par défaut.
2. **Retour dans le délai** : le joueur se reconnecte avec le même compte
   et envoie `room:rejoin`. Il reçoit `game:sync` et l'adversaire reçoit
   `player:reconnected`. Revenu avant l'annonce, il n'a jamais été
   déconnecté pour l'adversaire : rien n'est diffusé. C'est le cas des
   reconnexions imposées par l'hébergeur (Vercel ferme chaque WebSocket au
   bout de quelques minutes).
3. **Délai expiré** : la partie se termine par **abandon** du joueur
   absent (`GameEndReason.resignation`).

La pendule continue de tourner pendant la déconnexion.

Le client doit se reconnecter de lui-même et renvoyer `room:rejoin`. Quand
le délai de l'adversaire ou sa pendule arrive à zéro, il envoie `game:sync` :
le serveur applique alors l'abandon ou le temps écoulé, s'il ne l'a pas déjà
fait, et répond avec la partie. Le serveur peut aussi envoyer `game:sync` ou
`room:updated` sans demande, pour rattraper des événements perdus.

### Pendule (optionnelle)

Sans `timeControl`, il n'y a pas de limite de temps : le Dhamet n'en a pas
traditionnellement. Avec une `timeControl`, le temps du joueur au trait
décroît. Quand il atteint zéro, la partie se termine par
`GameEndReason.timeout` (`Game.loseOnTime`). Il s'agit d'une règle
**propre à l'application**.

## Modèle de données (PostgreSQL)

| Entité | Contenu |
|---|---|
| `User` | id, username, passwordHash (vide pour un invité), isGuest, avatar, rating, wins, losses, draws, createdAt, deletedAt (compte supprimé et anonymisé, sinon `null`) |
| `Game` | id, roomCode, rated, status, gameJson (JSON `Game` du moteur), resultJson, timeControl, tournamentMatchId, startedAt, finishedAt |
| `GamePlayer` | gameId, userId, color, ratingBefore, ratingAfter |
| `Move` | id, gameId, ply, userId, moveJson, playedAt |
| `Room` | code, hostId, status, rated, timeControl, createdAt, et pour un salon ouvert : players, gameId, clock, échéances (forfait, fermeture). Les salons ouverts (`closedAt` nul) sont l'état partagé par toutes les instances du serveur ; les salons fermés servent d'historique. |
| `Ranking` | historique Elo : userId, gameId, ratingBefore, ratingAfter, createdAt |
| `Tournament` | id, name, format, status, maxPlayers, createdById, createdAt |
| `TournamentPlayer` | tournamentId, userId, score |
| `TournamentMatch` | id, tournamentId, round, whiteId, blackId, roomCode, gameId, resultJson |
