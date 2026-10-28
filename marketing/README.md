# Marketing de Dhametna

Tout ce qu'il faut pour faire connaître Dhametna sur Facebook : créer la
Page, le plan, les publications prêtes à copier, la publicité et la vidéo
de démonstration en arabe.

| Guide | Pour |
|---|---|
| [01-page-facebook.md](01-page-facebook.md) | Créer et régler la Page, étape par étape |
| [02-strategie.md](02-strategie.md) | Public, messages, phases (testeurs, lancement, croissance), objectifs chiffrés |
| [03-calendrier.md](03-calendrier.md) | Les six premières semaines, publication par publication, avec les textes en arabe |
| [04-publicite.md](04-publicite.md) | Publicités Meta : booster, Ads Manager, ciblage, budget, suivi des installations |
| [05-video.md](05-video.md) | La vidéo : déroulé, formats, publication, voix off |

## Contenu du dossier

| Fichier | Utilisation |
|---|---|
| [visuels/photo-profil.png](visuels/photo-profil.png) | Photo de profil de la Page, 720 × 720 (affichée en cercle) |
| [visuels/couverture.png](visuels/couverture.png) | Photo de couverture, 1640 × 924 |
| [visuels/post-01-bientot.png](visuels/post-01-bientot.png) … [post-07-historique.png](visuels/post-07-historique.png) | Images des premières publications, 1080 × 1350 (4:5) |
| [video/dhametna-demo-9x16.mp4](video/dhametna-demo-9x16.mp4) | Vidéo verticale : Reels, Stories, statut WhatsApp, TikTok |
| [video/dhametna-demo-4x5.mp4](video/dhametna-demo-4x5.mp4) | Vidéo pour le fil Facebook et Instagram |
| [video/dhametna-demo-16x9.mp4](video/dhametna-demo-16x9.mp4) | Vidéo horizontale : YouTube, puis la fiche Google Play |
| `video/dhametna-demo-miniature-*.jpg` | Image de couverture de chaque vidéo |

Tous ces fichiers sont produits à partir de la vraie application :

```bash
tool/marketing/render.sh                              # version sans jeu en ligne
DHAMET_SERVER=https://… tool/marketing/render.sh      # version avec jeu en ligne
```

Le script filme l'application (`test/marketing/demo_video_test.dart`),
monte la vidéo (`tool/marketing/compose_video.py`) puis dessine les visuels
(`tool/marketing/facebook_visuals.py`). Il faut environ cinq minutes.
Relancez-le après un changement d'interface, comme
`tool/store/screenshots.sh` pour les captures du Play Store.

## Règles de rédaction

- **Les mots du jeu** sont ceux de l'application : العودان et لبعر pour les
  camps, عود et بعرة, ظايمة pour la pièce promue. Jamais أبيض / أسود,
  قطعة, جندي ni سلطان. En français : Laoudane, Lebaar, aoud, baara, Dhayma.
- **Ne promettre que ce qui existe** dans la version publiée. Sans serveur,
  pas de « jeu en ligne », de classement ni de tournoi. Pas d'iPhone pour
  l'instant.
- **Aucune image d'argent ni de pari** : la publicité pour un jeu gratuit
  n'a pas besoin d'autorisation tant qu'il ne ressemble pas à un jeu
  d'argent (voir [04-publicite.md](04-publicite.md)).
- **Jamais d'adresse e-mail en commentaire public** : les testeurs envoient
  leur adresse Gmail en message privé.

## Liste de contrôle

Dans l'ordre. Les dates relatives (J-28, J0…) partent du jour de la
publication en production sur Google Play.

**Préparation** ([01-page-facebook.md](01-page-facebook.md))

- [ ] Double authentification activée sur votre compte Facebook
- [ ] Page « Dhametna - ظامتنا » créée : catégorie, bio, photo, couverture
- [ ] Nom d'utilisateur (@dhametna ou proche) et bouton d'action « Envoyer un message »
- [ ] Un deuxième administrateur de confiance, en contrôle total
- [ ] Portefeuille business et Meta Business Suite ; messages automatiques
- [ ] WhatsApp relié (facultatif), Instagram relié (facultatif)

**Test fermé, J-28 à J-1** ([03-calendrier.md](03-calendrier.md), semaines 1 à 4)

- [ ] Vidéo 4:5 publiée et épinglée
- [ ] Recrutement d'au moins 15 testeurs (12 exigés par Google pendant 14 jours)
- [ ] Une publication tous les deux jours, un Reel par semaine

**Lancement, J0** ([03-calendrier.md](03-calendrier.md), semaine 5 ; [04-publicite.md](04-publicite.md))

- [ ] Liens Google Play avec UTM préparés
- [ ] Annonce publiée et épinglée ; bouton d'action vers Google Play
- [ ] Vidéo verticale en Reel, en statut WhatsApp et sur TikTok
- [ ] Première campagne publicitaire lancée

**Après le lancement**

- [ ] Réponse aux messages et commentaires sous 24 h
- [ ] Bilan chaque mois : abonnés, vues, clics, installations, notes (voir [02-strategie.md](02-strategie.md#mesurer))
