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
- **Plusieurs instances.** L'état partagé (salons, pendules, parties) est
  dans PostgreSQL. Les instances se parlent par `LISTEN/NOTIFY` : le serveur
  tourne sur Vercel, qui lance et arrête des instances selon le trafic.
- Mise en ligne : Vercel ([`Dockerfile.vercel`](../Dockerfile.vercel),
  guide [`deploiement/02-serveur-vercel.md`](../deploiement/02-serveur-vercel.md)),
  ou Render ([`render.yaml`](../render.yaml)). Voir [Déploiement](#déploiement).

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
│   ├── realtime/             transactions verrouillées, messages entre instances
│   ├── rooms/                salons en base, passerelle WebSocket, échéances, pendule
│   ├── tournaments/          round robin (méthode du cercle), classement
│   ├── accounts/             suppression de compte
│   ├── legal/                politique de confidentialité (/confidentialite)
│   ├── database/             options TypeORM, DataSource CLI, migrations
│   ├── testing/              banc d'essai des tests unitaires (hors build)
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
quadratique sur la partie. La base reste la référence : `EngineService`
garde ouvertes les parties récemment jouées par l'instance (200 au plus,
les plus anciennes d'abord fermées) et, avant de s'en servir, vérifie que
la copie ouverte est bien la partie enregistrée (`ensure`). Si une autre
instance a joué depuis, ou si une transaction a échoué, la partie est
rechargée.

### Autorité du serveur

Pour `game:move`, dans l'ordre du contrat : validation du message
(`INVALID_MESSAGE`), salon (`ROOM_NOT_FOUND`), appartenance
(`NOT_IN_ROOM`), partie en cours (`GAME_NOT_STARTED` / `GAME_OVER`), trait
(`NOT_YOUR_TURN`), `ply` (`STALE_PLY`), puis légalité par le moteur
(`ILLEGAL_MOVE`). Le serveur horodate le coup, le joue avec le moteur,
enregistre la ligne `Move` et le JSON `Game`, puis diffuse **la copie du
coup produite par le moteur** (jamais celle du client). Captures, fin de
partie et résultat sont toujours recalculés par le moteur.

### Plusieurs instances

Sur Vercel, chaque connexion WebSocket est tenue par une instance, et les
deux joueurs d'une partie peuvent être sur deux instances différentes. Une
instance peut aussi s'arrêter à tout moment. D'où :

- **L'état partagé est en base.** Un salon ouvert (`rooms.closedAt` nul)
  porte ses joueurs (`players`), sa partie (`gameId`), sa pendule (`clock`)
  et ses échéances. Aucune instance ne garde rien en mémoire d'indispensable.
- **Une modification à la fois.** `TransactionRunner.run(clé, …)` ouvre une
  transaction qui prend d'abord le verrou consultatif PostgreSQL de sa clé
  (`pg_advisory_xact_lock`) : `room:<code>` pour un salon, puis `ratings`
  pour les fins de partie, puis `tournaments`, toujours dans cet ordre. Dans
  une même instance, les tâches d'une même clé attendent aussi en mémoire.
  Avec sql.js (tests), tout passe par une seule file.
- **Les messages partent au commit.** Les événements d'une transaction
  (`tx.publish`) sont envoyés par `pg_notify` dans cette transaction :
  PostgreSQL ne les livre qu'au commit, dans l'ordre des commits, et jamais
  pour une modification annulée. Chaque instance qui a des connexions écoute
  (`LISTEN`, sur une connexion directe, pas celle du pooler) et transmet à
  ses joueurs (`RealtimeBus`). Une requête attend que son instance écoute.
  Après une coupure de l'écoute, l'instance renvoie à ses joueurs l'état de
  leurs salons.
- **Les délais sont des dates.** Abandon d'un absent (`forfeitAt`), pendule
  (`clock`), fermeture (`expiresAt`), annonce d'une déconnexion (`leftAt`).
  Le prochain délai d'un salon (`deadlineAt`) est diffusé à chaque
  modification. Les instances qui tiennent une connexion d'un de ses joueurs
  programment une minuterie (`RoomDeadlines`), et le salon est réglé à ce
  moment (`RoomsService.settle`). Toute requête sur le salon règle d'abord
  ce qui est échu. Les instances avec des connexions balaient aussi les
  salons en retard toutes les 30 s, et `GET /api/cron/sweep` le fait une
  fois par jour (Vercel Cron). Régler un salon deux fois ne change rien.
- **Reconnexions forcées.** Vercel ferme chaque WebSocket au bout de 5 min
  (offre Hobby). L'application se reconnecte aussitôt et envoie
  `room:rejoin`. L'adversaire n'est prévenu qu'après
  `DISCONNECT_NOTICE_SECONDS` : un joueur revenu entre-temps n'a jamais été
  « déconnecté » pour lui.
- **Arrêt d'une instance** (`SIGTERM`, 30 s de grâce) : ses joueurs sont
  marqués partis tout de suite, et les instances de leurs adversaires
  prennent le relais.

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
- Les migrations s'appliquent au démarrage sous un verrou de session
  PostgreSQL (`runMigrationsLocked`) : si plusieurs instances démarrent
  ensemble, une seule migre. `SharedRooms1791600000000` a déplacé les
  salons ouverts dans la base ; les parties encore `playing` de l'ancien
  serveur, qui les gardait en mémoire, y sont passées en `aborted`.

## Configuration

Voir [`.env.example`](.env.example).

| Variable | Défaut | Rôle |
|---|---|---|
| `PORT` | 3000 | port HTTP et WebSocket |
| `JWT_SECRET` | secret de dev | **obligatoire** si `NODE_ENV=production` |
| `JWT_EXPIRES_IN_SECONDS` | 2 592 000 (30 j) | durée des jetons |
| `DATABASE_URL` (ou `POSTGRES_URL`), ou `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` | `localhost:5436`, `dhamet`/`dhamet`/`dhamet` | PostgreSQL ; derrière un pooler (Neon), l'URL « poolée » |
| `DATABASE_URL_UNPOOLED` (ou `POSTGRES_URL_NON_POOLING`) | `DATABASE_URL` | connexion directe, pour `LISTEN` et le verrou des migrations |
| `DB_POOL_SIZE` | 10 | connexions du pool de chaque instance |
| `DB_TYPE` | `postgres` | `sqljs` pour les tests |
| `DB_MIGRATIONS_RUN` / `DB_SYNCHRONIZE` | `true` / `false` | gestion du schéma |
| `RECONNECT_GRACE_SECONDS` | 60 | délai de reconnexion (décimales permises) |
| `DISCONNECT_NOTICE_SECONDS` | 5 | délai avant d'annoncer une déconnexion aux autres joueurs (0 à 60) |
| `CRON_SECRET` | aucun | jeton de `GET /api/cron/sweep` (sans lui, la route répond 404) |
| `CONTACT_EMAIL` | aucune | adresse affichée par `/confidentialite` à la place de `contact@example.org` |
| `CORS_ORIGINS` | `*` | origines autorisées, séparées par des virgules |
| `AUTH_THROTTLE_LIMIT` / `AUTH_THROTTLE_TTL_SECONDS` | 20 / 60 | limite de débit de `/api/auth/*`, par adresse de client |
| `TRUST_PROXY` | `false` | proxys à croire pour lire l'adresse du client (`trust proxy` d'Express) : `true`/`false`, nombre de sauts, ou adresses et sous-réseaux (`loopback, 10.0.0.0/8`) ; `1` sur Vercel, `3` sur Render |
| `DB_HOST_PORT`, `API_PORT` | 5436, 3000 | ports publiés par docker compose |

Le port PostgreSQL publié par `docker-compose.yml` est **5436** : 5432 et
5433 sont déjà pris par d'autres projets sur la machine de développement.

## Déploiement

### Vercel

Guide pas à pas : [`deploiement/02-serveur-vercel.md`](../deploiement/02-serveur-vercel.md).
En bref :

- [`Dockerfile.vercel`](../Dockerfile.vercel), à la racine du dépôt : mêmes
  étapes que `server/Dockerfile`, puis une image allégée (~175 Mo, sous la
  limite de 250 Mo des fonctions) qui écoute sur le port 80 ;
- [`vercel.json`](../vercel.json) : un seul service, `dhamet-server` (cette
  image), qui reçoit tout le trafic ; région `fra1`, nettoyage quotidien
  `GET /api/cron/sweep`, et pas de déploiement pour un commit qui ne touche
  ni le serveur ni le moteur ;
- base Neon créée depuis Vercel, qui fournit `DATABASE_URL` (poolée) et
  `DATABASE_URL_UNPOOLED` (directe) ;
- à définir : `JWT_SECRET`, `CRON_SECRET`, `CONTACT_EMAIL`,
  `TRUST_PROXY=1`.

Un déploiement n'interrompt pas les parties : elles sont dans la base, et
les applications se reconnectent à la nouvelle version.

### Render

Le Blueprint [`render.yaml`](../render.yaml), à la racine du dépôt, décrit
une autre mise en ligne :

- **`dhamet-server`** : l'image de `server/Dockerfile`, construite depuis la
  racine du dépôt (le moteur Dart est compilé pendant la construction). Une
  instance toujours allumée, région Francfort, health check
  `GET /api/health` ;
- **`dhamet-db`** : PostgreSQL 16, relié par `DATABASE_URL` (URL interne,
  sans TLS sur le réseau privé de Render), qui sert aussi à `LISTEN` ;
- `JWT_SECRET`, généré une fois par Render, et `TRUST_PROXY=3` (Cloudflare,
  répartiteur de charge, proxy interne : chacun ajoute une adresse à
  `X-Forwarded-For`).

Mise en ligne : Render → **New → Blueprint**, puis le dépôt et la branche.
Les plans du Blueprint sont payants ; un service `free` s'endort après
15 min sans trafic et une base gratuite expire au bout de 30 jours.

### Ailleurs

Même image (`docker build -f server/Dockerfile .` depuis la racine du
dépôt), autant d'instances que voulu, avec une base PostgreSQL et un
`TRUST_PROXY` adapté aux proxys de l'hébergeur. Une base externe (Neon,
Supabase…) se met dans `DATABASE_URL`, avec `?sslmode=verify-full`.

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
  classement, fin du tournoi) ; fermeture `4401` sans jeton valide ;
  `GET /api/health` ; limite de débit de `/api/auth/*` par adresse de
  client derrière trois proxys (`TRUST_PROXY=3`), adresse forgée ignorée ;
  `/confidentialite` ; `/api/cron/sweep` protégé par `CRON_SECRET`.
- **Plusieurs instances** (`test/multi-instance.e2e-spec.ts`) : deux
  serveurs sur une même base PostgreSQL, chaque joueur connecté à l'un
  d'eux. Ils démarrent ensemble sur une base vide, dont un seul applique
  les migrations. Le test couvre ensuite une partie complète, l'abandon
  d'un joueur parti et le retour d'un joueur sur l'autre instance. Il
  vérifie aussi la pendule. Il demande une base jetable, dont il efface le
  schéma :

  ```bash
  docker compose up -d db
  docker compose exec db createdb -U dhamet dhamet_e2e
  E2E_DATABASE_URL=postgres://dhamet:dhamet@localhost:5436/dhamet_e2e npm run test:e2e
  ```

  Sans `E2E_DATABASE_URL`, il est ignoré.

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
3. **`graceSeconds`** est le temps qui reste au joueur pour revenir quand
   l'annonce part : `RECONNECT_GRACE_SECONDS` (60 par défaut, comme le
   contrat) moins `DISCONNECT_NOTICE_SECONDS` (5), soit 55 s par défaut.
   L'annonce `player:disconnected` attend ce délai d'annonce ; un joueur
   revenu avant n'est jamais annoncé (ni `player:reconnected`).
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
   - Un salon terminé reste ouvert pendant le délai de grâce
     (`game:sync`, `room:rejoin`), puis son code est libéré ; la partie
     reste consultable par `GET /api/games/:id`.
9. **Diffusion.** Les événements de salon et de partie vont à toutes les
   connexions ouvertes des membres (un compte peut en avoir plusieurs).
   `game:sync`, la réponse à `room:rejoin`, `pong` et `error` ne vont qu'à
   la connexion qui a fait la demande. Un joueur qui garde une autre
   connexion ouverte sur la même instance n'est pas considéré comme
   déconnecté. Toute action d'un joueur dans un salon (`game:move`,
   `game:sync`, `game:resign`, `room:ready`, `room:rejoin`) le marque
   présent. Après une coupure de l'écoute entre instances, le serveur
   renvoie de lui-même `game:sync` ou `room:updated` aux joueurs concernés.
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
13. **Statut `aborted`** : attribué par la migration
    `SharedRooms1791600000000` aux parties restées en cours sur l'ancien
    serveur, qui les gardait en mémoire.
14. **Invités** : `invite_` suivi de 4 caractères `[a-z0-9]` (plus en cas
    de collision). Sans mot de passe, leur jeton est leur seul identifiant.
15. **`GET /api/health`** (hors contrat) répond `{"status":"ok"}` pour les
    health checks de l'hébergeur. Il n'interroge pas la base : le serveur
    n'écoute qu'après avoir joint la base et appliqué les migrations.
16. **Autres routes hors contrat** : `GET /confidentialite` et
    `GET /privacy` (politique de confidentialité, hors du préfixe `/api`) ;
    `GET /api/cron/sweep` (nettoyage planifié, `Authorization: Bearer
    <CRON_SECRET>`), qui renvoie `{"settled": n}`.

## Suppression de compte

`DELETE /api/users/me` (contrat : [`docs/multiplayer.md`](../docs/multiplayer.md),
« Suppression de compte »), module `src/accounts/`, qui dépend de `rooms`,
`tournaments` et `users`. Le compte est anonymisé et désactivé
(`User.deletedAt`, migration `AddUserDeletedAt1790812378732`), jamais
effacé : parties, coups, historique Elo et tournois y font référence.

- **Ordre** : quitter les salons (`RoomsService.leaveAll`), puis les
  tournois (`TournamentsService.withdraw`), puis anonymiser, puis fermer
  les connexions (`4401`). Les deux premières étapes peuvent être rejouées
  sans effet : si l'une échoue, le compte n'est pas encore supprimé et le
  joueur peut réessayer.
- **Partie en cours : abandon plutôt que `409`.** `room:leave` abandonne
  déjà une partie en cours, par le même chemin que le forfait après le
  délai de reconnexion (`GameplayService.resignInRoom`, sous le verrou du
  salon). Et un refus ne suffirait pas : une rencontre de tournoi n'a pas
  de date limite, un tournoi en cours pourrait donc bloquer la suppression
  indéfiniment.
- Les salons de rencontres de tournoi encore en attente sont fermés
  **avant** d'enregistrer leur forfait, hors du verrou des tournois : le
  verrou d'un salon est toujours pris avant celui des tournois
  (`gameFinished`), l'ordre inverse pourrait bloquer les deux.
- Les numéros d'inscription (`seed`) d'un tournoi non commencé sont
  renumérotés après un retrait : ils restent 1, 2, 3… (ordre d'appariement).
- WebSocket : la connexion est enregistrée dès la vérification du jeton,
  puis fermée en `4401` si la base ne connaît plus le compte. Les messages
  reçus entre-temps ne peuvent rien modifier : créer ou rejoindre un salon
  exige un compte existant, et le compte supprimé n'est plus membre d'aucun
  salon en attente ou en cours.
- `UsersService.findById` ignore les comptes supprimés (jeton, profil,
  salons) ; `findByUsername` les voit, pour que leur nom `deleted_XXXX`
  reste réservé.
- Tests : `src/users/users.service.spec.ts`, `src/rooms/rooms.service.spec.ts`
  et `test/account-deletion.e2e-spec.ts` (204, `401` et `4401` ensuite, nom
  libéré, classement, parties de l'adversaire conservées, abandon de la
  partie en cours, salons en attente, tournois à venir et en cours).

## Limites connues

- Une instance qui plante sans recevoir `SIGTERM` laisse ses joueurs
  « connectés » jusqu'à leur retour : leur adversaire n'est pas prévenu et
  peut seulement abandonner ou attendre. Vercel envoie `SIGTERM` avant
  d'arrêter une instance.
- La limite de débit de `/api/auth/*` est comptée par instance. Pour une
  limite globale sur Vercel : règle de pare-feu (Vercel Firewall).
- Sur Vercel, les WebSockets et les images Docker sont en bêta.
- Pas de proposition de nulle en ligne (`end.draw` est NEEDS_VERIFICATION
  et désactivé dans `DhametRules.standard`) ; le demi-point de nulle est
  prévu dans le classement et les tournois, mais ne peut pas survenir avec
  les règles standard.
- Pas de revanche dans un même salon : une nouvelle partie demande un
  nouveau salon.
- Élimination directe (`singleElimination`) : réservée, renvoie 400.
