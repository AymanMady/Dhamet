# Déploiement de Dhametna

Tout ce qu'il faut pour publier Dhametna : l'application sur **Google
Play**, et son serveur de jeu en ligne sur **Vercel**.

| Guide | Pour |
|---|---|
| [01-google-play.md](01-google-play.md) | Signer, construire et publier l'application, puis ses mises à jour |
| [02-serveur-vercel.md](02-serveur-vercel.md) | Mettre en ligne le serveur (comptes, salles, classement, tournois) et la politique de confidentialité |

## Contenu du dossier

| Fichier | Utilisation |
|---|---|
| [google-play/listing.md](google-play/listing.md) | Textes de la fiche Play Store, en français, arabe et anglais : titre, descriptions courte et complète, notes de version |
| [google-play/data-safety.md](google-play/data-safety.md) | Réponses aux questionnaires « Contenu de l'application » : sécurité des données, classification, public cible… |
| [google-play/icon_512.png](google-play/icon_512.png) | Icône de la fiche (logo), 512 × 512 |
| [google-play/feature_graphic_1024x500.png](google-play/feature_graphic_1024x500.png) | Image de présentation, 1024 × 500 |
| [google-play/screenshots/](google-play/screenshots/) | Captures du téléphone, 1080 × 1920 : `fr/`, `ar/`, `en/`, 4 par langue |

Ailleurs dans le dépôt :

| Fichier | Utilisation |
|---|---|
| [`assets/images/logo.png`](../assets/images/logo.png) | Le logo en grand, tel qu'affiché dans l'application |
| [`server/src/legal/privacy-policy.html`](../server/src/legal/privacy-policy.html) | Politique de confidentialité (fr, ar, en), publiée par le serveur à `/confidentialite` |
| [`tool/release/`](../tool/release/) | Création de la clé d'import et construction du bundle |
| [`tool/store/screenshots.sh`](../tool/store/screenshots.sh) | Régénère les captures depuis l'application |
| [`tool/brand/generate_brand_assets.py`](../tool/brand/generate_brand_assets.py) | Redessine le logo, les icônes et l'image de présentation |
| [`Dockerfile.vercel`](../Dockerfile.vercel), [`vercel.json`](../vercel.json) | Déploiement du serveur sur Vercel |

## Comptes et outils

| | Coût | Sert à |
|---|---|---|
| Compte développeur Google Play | 25 $, une fois | Publier |
| 12 testeurs avec une adresse Gmail | — | Test fermé de 14 jours, obligatoire pour un compte personnel récent |
| Compte GitHub (ou GitLab, Bitbucket) | Gratuit | Héberger le dépôt, que Vercel déploie |
| Compte Vercel, offre Hobby | Gratuit (usage non commercial) | Serveur de jeu en ligne |
| Base Neon, depuis Vercel | Gratuit | Données du jeu en ligne |
| Flutter, JDK 17, Android SDK | — | Construire l'application |
| Python 3 avec Pillow et fontTools, police Noto Sans Arabic | — | Seulement pour régénérer les captures |

## Liste de contrôle

Dans l'ordre. Sans jeu en ligne, sautez la partie « Serveur », mais publiez
quand même la politique de confidentialité (voir la fin de
[02-serveur-vercel.md](02-serveur-vercel.md)).

**Serveur** ([02-serveur-vercel.md](02-serveur-vercel.md))

- [ ] Dépôt poussé sur GitHub
- [ ] Projet Vercel créé depuis le dépôt (racine `./`), nom choisi : `https://<projet>.vercel.app`
- [ ] Base Neon (Frankfurt) connectée au projet
- [ ] Variables `JWT_SECRET`, `CRON_SECRET`, `CONTACT_EMAIL` et `TRUST_PROXY=1` en Production
- [ ] Fluid compute activé, projet redéployé
- [ ] `/api/health` répond `{"status":"ok"}` et `/confidentialite` montre votre adresse
- [ ] Partie en ligne testée entre deux téléphones

**Application** ([01-google-play.md](01-google-play.md))

- [ ] Clé d'import créée **et sauvegardée** (`~/keystores/dhametna-upload.jks`, `android/key.properties`)
- [ ] Tests au vert : `flutter test`, moteur, IA, serveur
- [ ] Bundle construit : `DHAMET_SERVER=https://<projet>.vercel.app tool/release/build_release.sh`
- [ ] Symboles `build/symbols/<version>/` conservés

**Play Console** ([01-google-play.md](01-google-play.md), § 4)

- [ ] Application créée : Dhametna, jeu, gratuit, français par défaut
- [ ] Fiche : textes de `listing.md` (fr, ar, en), icône, image de présentation, captures
- [ ] Contenu de l'application : réponses de `data-safety.md`
- [ ] Politique de confidentialité : `https://<projet>.vercel.app/confidentialite`
- [ ] Suppression de compte : `https://<projet>.vercel.app/confidentialite#suppression`
- [ ] Test fermé : bundle envoyé, Play App Signing activé, 12 testeurs pendant 14 jours
- [ ] Accès à la production demandé, version de production publiée

## À garder précieusement

| Quoi | Pourquoi |
|---|---|
| `~/keystores/dhametna-upload.jks` et `android/key.properties` | Sans eux, plus de mise à jour possible pendant plusieurs jours |
| `JWT_SECRET` du serveur | Le changer déconnecte tout le monde et fait perdre les comptes invités |
| `build/symbols/<version>/` de chaque version | Lire les traces de plantage |
| L'adresse `https://<projet>.vercel.app` | Inscrite dans l'application publiée : ne supprimez ni ne renommez le projet |
