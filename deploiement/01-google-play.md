# 1. Publier l'application sur Google Play

Ce guide mène du code source à l'application publiée. Les textes et les
visuels de la fiche sont dans [google-play/](google-play/) ; le serveur du
jeu en ligne a son propre guide : [02-serveur-vercel.md](02-serveur-vercel.md).

## Identité de l'application

| | |
|---|---|
| Nom | **Dhametna** (ظامتنا), « notre Dhamet ». Le jeu reste le Dhamet (ظامت) ; le nom est le même dans toutes les langues (`lib/app/brand.dart`) |
| Identifiant | `mr.dhametna.app`, **définitif** dès le premier envoi sur la Play Console |
| Version | `version:` de `pubspec.yaml`, `1.0.0+1` : nom de version `1.0.0`, code de version `1` |
| Android | minSdk 24 (Android 7.0), targetSdk 36 (Android 16), le niveau exigé par Google Play pour les nouvelles applications et les mises à jour depuis le 31 août 2026 |
| Signature | Play App Signing : Google signe l'application, vous signez les envois avec votre clé d'import |
| Logo | Dessiné par `tool/brand/generate_brand_assets.py`, qui écrit aussi toutes les icônes |

### Le logo

Un carré de sable où l'on a tracé au doigt une cellule du plateau : le
carré, la croix et les deux diagonales. Comme sur le vrai plateau, les
milieux des côtés sont des points « étroits », sans diagonale. Au centre se
dresse une ظايمة : deux bâtonnets croisés, liés par une cordelette indigo,
comme le dessine le jeu (voir [docs/design.md](../docs/design.md)). Une
بعرة attend dans un coin.

Le script produit, à partir d'un seul dessin :

- l'icône adaptative Android (fond, premier plan, et la version
  monochrome qu'Android 13+ teinte selon le thème) ;
- les icônes carrée et ronde d'Android 7, et le logo de l'écran de
  lancement ;
- les icônes iOS ;
- `assets/images/logo.png`, affiché dans l'application ;
- l'icône 512 × 512 et l'image de présentation 1024 × 500 de Google Play,
  dans [google-play/](google-play/).

```bash
python3 tool/brand/generate_brand_assets.py   # numpy, Pillow avec libraqm
```

## 1. La clé d'import (une seule fois)

```bash
tool/release/create_upload_key.sh
```

Le script crée `~/keystores/dhametna-upload.jks`, hors du dépôt, avec un mot
de passe aléatoire, et `android/key.properties`, qui l'indique au build.
Aucun des deux fichiers n'est versionné (`android/.gitignore`).

**Sauvegardez ces deux fichiers** (gestionnaire de mots de passe, disque
chiffré). En cas de perte, il faut demander une nouvelle clé d'import à
Google (Play Console → Test et publication → Configuration → Intégrité de
l'application), ce qui bloque les mises à jour quelques jours.

Sans `android/key.properties`, une version release est signée avec la clé
de débogage : elle s'installe avec `flutter run --release`, mais Google Play
la refuse.

## 2. Le serveur du jeu en ligne

Le jeu en ligne n'existe que si la version est compilée avec l'adresse de
son serveur :

- **sans serveur**, l'accueil n'affiche pas « Jouer en ligne ». Rien ne
  quitte le téléphone, et la déclaration de sécurité des données est
  « aucune donnée collectée » ;
- **avec serveur**, l'application a des comptes : il faut la politique de
  confidentialité, l'URL de suppression de compte et la déclaration
  détaillée de [google-play/data-safety.md](google-play/data-safety.md).

Le serveur se déploie sur Vercel : suivez
[02-serveur-vercel.md](02-serveur-vercel.md). Il vous donne l'adresse du
serveur, par exemple `https://dhametna.vercel.app`, et publie la politique
de confidentialité à `https://dhametna.vercel.app/confidentialite`.
L'application exige HTTPS en release.

L'application n'a aucun réglage de serveur : pour en essayer un autre,
construisez une version avec une autre adresse `DHAMET_SERVER`.

## 3. Construire le bundle

```bash
DHAMET_SERVER=https://dhametna.vercel.app tool/release/build_release.sh
# ou, sans jeu en ligne :
tool/release/build_release.sh
```

Le script refuse de construire sans `android/key.properties` ou avec une
adresse en HTTP. Il produit :

- `build/app/outputs/bundle/release/app-release.aab`, le fichier à envoyer.
  Il fait environ 55 Mo, car il contient les trois architectures et les
  tables de symboles natifs. Google Play n'installe que la partie utile à
  chaque téléphone ;
- `build/symbols/<version>/`, les symboles du code Dart, qui est obfusqué.
  **Gardez-les pour chaque version publiée** : ils servent à lire les traces
  de plantage (`flutter symbolize`).

L'avertissement « The generated ELF library contains unobfuscated DWARF
debugging information » concerne ces fichiers de symboles. La bibliothèque
livrée dans le bundle est bien dépouillée.

Avant d'envoyer, vérifiez :

```bash
flutter analyze && flutter test
(cd packages/dhamet_engine && dart test) && (cd packages/dhamet_ai && dart test)
(cd server && npm test && npm run test:e2e)
```

## 4. Première publication

1. **Compte développeur** : [play.google.com/console](https://play.google.com/console),
   frais d'inscription uniques (25 $) et vérification d'identité. Un compte
   **personnel** créé après le 13 novembre 2023 doit d'abord faire un
   **test fermé avec au moins 12 testeurs inscrits pendant 14 jours d'affilée**
   avant de pouvoir demander l'accès à la production. Prévoyez la liste des
   testeurs (adresses Gmail) à l'avance.
2. **Créer l'application** : nom « Dhametna », langue par défaut français
   (fr-FR), type **Jeu**, **gratuit**. Une application gratuite ne peut plus
   devenir payante.
3. **Fiche Play Store** (Croissance → Présence sur le Play Store → Fiche
   principale) : textes de [google-play/listing.md](google-play/listing.md),
   puis les visuels de [google-play/](google-play/) :

   | Champ de la Play Console | Fichier |
   |---|---|
   | Icône de l'application | `icon_512.png` |
   | Image de présentation | `feature_graphic_1024x500.png` |
   | Captures d'écran du téléphone (français) | `screenshots/fr/*.jpg` |
   | Captures, traduction arabe (ar) | `screenshots/ar/*.jpg` |
   | Captures, traduction anglaise (en-US) | `screenshots/en/*.jpg` |

   Ajoutez les traductions arabe (ar) et anglaise (en-US) de la fiche.
4. **Contenu de l'application** : suivez
   [google-play/data-safety.md](google-play/data-safety.md) (politique de
   confidentialité, accès à l'application, annonces, classification du
   contenu, public cible, sécurité des données, suppression de compte).
5. **Politique de confidentialité** : déclarez
   `https://dhametna.vercel.app/confidentialite`. Vérifiez d'abord que
   votre adresse de contact y figure (variable `CONTACT_EMAIL` du serveur).
   Pour la version en ligne, déclarez aussi l'adresse de suppression de
   compte : `https://dhametna.vercel.app/confidentialite#suppression`.
6. **Test fermé** : Test et publication → Tests → Test fermé. Envoyez
   `app-release.aab` et ajoutez les testeurs. Activez Play App Signing
   (proposé au premier envoi).
7. **Production** : après les 14 jours, demandez l'accès à la production,
   puis créez une version de production avec le même bundle, ou un bundle
   plus récent. L'examen par Google prend de quelques heures à quelques
   jours.

## 5. Les mises à jour

1. Augmentez la version dans `pubspec.yaml` : `1.0.1+2`, puis `1.1.0+3`…
   Le nombre après `+` (code de version) doit augmenter à chaque envoi.
2. Si l'interface a changé, régénérez les captures :

   ```bash
   DHAMET_SERVER=https://dhametna.vercel.app tool/store/screenshots.sh
   ```

   Elles arrivent dans [google-play/screenshots/](google-play/screenshots/).
   Sans `DHAMET_SERVER`, les captures montrent une version sans jeu en
   ligne. Le script demande Python (fontTools, Pillow) et la police Noto
   Sans Arabic (paquet `fonts-noto-core`).
3. Reconstruisez avec `tool/release/build_release.sh`, en gardant le même
   `DHAMET_SERVER`, et conservez `build/symbols/<version>/`.
4. Envoyez le bundle dans une nouvelle version, avec des notes de version
   dans les trois langues.

Chaque année, Google relève le niveau d'API exigé (`targetSdk`) : en
août 2027, il faudra probablement viser Android 17 (API 37).

## Ce qui a été vérifié

Sur un émulateur Android 16 (API 36), avec la version release obfusquée,
le 1<sup>er</sup> octobre 2026 :

- installation ;
- icône adaptative et écran de lancement ;
- accueil, sans « Jouer en ligne » faute de serveur ;
- partie contre l'IA sauvegardée, puis reprise après redémarrage de
  l'émulateur.

Le bundle est signé avec la clé d'import (`CN=Dhametna`).

Le serveur prévu pour Vercel a été vérifié le 8 octobre 2026 avec deux
conteneurs de son image de production sur une même base PostgreSQL. Un
joueur était connecté à chacun, pour une partie complète :

- coups transmis d'une instance à l'autre ;
- reconnexion rapide invisible pour l'adversaire ;
- abandon après le délai de grâce.

À vérifier sur un vrai téléphone pendant le test fermé :

- le geste retour (Android 16 active le « retour prédictif ») ;
- les vibrations ;
- le jeu en ligne contre le serveur de production sur Vercel, en laissant
  une partie durer plus de 5 minutes (reconnexion forcée par Vercel).
