# 2. Le serveur de jeu en ligne sur Vercel

Le jeu en ligne de Dhametna (comptes, salles privées, classement Elo,
tournois) passe par le serveur `server/`. Ce guide le met en ligne sur
**Vercel**, avec sa base **PostgreSQL chez Neon**. Les deux ont une offre
gratuite. À la fin, vous avez :

- l'adresse du serveur, par exemple `https://dhametna.vercel.app`, à mettre
  dans l'application (`DHAMET_SERVER`) ;
- la politique de confidentialité en ligne, à
  `https://dhametna.vercel.app/confidentialite`, à déclarer dans la Play
  Console.

Sans jeu en ligne, ce guide est facultatif. Il faut quand même publier la
politique de confidentialité quelque part (voir la fin de ce guide).

## Ce qu'il faut

| | |
|---|---|
| Compte GitHub (ou GitLab, Bitbucket) | Le dépôt du projet y est poussé ; Vercel le déploie à chaque commit |
| Compte [Vercel](https://vercel.com/signup) | Offre **Hobby** gratuite, réservée à un usage **non commercial** (voir « Limites et coûts ») |
| Base Neon | Créée depuis Vercel (Marketplace), offre gratuite |
| Adresse e-mail de contact | Affichée dans la politique de confidentialité |
| Terminal avec `openssl` et `curl` | Pour générer les secrets et vérifier le serveur |

Rien à installer pour le déploiement : Vercel construit l'image Docker
lui-même, moteur Dart compris.

## Fichiers du dépôt qui servent au déploiement

| Fichier | Rôle |
|---|---|
| [`Dockerfile.vercel`](../Dockerfile.vercel) | Image du serveur : compile le moteur Dart en JavaScript, puis le serveur NestJS |
| [`vercel.json`](../vercel.json) | Un seul service, `dhamet-server` (l'image ci-dessus), qui reçoit tout le trafic du projet, WebSockets compris ; région `fra1` (Francfort), nettoyage quotidien (`/api/cron/sweep`), et pas de nouveau déploiement quand seule l'application Flutter change |
| [`.vercelignore`](../.vercelignore), [`Dockerfile.vercel.dockerignore`](../Dockerfile.vercel.dockerignore) | N'envoient à Vercel que `server/` et le moteur, pas l'application ni ses images |
| [`server/src/database/migrations/`](../server/src/database/migrations/) | Schéma de la base, appliqué au démarrage du serveur |
| [`server/src/legal/privacy-policy.html`](../server/src/legal/privacy-policy.html) | Politique de confidentialité, publiée par le serveur |

## Étape 1 — Pousser le dépôt

Le projet doit être sur GitHub (ou GitLab, Bitbucket), dans un dépôt privé
ou public. Vercel déploie la branche de production, en général `main`.

## Étape 2 — Créer le projet Vercel

1. Vercel → **Add New… → Project** → importez le dépôt.
2. Réglages de l'import :
   - **Root Directory** : laissez la racine du dépôt (`./`). Le Dockerfile
     a besoin de `server/` et de `packages/dhamet_engine/` ;
   - **Framework Preset** : `Services`, choisi d'après `vercel.json` ;
   - ne touchez pas aux commandes de build : Vercel construit
     `Dockerfile.vercel`, l'image du service `dhamet-server`.
3. **Deploy**. Ce premier déploiement échoue ou démarre sans base de
   données : c'est normal, les étapes 3 et 4 le complètent.

Le nom du projet donne l'adresse : un projet `dhametna` répond à
`https://dhametna.vercel.app`. Choisissez-le bien : **l'application
publiée contient cette adresse**. La changer plus tard demande une mise à
jour de l'application.

## Étape 3 — Créer la base PostgreSQL (Neon)

1. Dans le projet : **Storage → Create Database → Neon** (Serverless
   Postgres).
2. Région : **Frankfurt (aws-eu-central-1)**, la plus proche de la région
   `fra1` du serveur.
3. Offre : **Free**.
4. **Connect** au projet, pour tous les environnements (Production,
   Preview, Development).

Vercel ajoute alors les variables de la base, notamment `DATABASE_URL`
(connexion « poolée », pour les requêtes) et `DATABASE_URL_UNPOOLED`
(connexion directe, pour l'écoute temps réel et les migrations). Le serveur
lit les deux : ne les renommez pas.

## Étape 4 — Variables d'environnement

Projet → **Settings → Environment Variables**, environnement
**Production** (et Preview si vous testez des branches) :

| Variable | Valeur | |
|---|---|---|
| `JWT_SECRET` | `openssl rand -base64 48` | **Obligatoire.** Signe les sessions. Ne le changez jamais : tout le monde serait déconnecté et les comptes invités, dont le jeton est la seule clé, seraient perdus |
| `CRON_SECRET` | `openssl rand -hex 32` | Protège le nettoyage quotidien ; Vercel l'envoie de lui-même à `/api/cron/sweep` |
| `CONTACT_EMAIL` | votre adresse | Remplace `contact@example.org` dans la politique de confidentialité |
| `TRUST_PROXY` | `1` | L'adresse IP du joueur vient de l'en-tête de Vercel (limite anti-abus des connexions) |

Facultatives, avec leur valeur par défaut :

| Variable | Défaut | |
|---|---|---|
| `RECONNECT_GRACE_SECONDS` | `60` | Temps laissé à un joueur déconnecté pour revenir, avant de perdre par abandon |
| `DISCONNECT_NOTICE_SECONDS` | `5` | Délai avant de prévenir l'adversaire d'une déconnexion (voir « Comment ça marche ») |
| `DB_POOL_SIZE` | `10` | Connexions à la base par instance ; `5` suffit sur l'offre gratuite |
| `CORS_ORIGINS` | `*` | Origines web autorisées ; l'application mobile n'en a pas besoin |

Ne définissez pas `PORT` : l'image écoute sur le port 80, celui de Vercel.

## Étape 5 — Vérifier Fluid compute

Les WebSockets demandent **Fluid compute**, activé par défaut sur les
projets récents : **Settings → Functions → Fluid Compute** doit être
activé.

## Étape 6 — Redéployer

**Deployments** → dernier déploiement → **⋯ → Redeploy**. Le build dure
quelques minutes : compilation du moteur Dart, puis du serveur. Au
démarrage, le serveur applique les migrations à la base vide.

## Étape 7 — Vérifier

Remplacez `dhametna` par le nom de votre projet.

```bash
# Le serveur répond.
curl https://dhametna.vercel.app/api/health
# → {"status":"ok"}

# Un compte invité se crée.
curl -X POST https://dhametna.vercel.app/api/auth/guest \
  -H 'Content-Type: application/json' -d '{}'
# → {"token":"…","user":{…"username":"invite_…"}}

# Le nettoyage planifié refuse les inconnus…
curl -i https://dhametna.vercel.app/api/cron/sweep          # → 401
# …et accepte Vercel.
curl -H "Authorization: Bearer <CRON_SECRET>" \
  https://dhametna.vercel.app/api/cron/sweep                # → {"settled":0}
```

Ouvrez aussi `https://dhametna.vercel.app/confidentialite` dans un
navigateur. Votre adresse de contact doit y figurer.

Puis le vrai test, avec deux téléphones (ou un téléphone et un émulateur) :

```bash
flutter run --release --dart-define=DHAMET_SERVER=https://dhametna.vercel.app
```

Créez une salle sur l'un, rejoignez-la avec le code sur l'autre et jouez
quelques coups. Les journaux du serveur sont dans Vercel → **Logs**.

## Étape 8 — Construire l'application avec cette adresse

```bash
DHAMET_SERVER=https://dhametna.vercel.app tool/release/build_release.sh
```

Suite : [01-google-play.md](01-google-play.md), étape 3.

## Les mises à jour du serveur

- Un `git push` sur `main` qui touche `server/`, `packages/dhamet_engine/`
  ou les fichiers Vercel déclenche un nouveau déploiement. Les commits qui
  ne changent que l'application sont ignorés (`ignoreCommand` de
  `vercel.json`).
- Les migrations s'appliquent au démarrage, sous un verrou : si plusieurs
  instances démarrent ensemble, une seule migre.
- Les parties en cours **survivent** au déploiement : elles sont dans la
  base. Les applications se reconnectent d'elles-mêmes à la nouvelle
  version.
- En cas de problème : Deployments → version précédente → **Promote to
  Production** (retour arrière immédiat).

## Comment ça marche

Vercel n'a pas un serveur unique allumé en permanence. Il lance autant
d'**instances** que le trafic l'exige, arrête celles qui n'ont plus de
trafic depuis 5 minutes, et **ferme chaque WebSocket au bout de 5 minutes**
en offre Hobby (jusqu'à 13 minutes en Pro). Le serveur a été écrit pour
cela :

- **L'état est dans la base.** Les salles ouvertes, les joueurs, les
  pendules et les parties sont dans PostgreSQL ; aucune instance ne garde
  rien en mémoire d'indispensable. Chaque modification d'une salle se fait
  dans une transaction qui prend le verrou de cette salle
  (`pg_advisory_xact_lock`) : deux instances ne la modifient jamais en même
  temps.
- **Les instances se parlent par PostgreSQL** (`LISTEN/NOTIFY`). Quand un
  joueur connecté à l'instance A joue, l'instance B de son adversaire reçoit
  le coup et le lui envoie. Les messages ne partent qu'une fois la
  transaction validée, dans l'ordre.
- **Les délais sont des dates.** Abandon d'un joueur qui ne revient pas,
  temps écoulé à la pendule, fermeture d'une salle vide : chaque échéance
  est enregistrée. Elle est appliquée par l'instance d'un joueur encore
  connecté, au moment voulu, ou par la première requête qui touche la
  salle, ou par le nettoyage. L'application elle-même redemande l'état de
  la partie quand le délai de l'adversaire ou une pendule arrive à zéro.
- **Les reconnexions forcées passent inaperçues.** Quand Vercel ferme la
  connexion d'un joueur, l'application se reconnecte en moins d'une
  seconde. L'adversaire n'est prévenu qu'au bout de
  `DISCONNECT_NOTICE_SECONDS` (5 s) : il ne voit rien.
- **Le nettoyage quotidien** (`vercel.json`, 4 h UTC) règle ce qui a expiré
  sans personne pour le voir : salles vides, abandons de deux joueurs
  partis.

Détails : [server/README.md](../server/README.md) et le contrat
client-serveur [docs/multiplayer.md](../docs/multiplayer.md).

## Limites et coûts

- **Hobby est réservé aux projets personnels non commerciaux.** Une
  application gratuite, sans publicité ni achat, de loisir, y a sa place.
  Avec des revenus (publicité, achats intégrés, client), il faut l'offre
  **Pro** (20 $ par mois et par membre). Si un quota gratuit est dépassé,
  Vercel met le projet en pause jusqu'au mois suivant.
- **Les WebSockets sont en bêta chez Vercel**, de même que les images
  Docker (`Dockerfile.vercel`). Leur comportement peut encore évoluer.
  Suivez le [changelog de Vercel](https://vercel.com/changelog) et
  testez le jeu en ligne après chaque changement annoncé.
- **Neon gratuit** : 0,5 Go de données, largement assez pour des milliers
  de parties. La base se met en veille sans activité : la première requête
  qui suit prend environ une seconde de plus.
- **Le nettoyage quotidien** tourne une fois par jour en Hobby, à une heure
  approximative. Ce n'est qu'un filet de sécurité : les instances règlent
  les délais à temps tant qu'un joueur est connecté.
- **Limite anti-abus des connexions** (`/api/auth/*`) : elle est comptée par
  instance. Pour une limite globale, ajoutez une règle « Rate Limiting »
  sur `/api/auth/` dans **Settings → Firewall**.

## En cas de problème

| Symptôme | Cause probable |
|---|---|
| Logs : `JWT_SECRET is required when NODE_ENV=production` | Variable absente de l'environnement Production : ajoutez-la, puis redéployez |
| Logs : erreur de connexion à la base | `DATABASE_URL` ou `DATABASE_URL_UNPOOLED` absente : reconnectez Neon au projet (Storage), pour Production |
| `/api/health` répond mais le jeu en ligne ne se connecte pas | Fluid compute désactivé (étape 5), ou application construite avec une autre adresse que celle du projet |
| « Ignored Build Step » sur un déploiement | Normal si le commit ne touche pas le serveur. Pour forcer : Redeploy |
| L'adversaire est souvent « déconnecté » quelques secondes | Réseau mobile instable ; augmentez `DISCONNECT_NOTICE_SECONDS` (8 ou 10) |

## Alternatives

- **Render** : [`render.yaml`](../render.yaml) décrit le même serveur sur
  Render (instance toujours allumée, payante, sans reconnexions forcées).
  Voir [server/README.md](../server/README.md).
- **Tester l'image Vercel sur votre machine** :

  ```bash
  (cd server && docker compose up -d db)
  docker build -f Dockerfile.vercel -t dhamet-vercel .
  docker run --rm --network host -e PORT=3000 -e JWT_SECRET=dev \
    -e DATABASE_URL=postgres://dhamet:dhamet@localhost:5436/dhamet dhamet-vercel
  ```

## Sans jeu en ligne

Google Play exige quand même une politique de confidentialité en ligne.
Deux possibilités :

- déployer ce serveur quand même, juste pour la page
  `/confidentialite` (aucun joueur ne s'y connectera) ;
- ou publier le fichier
  [`server/src/legal/privacy-policy.html`](../server/src/legal/privacy-policy.html)
  ailleurs (GitHub Pages, Google Sites), après y avoir remplacé
  `contact@example.org` par votre adresse.
