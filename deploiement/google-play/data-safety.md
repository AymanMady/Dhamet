# Play Console — Contenu de l'application

Réponses aux questionnaires de la Play Console (Règles et programmes →
Contenu de l'application), établies d'après le code de la version 1.0.0.
À revoir si l'application change (nouvelle bibliothèque, statistiques
réellement envoyées, publicité…).

Deux cas, selon la compilation :

- **sans serveur** (`DHAMET_SERVER` absent) : rien ne quitte l'appareil ;
- **avec serveur** : le jeu en ligne envoie au serveur Dhametna un compte,
  les parties en ligne, le classement et les tournois.

## Sécurité des données (Data safety)

### Version sans serveur

| Question | Réponse |
|---|---|
| Votre application collecte-t-elle ou partage-t-elle des types de données utilisateur obligatoires ? | **Non** |

La Play Console affiche alors « Aucune donnée collectée ». Les parties, les
réglages et l'historique restent dans le stockage privé de l'application.

### Version avec serveur

| Question | Réponse |
|---|---|
| Collecte ou partage de données utilisateur ? | **Oui** |
| Toutes les données sont-elles chiffrées en transit ? | **Oui** (HTTPS et WSS : Android refuse le HTTP en clair aux versions release) |
| Les utilisateurs peuvent-ils demander la suppression de leurs données ? | **Oui** : dans l'application (Jouer en ligne → Supprimer mon compte) et par e-mail (URL de suppression ci-dessous) |
| Partage avec des tiers | **Aucun** |

Types de données à cocher :

| Catégorie → type | Quoi | Collectée | Partagée | Facultative ? | Finalités |
|---|---|---|---|---|---|
| Informations personnelles → **ID utilisateur** | Nom de joueur et identifiant du compte (un compte invité reçoit un nom `invite_…`) | Oui | Non | **Oui, facultative** (seul le jeu en ligne en a besoin) | Fonctionnement de l'application, Gestion du compte |
| Activité dans l'application → **Autres actions** | Parties en ligne (coups, résultats), classement Elo, tournois | Oui | Non | Oui, facultative | Fonctionnement de l'application |

À ne **pas** cocher, et pourquoi :

- **Mot de passe** : la Play Console n'a pas de type « mot de passe » ; il
  sert à l'authentification et n'est conservé que haché (scrypt).
- **Adresse IP** : utilisée de façon éphémère par le serveur pour la
  connexion et pour limiter les abus (anti-spam des connexions), sans être
  enregistrée par l'application, ni servir à déduire une position.
- **Statistiques d'usage** : l'option existe dans les paramètres, mais en
  1.0.0 les événements restent en mémoire sur l'appareil
  (`InMemoryAnalyticsSink`). Si un jour ils sont envoyés, il faudra
  déclarer « Activité dans l'application → Interactions avec l'application »,
  finalité Analyse.
- **Plantages / diagnostics** : aucun outil de rapport de plantage n'est
  intégré (les statistiques Android vitals de Google Play ne sont pas à
  déclarer).
- **Identifiants de l'appareil, publicité, position, contacts, photos** :
  jamais accédés. La seule autorisation est `INTERNET`.

### URL de suppression de compte

Obligatoire dès que l'application permet de créer un compte (version avec
serveur) : l'adresse de la section « Supprimer votre compte » de la
politique de confidentialité, par exemple
`https://<votre-hébergement>/privacy-policy.html#suppression`.

## Politique de confidentialité

URL publique de `store/google_play/privacy-policy.html`, à héberger avant
de remplir la fiche (GitHub Pages, Google Sites, Netlify…). Remplacez
d'abord l'adresse e-mail de contact (`contact@example.org`) dans le fichier.

## Accès à l'application

« Toutes les fonctionnalités sont disponibles sans accès spécial. » Le jeu
en ligne se teste sans identifiants : bouton « Jouer en invité ».

## Annonces

« Non, mon application ne contient pas d'annonces. »

## Classification du contenu (questionnaire IARC)

- Catégorie : **Jeu** (« Jeux de société, de cartes, de casse-tête… » si la
  liste le propose).
- Violence, peur, sexualité, grossièretés, substances, discrimination :
  **Non** partout.
- Jeux d'argent : **Non** (aucune mise, aucun jeu de hasard simulé ; le
  tirage du camp « au hasard » n'est pas un jeu d'argent).
- Interactions entre utilisateurs :
  - sans serveur : **Non** ;
  - avec serveur : **Oui**. Les joueurs voient le nom de leur adversaire et
    jouent ensemble, mais il n'y a ni messagerie, ni partage de contenu, ni
    partage de position.
- Achats numériques : **Non**.
- Résultat attendu : PEGI 3, ESRB Everyone, USK 0 (avec la mention
  « Interactions entre utilisateurs » pour la version en ligne).

## Public cible et contenu

- Tranches d'âge recommandées : **13 ans et plus** (13-15, 16-17, 18+).
  Le jeu convient à tous, mais viser les moins de 13 ans soumet
  l'application au programme Familles (exigences supplémentaires sur les
  comptes en ligne et les bibliothèques). À reconsidérer plus tard si vous
  voulez cibler les enfants.
- « L'application pourrait-elle attirer involontairement les enfants ? » :
  **Non** (jeu de réflexion traditionnel, sans personnages ni publicité).

## Autres déclarations

| Déclaration | Réponse |
|---|---|
| Application d'actualités | Non |
| Application gouvernementale | Non |
| Fonctionnalités financières | Aucune |
| Santé | Non |
| Applications de traçage des contacts COVID-19 | Non |
| Autorisations sensibles (localisation, SMS, accessibilité…) | Aucune |
