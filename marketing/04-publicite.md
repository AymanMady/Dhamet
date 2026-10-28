# Publicité sur Facebook

La Page et ses publications sont gratuites ; la publicité accélère le
lancement. Commencez petit, mesurez, puis mettez l'argent sur ce qui
marche.

## Avant de payer

1. **Portefeuille business et compte publicitaire** : Meta Business Suite
   → **Paramètres** → **Comptes** → **Comptes publicitaires** → **Ajouter**
   → **Créer un compte publicitaire**. Devise : dollar américain ou euro ;
   fuseau horaire : Nouakchott (GMT).
2. **Double authentification** : obligatoire pour faire de la publicité
   depuis un portefeuille business (voir
   [01-page-facebook.md](01-page-facebook.md#1-sécuriser-votre-compte)).
3. **Moyen de paiement** : **Paramètres de paiement** du compte
   publicitaire. Meta accepte les cartes Visa et Mastercard (et American
   Express) et PayPal. Rien n'indique que Bankily ou Masrvi soient
   acceptés : prenez une carte Visa internationale ouverte aux paiements
   en ligne et à l'étranger (demandez-le à votre banque), ou la carte ou le
   compte PayPal d'un proche de la diaspora.

**N'ajoutez pas le SDK Facebook à l'application.** La version sans jeu en
ligne déclare sur Google Play « Aucune donnée collectée » (voir
[deploiement/google-play/data-safety.md](../deploiement/google-play/data-safety.md)) :
un SDK publicitaire obligerait à changer ces déclarations et la politique
de confidentialité, et casserait la promesse « rien ne quitte
l'appareil ». Les installations se mesurent sans lui, avec les liens UTM
([ci-dessous](#mesurer-les-installations)).

## Deux façons de faire

| | Booster une publication | Gestionnaire de publicités (Ads Manager) |
|---|---|---|
| Où | Bouton **Booster** sous une publication de la Page | [adsmanager.facebook.com](https://adsmanager.facebook.com) ou Business Suite → **Publicités** |
| Pour | Faire voir une publication qui marche déjà | Une vraie campagne : objectif, plusieurs annonces, tests |
| Limites | Texte et image de la publication non modifiables | Plus de réglages |

Débutez par un boost de la publication de lancement (n° 12 du
[calendrier](03-calendrier.md)) ; passez au gestionnaire quand vous voulez
comparer plusieurs annonces.

## Campagne 1 : recruter les testeurs (facultatif, J-24)

Si les amis et la famille ne suffisent pas à trouver 15 testeurs.

| Réglage | Valeur |
|---|---|
| Quoi | Booster la publication n° 3 (appel aux testeurs) |
| Objectif | **Plus de messages** (Messenger, ou WhatsApp s'il est relié) |
| Audience | Mauritanie, 18–45 ans |
| Budget | 2 $ par jour pendant 5 jours |

## Campagne 2 : le lancement (J0 à J+14)

### Objectif

Deux possibilités dans le gestionnaire de publicités ; Meta en propose
six en tout (Notoriété, Trafic, Interactions, Prospects, Promotion de
l'application, Ventes).

- **Trafic**, vers le lien Google Play avec UTM : le plus simple, sans rien
  enregistrer chez Meta. Meta pourrait refuser ou freiner une annonce
  « Trafic » qui pointe vers une boutique d'applications (non confirmé) :
  si l'annonce est refusée, prenez l'objectif suivant.
- **Promotion de l'application** : il faut d'abord enregistrer
  l'application, gratuitement, sur
  [developers.facebook.com](https://developers.facebook.com) (Créer une
  app → plateforme Android → nom du paquet `mr.dhametna.app` et lien
  Google Play), la relier au compte publicitaire, et accepter les
  conditions des publicités pour applications. Sans SDK, Meta ne voit pas
  les installations : la campagne s'optimise alors sur les clics.

### Audience

| Réglage | Ensemble A : Mauritanie | Ensemble B : diaspora |
|---|---|---|
| Lieux | Mauritanie | Sénégal, Mali, France, Espagne, Émirats arabes unis, Arabie saoudite, États-Unis |
| Âge | 18–55 ans | 18–55 ans |
| Langues | — | Arabe |
| Ciblage détaillé | Aucun : laissez Meta trouver (audience large) | « A vécu en Mauritanie », si Meta le propose ; sinon langue arabe et centres d'intérêt « Mauritanie » |
| Appareils | **Android uniquement** (Placements → appareils mobiles → Android) | Android uniquement |

L'ensemble B est plus cher et plus incertain : gardez-le petit au début.

### Placements et annonces

Placements **Advantage+** (automatiques), ou à la main : fil Facebook,
Reels Facebook, Stories Facebook (et Instagram si le compte est relié).

| Annonce | Média | Texte principal | Titre | Bouton |
|---|---|---|---|---|
| 1. Vidéo | `video/dhametna-demo-4x5.mp4` (et `9x16` pour Reels et Stories) | Texte de la publication n° 12 | ظامتنا: ظامت على هاتفك | **Installer** ou **En savoir plus** |
| 2. Image | `visuels/post-05-lancement.png` | « ظامت، لعبتنا التقليدية، على هاتفك. مجانية، بلا إعلانات، وتعمل دون إنترنت. » | حمّلها مجانًا | Idem |

### Budget

Le minimum est de 1 $ par jour et par ensemble de publicités ; Meta
conseille au moins 5 $ par jour pendant six jours pour qu'il apprenne.

| Période | Ensemble A | Ensemble B | Total |
|---|---|---|---|
| J0 à J+6 : test des deux annonces | 4 $/jour | 1 $/jour | 35 $ |
| J+7 à J+13 : la meilleure annonce seulement | 5 $/jour | 1 $/jour (ou 0) | 35 à 42 $ |

Soit 70 à 80 $ pour les deux semaines. Au bout de trois jours, coupez une
annonce dont le taux de clic reste sous 0,5 % ou dont le coût par clic est
plus du double de l'autre.

## Règles de Meta à respecter

- Un jeu **entièrement gratuit qui ne simule pas de jeu d'argent** peut
  faire de la publicité sans autorisation préalable. Pas de monnaie, de
  billets, de mises ni de « gagnez de l'argent » dans les annonces.
- Pas d'annonce qui vise ou montre des mineurs.
- Pas de promesse fausse (iPhone, jeu en ligne absent de la version
  publiée).
- L'examen d'une annonce prend en général moins de 24 h : lancez la veille
  au soir pour être en ligne le matin de J0.

## Mesurer les installations

Un lien Google Play peut porter un paramètre `referrer` avec des valeurs
UTM, encodées (`=` devient `%3D`, `&` devient `%26`) :

```text
https://play.google.com/store/apps/details?id=mr.dhametna.app&referrer=utm_source%3Dfacebook%26utm_medium%3Dsocial%26utm_campaign%3Dlancement
```

Un lien par canal, pour savoir d'où viennent les joueurs :

| Où | utm_source | utm_medium | utm_campaign |
|---|---|---|---|
| Publications de la Page, bouton d'action | `facebook` | `social` | `lancement` |
| Publicités Facebook | `facebook` | `paid` | `lancement` |
| WhatsApp (statut, groupes) | `whatsapp` | `social` | `lancement` |
| TikTok | `tiktok` | `social` | `lancement` |
| Instagram | `instagram` | `social` | `lancement` |

Le [générateur de Google](https://ga-dev-tools.web.app/ga4/campaign-url-builder/play/)
fabrique ces liens sans erreur d'encodage.

Où lire les résultats : Play Console → **Développer l'audience** →
**Performances de la fiche Play Store** → **Analyse des conversions**,
avec la source de trafic **Annonces et sites référents**, puis les
dimensions « source UTM » et « campagne UTM ». Depuis juillet 2026, ce
rapport compte les clics vers la fiche ; les installations totales sont
dans la vue d'ensemble de **Développer l'audience**. Les petits nombres
sont regroupés sous « Autre ».

Aucune ligne de code n'est nécessaire pour ces chiffres de la Play Console.

## Sources

Consultées en octobre 2026 :

- [Objectifs publicitaires](https://www.facebook.com/business/help/1438417719786914)
- [Booster une publication ou utiliser le gestionnaire](https://www.facebook.com/business/help/347839548598012)
- [Budget minimum](https://en-gb.facebook.com/business/help/203183363050448)
- [Moyens de paiement](https://www.facebook.com/business/help/212763688755026)
- [Publicités pour applications](https://developers.facebook.com/docs/app-ads/overview)
- [Jeux et jeux d'argent dans les publicités](https://transparency.meta.com/policies/ad-standards/restricted-goods-services/gambling-games)
- [Liens UTM Google Play](https://developer.android.com/games/playgames/user-acquisition)
- [Analyse des conversions de la Play Console](https://support.google.com/googleplay/android-developer/answer/9859173)
