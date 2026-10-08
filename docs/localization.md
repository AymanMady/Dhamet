# Localisation

L'application ne code aucun texte en dur dans les widgets : tout passe par
`AppLocalizations`, généré par `gen-l10n` à partir des fichiers ARB de
`lib/l10n/`. Seuls le nom de l'application, ظامتنا et sa graphie latine
DHAMETNA (`lib/app/brand.dart`), et le nom de chaque langue écrit dans sa
propre langue sont volontairement fixes.

| Langue | Locale | Fichier | Sens | État |
|---|---|---|---|---|
| Français | `fr` | `app_fr.arb` (modèle) | LTR | complet |
| English | `en` | `app_en.arb` | LTR | complet |
| العربية | `ar` | `app_ar.arb` | RTL | complet |
| الحسانية (Hassaniya) | `ar_MR` | `app_ar_MR.arb` | RTL | **à traduire par des locuteurs natifs** |

Pour connaître l'état des traductions :

```bash
dart run tool/l10n_status.dart          # résumé par langue
dart run tool/l10n_status.dart ar_MR    # liste des messages hassaniya manquants
```

## Hassaniya

Le hassaniya, arabe dialectal de Mauritanie, utilise la locale `ar_MR` :

- tout message absent de `app_ar_MR.arb` **se replie automatiquement sur
  l'arabe**, grâce à la classe générée `AppLocalizationsArMr extends
  AppLocalizationsAr` ;
- la mise en page est RTL et les widgets Material utilisent les
  traductions arabes ;
- sur un téléphone réglé en arabe (Mauritanie), l'application choisit
  d'elle-même le hassaniya.

Le vocabulaire traditionnel du jeu (العودان، لبعر، عود، بعرة، ظايمة) est
déjà celui de l'arabe : `app_ar_MR.arb` n'a donc rien à redéfinir pour
l'instant. Aucune phrase hassaniya n'a été inventée : la traduction du
reste de l'interface est à confier à des locuteurs natifs.

> La norme ISO 639-3 attribue au hassaniya le code `mey`, que Flutter ne
> connaît pas. `ar_MR` offre un repli propre sur l'arabe, pour les textes
> comme pour la direction d'écriture. Un passage à `mey` demanderait des
> délégués Material, Cupertino et Widgets dédiés.

## Glossaire du jeu

| Notion | Français | English | العربية | Hassaniya (sources) |
|---|---|---|---|---|
| Le jeu | Dhamet | Dhamet | ظامت | ظامت، اصرند |
| Point du plateau | intersection | intersection | نقطة | عين |
| Point avec diagonales | point vaste | wide point | نقطة واسعة | لوسع |
| Point sans diagonale | point étroit | narrow point | نقطة ضيقة | الظيك |
| Coin | coin | corner | زاوية | القرن / الكرن |
| Centre, vide au départ | case de rencontre | meeting point | النقطة الوسطى | عين المورده |
| Camp des bâtonnets | Laoudane | Laoudane | العودان | العودان |
| Camp des crottes de chameau | Lebaar | Lebaar | لبعر | لبعر |
| Bâtonnet (un) | aoud | aoud | عود | عود |
| Crotte de chameau (une) | baara | baara | بعرة | بعرة |
| Pièce promue | Dhayma | Dhayma | ظايمة | ظايمة |
| Prendre | prendre | capture | أكل | — (à documenter) |

L'application n'emploie que ces mots traditionnels : jamais Blancs, Noirs,
pièce, pion, soldat (جندي, قطعة) ni Sultan (سلطان). Un message qui parle de
l'un ou l'autre camp sans savoir lequel dit « عود أو بعرة », « un aoud ou
une baara ». Le français et l'anglais écrivent les mots hassaniya en lettres
latines, sans les traduire. `test/l10n/localization_test.dart` vérifie
qu'aucun ancien mot ne revient.

Aucune source ne dit quel camp commence ni lequel joue avec les bâtonnets.
Dans le moteur, Laoudane est `Player.white` et Lebaar `Player.black` ;
`piecesCount` reçoit le camp (`white` ou `black`) pour compter des عود ou
des بعرة.

## Ajouter ou modifier un texte

1. Ajouter la clé dans `app_fr.arb`, avec sa description et ses
   paramètres (`@clé`).
2. La traduire dans `app_en.arb` et `app_ar.arb`. Pour l'arabe, utiliser
   les formes plurielles ICU `zero`, `one`, `two`, `few`, `many` et
   `other`.
3. `flutter gen-l10n`, ou tout simplement `flutter run` / `flutter test`.
4. `docs/l10n_untranslated.json` liste les messages qui manquent dans une
   langue complète. Il doit rester `{}`.
