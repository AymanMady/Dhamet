# Localisation

L'application ne code aucun texte en dur dans les widgets : tout passe par
`AppLocalizations`, généré par `gen-l10n` à partir des fichiers ARB de
`lib/l10n/`. Seuls le nom ظامت, sa graphie latine DHAMET et le nom de chaque
langue écrit dans sa propre langue sont volontairement fixes.

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

Seul le vocabulaire du jeu **attesté par les sources** est déjà traduit.
C'est le cas de ظايم, le pion promu (voir `docs/rules.md` § 1). Aucune
phrase n'a été inventée : la traduction de l'interface est à confier à des
locuteurs natifs.

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
| Pion promu | Sultan | Sultan | سلطان | ظايم، سلطان |
| Prendre | prendre | capture | أكل | — (à documenter) |
| Pièces claires / foncées | bâtonnets / crottes | sticks / pellets | العيدان / البعر | العيدان / البعر |

Aucune source ne dit quel camp joue avec les bâtonnets et quel camp joue
avec les crottes. L'application nomme donc les camps **Blancs** et
**Noirs**. Elle dessine un bâtonnet sur les pièces claires et un anneau sur
les foncées, par simple choix visuel.

## Ajouter ou modifier un texte

1. Ajouter la clé dans `app_fr.arb`, avec sa description et ses
   paramètres (`@clé`).
2. La traduire dans `app_en.arb` et `app_ar.arb`. Pour l'arabe, utiliser
   les formes plurielles ICU `zero`, `one`, `two`, `few`, `many` et
   `other`.
3. `flutter gen-l10n`, ou tout simplement `flutter run` / `flutter test`.
4. `docs/l10n_untranslated.json` liste les messages qui manquent dans une
   langue complète. Il doit rester `{}`.
