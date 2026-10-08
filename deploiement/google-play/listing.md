# Fiche Google Play — Dhametna

Textes à copier dans la Play Console (Croissance → Présence sur le Play
Store → Fiche principale), langue par défaut **français (fr-FR)**, avec les
traductions **arabe (ar)** et **anglais (en-US)**.

Les lignes marquées **[EN LIGNE]** ne valent que pour une version compilée
avec un serveur (`DHAMET_SERVER`, voir [docs/release.md](../../docs/release.md)).
Sans serveur, supprimez-les et prenez la description courte « sans jeu en
ligne ».

Limites de Google Play : titre 30 caractères, description courte 80,
description complète 4 000.

## Visuels

| Élément | Fichier | Format |
|---|---|---|
| Icône | `icon_512.png` | 512 × 512, PNG 32 bits, carré plein (Google Play arrondit lui-même) |
| Image de présentation | `feature_graphic_1024x500.png` | 1024 × 500, JPEG ou PNG sans transparence |
| Captures d'écran du téléphone | `screenshots/fr/`, `screenshots/ar/`, `screenshots/en/` | 4 par langue, 1080 × 1920, JPEG |

Les captures sont rendues par l'application elle-même :
`tool/store/screenshots.sh`. Régénérez-les après un changement d'interface,
avec `DHAMET_SERVER=…` si la version a le jeu en ligne (le bouton « Jouer en
ligne » apparaît alors sur l'accueil). Celles du dépôt montrent la version
sans serveur.

## Classement

- Application ou jeu : **Jeu**
- Catégorie : **Société** (Board)
- Tags suggérés : Jeux de société, Stratégie, Jeux de dames, Hors ligne
- Coordonnées : adresse e-mail de contact (obligatoire, publique)

---

## Français (fr-FR)

**Titre** (29)

```text
Dhametna : Dhamet mauritanien
```

**Description courte** (78)

```text
Le jeu de dames de Mauritanie, sur le sable : contre l'IA, à deux ou en ligne.
```

Sans jeu en ligne (68) :

```text
Le jeu de dames de Mauritanie, sur le sable : contre l'IA ou à deux.
```

**Description complète**

```text
Dhametna vous fait jouer au Dhamet (ظامت), le jeu de dames traditionnel de Mauritanie, aussi appelé Srand. Comme au village, la partie se joue sur le sable : le plateau est tracé au doigt, Laoudane joue avec des bâtonnets plantés (aouds) et Lebaar avec des crottes de chameau (baaras).

★ Plusieurs façons de jouer
• Contre l'ordinateur, avec 4 niveaux : Facile, Moyen, Difficile et Expert.
• À deux sur le même téléphone.
• En ligne avec un ami, dans une salle privée à code : partie classée ou amicale, avec ou sans pendule. [EN LIGNE]

★ Les vraies règles
• Plateau de 9 × 9 intersections au tracé d'alquerque, 40 aouds contre 40 baaras.
• La prise est obligatoire, et il faut toujours jouer la plus longue rafle.
• L'aoud ou la baara qui termine son coup sur la dernière rangée devient Dhayma (ظايمة) et se déplace à distance.
Les règles appliquées et leurs sources sont documentées. Les points encore discutés entre joueurs sont signalés, jamais inventés.

★ Apprendre et progresser
• Tutoriel interactif, pas à pas.
• Coups possibles en surbrillance, annulation d'un coup.
• Historique, relecture et statistiques de vos parties.
• Classement Elo et tournois entre amis. [EN LIGNE]

★ Pour tous
• Hors ligne : parties à deux, contre l'IA, tutoriel et historique fonctionnent sans Internet.
• En arabe, en français et en anglais.
• Thème clair ou sombre, compatible avec les lecteurs d'écran.
• Sans publicité et sans achat intégré.

Dhametna, « notre Dhamet » : le jeu traditionnel de Mauritanie, maintenant dans votre poche.
```

---

## العربية (ar)

**العنوان** (29)

```text
ظامتنا: لعبة ظامت الموريتانية
```

**الوصف القصير** (71)

```text
لعبة الداما الموريتانية على الرمل: ضد الحاسوب، لاعبان، أو عبر الإنترنت.
```

بدون اللعب عبر الإنترنت (60):

```text
لعبة الداما الموريتانية على الرمل: ضد الحاسوب أو بين لاعبين.
```

**الوصف الكامل**

```text
ظامتنا تتيح لك لعب ظامت، لعبة الداما التقليدية في موريتانيا، وتُعرف أيضًا باسم اصرند. كما في القرية، تُلعب المباراة على الرمل: الرقعة مرسومة بالإصبع، وتتواجه فيها العودان المغروسة في الرمل ولبعر.

★ طرق متعددة للعب
• ضد الحاسوب، بأربعة مستويات: سهل، متوسط، صعب، خبير.
• لاعبان على الهاتف نفسه.
• عبر الإنترنت مع صديق، في غرفة خاصة برمز: لعبة مصنَّفة أو ودية، مع ساعة أو بدونها. [EN LIGNE]

★ القواعد الحقيقية
• رقعة من 9 × 9 نقاط على نمط القِرق، و40 عودًا مقابل 40 بعرة.
• الأكل إجباري، ويجب أكل أكثر ما يمكن.
• العود أو البعرة إذا أنهى نقلته على الصف الأخير يصبح ظايمة تتحرك عن بُعد.
القواعد المطبقة ومصادرها موثقة. والنقاط التي ما زال اللاعبون يختلفون فيها مُشار إليها، ولا شيء منها مُختلَق.

★ تعلَّم وتقدَّم
• درس تفاعلي خطوة بخطوة.
• إبراز النقلات الممكنة، وإمكانية التراجع عن نقلة.
• سجل ألعابك وإعادة عرضها وإحصاءاتها.
• ترتيب إيلو وبطولات بين الأصدقاء. [EN LIGNE]

★ للجميع
• دون إنترنت: اللعب بين لاعبين وضد الحاسوب والدرس والسجل تعمل دون اتصال.
• بالعربية والفرنسية والإنجليزية.
• مظهر فاتح أو داكن، ومتوافقة مع قارئات الشاشة.
• بلا إعلانات وبلا مشتريات داخل التطبيق.

ظامتنا: لعبة موريتانيا التقليدية، الآن في جيبك.
```

---

## English (en-US)

**Title** (28)

```text
Dhametna: Mauritanian Dhamet
```

**Short description** (79)

```text
Mauritania's draughts game, played on the sand: vs the AI, two players, online.
```

Without online play (78):

```text
Mauritania's draughts game, played on the sand: against the AI or two players.
```

**Full description**

```text
Dhametna lets you play Dhamet (ظامت), the traditional draughts game of Mauritania, also known as Srand. Just like in the village, the game is played on the sand: the board is drawn with a finger, Laoudane plays with planted sticks (aouds) and Lebaar with camel-dung pellets (baaras).

★ Many ways to play
• Against the computer, with 4 levels: Easy, Medium, Hard and Expert.
• Two players on the same phone.
• Online with a friend, in a private room with a code: rated or friendly, with or without a clock. [EN LIGNE]

★ The real rules
• A 9 × 9 board of intersections with the alquerque pattern, 40 aouds against 40 baaras.
• Capturing is mandatory, and you must always play the longest capture sequence.
• An aoud or a baara that ends its move on the last row becomes a Dhayma (ظايمة) and moves from afar.
The rules applied and their sources are documented. Points still debated among players are flagged, never made up.

★ Learn and improve
• Step-by-step interactive tutorial.
• Possible moves highlighted, undo a move.
• History, replay and statistics of your games.
• Elo rating and tournaments among friends. [EN LIGNE]

★ For everyone
• Offline: two-player games, games against the AI, the tutorial and your history work without Internet.
• In Arabic, French and English.
• Light or dark theme, works with screen readers.
• No ads and no in-app purchases.

Dhametna, "our Dhamet": Mauritania's traditional game, now in your pocket.
```

---

## Notes de version 1.0.0

Sans jeu en ligne, retirez « ou en ligne » / « أو عبر الإنترنت » / « or
online ».

```text
<fr-FR>
Première version : jouez au Dhamet contre l'IA, à deux ou en ligne, et apprenez les règles avec le tutoriel.
</fr-FR>
<ar>
الإصدار الأول: العب ظامت ضد الحاسوب أو مع صديق أو عبر الإنترنت، وتعلّم القواعد مع الدرس التفاعلي.
</ar>
<en-US>
First release: play Dhamet against the AI, with a friend or online, and learn the rules with the tutorial.
</en-US>
```
