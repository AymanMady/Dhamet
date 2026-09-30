# Règles du Dhamet — ظامت

Ce document est la **référence des règles** implémentées par le moteur
(`packages/dhamet_engine`). Chaque règle porte :

- un **identifiant** stable, repris dans le code (`dhametRuleCatalog`) ;
- un **statut** ;
- le cas échéant, le **paramètre** de `DhametRules` qui la contrôle ;
- les **sources** qui l'établissent (voir [§ 15](#15-sources)).

Les récapitulatifs sont en fin de document :
[Confirmed Rules](#confirmed-rules), [Unconfirmed Rules](#unconfirmed-rules)
et [Configurable Rules](#configurable-rules).

| Statut | Signification |
|---|---|
| `CONFIRMED` | Énoncée de façon concordante par au moins deux sources indépendantes. |
| `LIKELY` | Énoncée par plusieurs sources, mais l'une d'elles est ambiguë. |
| `VARIANT` | Alternative documentée, non retenue par défaut. |
| `NEEDS_VERIFICATION` | Sources contradictoires ou muettes : à faire valider par des joueurs expérimentés ou par la Fédération mauritanienne de Dhamet. |

> Aucune règle n'a été inventée. Quand les sources se taisent, le moteur
> choisit le comportement le moins restrictif, le marque
> `NEEDS_VERIFICATION` et le rend paramétrable.

---

## 1. Noms et terminologie

- **ظامت** (Dhamet, Damet), aussi appelé **اصرند** (Srand, Strand) : jeu
  national mauritanien, de la famille de l'alquerque et du Zamma. [S1, S2, S7]
- La version mauritanienne se distingue des autres Zamma par le **retrait
  immédiat** des pièces prises pendant une rafle. [S3, S4, S5]
- Les deux armées sont traditionnellement des **bâtonnets** (العيدان) et des
  **crottes de chameau** (البعر), tracées et jouées sur le sable. [S7, S8, S9]
  Le moteur les appelle `Player.white` et `Player.black`.

Terminologie hassaniya relevée [S7], à compléter et vérifier avec des joueurs :

| Terme | Sens |
|---|---|
| عين | point (intersection) du plateau |
| الكرن / القرن | coin (4 sur le plateau) |
| الظيك / الضيق | point **étroit** : sans diagonale (« case fermée » [S1]) |
| لوسع / الوسع | point **vaste** : avec diagonales (« case ouverte » [S1]) |
| عين المورده | point central, vide au départ (« case de rencontre » [S1]) |
| سلطان / ظايم | pion promu, le **Sultan** [S3, S7] |
| أشرك | « pièges » : un coin et le point vaste voisin sur la dernière rangée |
| التشراك | embuscade préparée |
| الكاصف | embuscade ratée |
| السائل | étourderie que l'adversaire choisit de ne pas sanctionner |
| السله، لكريف | deux opérations de jeu (sens exact **à documenter**) |
| النزل على ظر | déplacement latéral — **interdit** [S8] |

## 2. Coordonnées et notation

Le moteur utilise la notation de la source française [S1] : colonnes `a` à
`i` de gauche à droite, rangées `1` à `9` depuis le camp des Blancs.

- Déplacement : `d4-e5`.
- Prise : `c3xe5`.
- Rafle : toutes les étapes (`g7xi5xg3xg5xe7xc9`), ou seulement le départ et
  l'arrivée (`e5xa5`), comme l'écrit la source.

## 3. Plateau — `board.grid`, `board.diagonals` — CONFIRMED

Les pièces se placent sur les **81 intersections** d'une grille de 9 × 9
lignes [S1, S2, S3, S4]. Le tracé est celui de **quatre plateaux d'alquerque
accolés** [S3, S4, S5] : toutes les rangées et colonnes, et **14 diagonales**
[S1].

Les diagonales passent par les intersections dont `colonne + rangée` est
**pair** : les points vastes (لوسع). Il y en a 41, dont les 4 coins et le
centre. Les 40 autres sont les points étroits (الظيك), traversés seulement
par leur rangée et leur colonne. La source française donne des exemples :
a1, e3 et h4 sont ouverts ; b1, c4 et h5 sont fermés [S1].

```text
9  ●───●───●───●───●───●───●───●───●
   │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │
8  ●───●───●───●───●───●───●───●───●
   │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │
7  ●───●───●───●───●───●───●───●───●
   │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │
6  ●───●───●───●───●───●───●───●───●
   │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │
5  ●───●───●───●───●───●───●───●───●
   │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │
4  ●───●───●───●───●───●───●───●───●
   │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │
3  ●───●───●───●───●───●───●───●───●
   │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │
2  ●───●───●───●───●───●───●───●───●
   │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │ ╱ │ ╲ │
1  ●───●───●───●───●───●───●───●───●
   a   b   c   d   e   f   g   h   i
```

Graphe obtenu : 144 segments orthogonaux et 64 segments diagonaux (vérifié
par les tests).

> Remarque pour l'interface : sur les plateaux tracés dans le sable, les
> rangées 2, 4, 6, 8 et les colonnes b, d, f, h ne sont souvent pas dessinées
> [S1]. Elles existent pourtant pour le jeu : la source montre des prises le
> long de la rangée 6. L'interface pourra proposer ce style de tracé.

## 4. Matériel et position initiale — `setup.pieces`, `setup.middleRow` — CONFIRMED

- 40 pièces par camp. Seule l'intersection centrale **e5** est vide
  [S1, S2, S3, S7].
- Les Blancs occupent les rangées 1 à 4, les Noirs les rangées 6 à 9.
- Sur la rangée 5, chaque camp place ses 4 dernières pièces **à sa droite**
  [S1, S3]. Le partage 4 + 4 de la rangée 5 est confirmé par [S7].

```text
9  b b b b b b b b b
8  b b b b b b b b b
7  b b b b b b b b b
6  b b b b b b b b b
5  b b b b . w w w w
4  w w w w w w w w w
3  w w w w w w w w w
2  w w w w w w w w w
1  w w w w w w w w w
   a b c d e f g h i
```

Cette position est symétrique par demi-tour (couleurs échangées).

## 5. Premier joueur — `turn.startingPlayer` — NEEDS_VERIFICATION

Les sources se contredisent :

- « Les blancs commencent toujours » [S1] ; l'ouverture traditionnelle
  (§ 11) commence aussi par un coup blanc.
- « Black moves first » [S3, S4, S5, S6].

La position étant symétrique, la question porte seulement sur le nom donné
au premier joueur (bâtonnets ou crottes de chameau ?).
**Défaut du moteur : Blancs**, paramètre `startingPlayer`. Ce défaut restera
inchangé tant qu'aucune nouvelle source ne tranche la question.

## 6. Déplacement des pions — `pawn.move` — CONFIRMED

Un pion avance d'**un pas** vers une intersection vide voisine, **tout droit
ou en diagonale vers l'avant**, en suivant une ligne tracée
[S1, S2, S3, S4, S7, S8].

- Jamais de recul hors prise [S1, S2, S7, S8].
- Jamais de déplacement latéral (« النزل على ظر ») [S1, S8].
- Depuis un point étroit, seul le pas tout droit est possible. Depuis un
  point vaste, trois pas sont possibles.

Exemples de la source française [S1], repris dans les tests : a1 → a2 ou
b2 ; b3 → b4 seulement ; e3 → d4, e4 ou f4.

## 7. Prises

### 7.1 Prise par le pion — `capture.pawnDirections` — CONFIRMED

Le pion saute par-dessus une pièce adverse **adjacente** et se pose sur
l'intersection **immédiatement derrière**, qui doit être libre. Le saut suit
une ligne tracée, **dans toutes les directions : en avant, de côté et en
arrière** [S1, S2, S3, S4, S7].

Exemples [S1], repris dans les tests : le pion c7 (point vaste) peut
prendre en a9, c9, e7, c5 ou a5 ; le pion g6 (point étroit) en g4, e6, g8
ou i6.

Paramètres : `pawnCapturesBackward`, `pawnCapturesSideways` (tous deux
`true` par défaut).

### 7.2 Prise obligatoire — `capture.mandatory` — CONFIRMED

Prendre est obligatoire [S1, S2, S3, S4, S5]. Quand une prise existe, le
moteur ne propose aucun autre coup. Paramètre : `mandatoryCapture`.

### 7.3 Rafles et prise majoritaire — `capture.maximum` — CONFIRMED

- On peut enchaîner plusieurs prises, en changeant de direction [S1, S2,
  S3, S4, S5].
- On doit toujours jouer la rafle qui prend **le plus de pièces** [S1, S2,
  S3, S4, S5]. Le maximum se calcule sur toutes les pièces du camp.
- Une rafle ne peut pas être interrompue : ce serait une faute sanctionnée
  par le soufflé (§ 10) [S1].
- Si plusieurs rafles prennent le même nombre maximal de pièces, le joueur
  choisit.

Exemple [S1], repris dans les tests : le pion blanc g7 exécute la rafle
g7 x i5 x g3 x g5 x e7 x c9.

`capture.maximumSultanWeight` — **NEEDS_VERIFICATION** : aucune source ne
dit si un Sultan compte davantage qu'un pion dans ce calcul. Le moteur
compte les pièces seulement.

### 7.4 Retrait immédiat — `capture.immediateRemoval` — CONFIRMED

« Contrairement aux dames, les pions doivent être retirés du jeu au fur et
à mesure que le joueur effectue sa rafle » [S1]. C'est la particularité
mauritanienne [S3, S4, S5]. La variante `endOfSequence` (Zamma d'ailleurs)
reste disponible.

Constat établi en développant le moteur, et vérifié par les tests : pour un
**pion**, le moment du retrait ne change rien. Il atterrit toujours à un
écart pair de sa case de départ et saute des pièces situées à un écart
impair ; il ne peut donc jamais repasser par une case vidée. La règle ne
concerne en pratique que le **Sultan**, qui peut survoler une case vidée,
voire terminer sa rafle sur la case d'une pièce qu'il vient de prendre.

## 8. Promotion — `promotion.lastRow`, `promotion.notDuringCapture` — CONFIRMED

- Un pion qui **termine** son coup sur la dernière rangée adverse devient
  **Sultan** [S1, S2, S3, S4, S7], que ce soit par un déplacement ou à la fin
  d'une rafle.
- Un pion qui ne fait que **traverser** cette rangée au cours d'une rafle
  n'est pas promu. Il poursuit la rafle en tant que pion [S2 : « lorsqu'il
  s'arrête sur la dernière ligne »] [S4].
- Sur le sable, on superpose un second pion, comme aux dames [S1].

## 9. Sultan

### `sultan.flying` — CONFIRMED

- Le Sultan se déplace dans toutes les directions, d'autant d'intersections
  qu'il veut, le long d'une ligne, tant que rien ne le bloque
  [S1, S2, S3, S4, S5].
- Il prend une pièce adverse située sur sa ligne **à n'importe quelle
  distance**, si le chemin jusqu'à elle est libre et si l'intersection
  derrière elle est libre [S1, S2, S5].
- Sur un point étroit, il n'a pas de diagonale : « le Sultan b7 ne peut se
  déplacer que sur la rangée 7 et la colonne b » [S1].

Paramètre : `sultanFlies`. La valeur `false` donne un Sultan à pas unique,
qui ne correspond à aucune source sur le Dhamet.

### `sultan.landing` — LIKELY

« Il peut s'arrêter ailleurs qu'immédiatement derrière la dernière pièce
prise » [S2], « land anywhere behind the captured piece » [S3, S4], « landing
on one of these cells » [S5]. La source française ne montre qu'un
atterrissage juste derrière (e5 x c3, posé en b2) [S1], sans exclure les
autres. Paramètre : `sultanLanding`, avec `anyEmptyPointBeyond` par défaut
et `immediatelyBehind` en variante.

### `sultan.reverseDuringCapture` — NEEDS_VERIFICATION

Pendant une rafle, le Sultan peut-il repartir dans la direction opposée à
sa prise précédente, en repassant sur la case qu'il vient de vider ?
Certaines dames, dont les dames turques, l'interdisent. **Aucune source ne
traite ce point pour le Dhamet.** Le moteur l'autorise par défaut, puisque
rien ne l'interdit. Paramètre : `sultanMayReverseDuringCapture`.

## 10. Souvlet / Soufflé — `souvlet` — NEEDS_VERIFICATION (abstraction seulement)

Ce que disent les sources :

> « **Soufflés** : lorsqu'un joueur n'a pas effectué sa rafle complète, son
> adversaire peut l'exiger ou lui souffler son pion ou son sultan
> (c'est-à-dire le retirer du jeu). Dans le cas de rafles compliquées, le
> joueur annonce à l'avance le nombre de pions qu'il va prendre. Si son
> adversaire démontre qu'il pouvait en prendre davantage, il souffle le pion
> ou le Sultan qui devait effectuer la rafle. » [S1]

> « Un joueur peut se voir interdit par son adversaire tout coup qui ne
> permettrait pas la prise d'un maximum de pièces, son adversaire peut aussi
> choisir de souffler la pièce fautive. » [S2]

Le terme hassaniya السائل (étourderie que l'adversaire choisit de ne pas
sanctionner) [S7] évoque la même logique : la sanction est **au choix** de
l'adversaire.

| Question | Réponse des sources |
|---|---|
| Qu'est-ce qui déclenche la pénalité ? | Une rafle incomplète [S1], ou tout coup qui ne prend pas le maximum [S2], donc probablement aussi l'absence de prise quand une prise existe. |
| Quelle conséquence ? | Au choix de l'adversaire : **exiger** le bon coup, ou **souffler** (retirer) la pièce fautive [S1, S2]. |
| Quelle pièce est retirée ? | « Le pion ou le Sultan qui devait effectuer la rafle » [S1]. **Inconnu** si plusieurs pièces pouvaient prendre : qui choisit ? |
| Le coup fautif est-il maintenu après le soufflé ? | **Inconnu.** |
| Le soufflé compte-t-il comme un coup ? | **Inconnu.** |
| Faut-il annoncer le nombre de prises ? | Oui, pour les « rafles compliquées » [S1]. Seuil inconnu. |
| Toutes variantes, règle de compétition ? | **Inconnu.** |

**Décision actuelle :** le moteur ne génère que des coups légaux, et
l'application les impose. Une faute est donc impossible et le soufflé n'a
pas lieu d'être. Cela revient à l'option « l'adversaire exige le bon coup ».

**Abstraction en place :** `DhametRules.souvlet` est un `SouvletRule`.

- `SouvletRule.disabled` (défaut) correspond au comportement décrit
  ci-dessus.
- `SouvletRule.enabled` existe comme configuration et peut être
  sauvegardé, mais **son comportement n'est pas implémenté**. Tant qu'il
  n'est pas confirmé, le moteur refuse de générer des coups avec cette
  configuration (`UnsupportedError`). La règle ne peut donc jamais
  s'appliquer silencieusement de façon inventée.
- Les questions ouvertes sont reprises dans le code (`TODO(CONFIRMATION_NEEDED)`
  dans `souvlet_rule.dart`). Une fois tranchées, `SouvletRule` recevra ses
  options et l'application pourra proposer un mode « traditionnel », où une
  rafle non maximale est jouable et où l'adversaire choisit d'exiger le bon
  coup ou de souffler.

## 11. Ouverture traditionnelle « rencontre » — `opening.rencontre` — VARIANT (option, désactivée par défaut)

> « Une partie débute par une "rencontre" qui est conventionnellement
> toujours la même : d4-e5 (f6xd4) ; c3xe5 (a5xc3) ; b2xd4 (c5xc3) ; e5xa5
> (c3xe5) ; f5xd5 (d6xd4) ; … » (coups noirs entre parenthèses) [S1]

> « Ce pion d4 peut être pris de trois manières différentes : la prise en d5,
> la prise en c4, préférée des grands maîtres, et la prise en c5. » [S1]

- fr.wikipedia dit que les cinq premiers coups de chaque joueur sont « fixés
  par règle » [S2]. La source [S1] parle d'une simple **convention**.
- **Validation du moteur :** les tests rejouent cette séquence. Chaque coup
  y est légal, les répliques forcées sont bien les seuls coups légaux, et
  les Blancs ont ensuite **exactement trois** façons de prendre d4 (d3xd5,
  e4xc4, e3xc5), avec l'avance d'un pion annoncée par la source. C'est une
  confirmation indépendante du tracé des diagonales, de la position
  initiale, des prises latérales et du retrait immédiat.
- **Paramètre `opening`** :
  - `OpeningRule.free` (**défaut**) : jeu libre dès le premier coup.
  - `OpeningRule.traditionalEncounter` : tant que la partie suit la
    rencontre depuis la position initiale, seul le coup prévu est légal.
    Les 10 coups sont joués, puis le jeu redevient libre avec les trois
    prises de d4.
    - Si les Noirs commencent, la même séquence est jouée par l'autre camp,
      en miroir (demi-tour du plateau).
    - Si un coup de la séquence est illégal avec les autres paramètres (par
      exemple e5xa5 quand les prises latérales sont désactivées), la
      séquence s'arrête à ce coup.
- Cette ouverture n'est **jamais imposée par défaut**. À confirmer : est-elle
  obligatoire, en compétition comme en partie libre ?

## 12. Fin de partie

| Id | Règle | Statut |
|---|---|---|
| `end.elimination` | Celui qui n'a plus de pièce perd [S1, S2, S3, S4, S8]. | CONFIRMED |
| `end.blocked` | Celui qui ne peut plus jouer perd [S1, S2, S5]. C'est rare en pratique [S1, S2]. | CONFIRMED |
| `end.draw` | Nulle par accord mutuel ou triple répétition [S5 seulement, sans référence]. | NEEDS_VERIFICATION, désactivée par défaut |

Il n'y a pas de limite de temps traditionnelle : « لا يوجد مجال زمني محدد
للعبة » (« aucun temps n'est imposé »). La phrase a été relevée dans la
presse arabe, mais sa source exacte reste **à retrouver**. Une pendule
pour le mode compétitif en ligne serait donc une règle **propre à
l'application**, à présenter comme telle.

**Implémentation : `GameEndDetector`**. Il lit la position, avec l'historique
pour la répétition, dans cet ordre :

1. **Élimination** : le camp sans pièce perd (`GameEndReason.elimination`).
2. **Blocage** : le camp au trait, qui a des pièces mais aucun coup légal,
   perd (`GameEndReason.blocked`).
3. **Répétition** : seulement si `draw.repetitionLimit` est défini. Une
   position compte comme répétée si le plateau **et** le camp au trait sont
   identiques (`GameEndReason.repetition`).

Les **nulles sont désactivées par défaut** : `DhametRules.draw` vaut
`DrawRules.none`. Avec les options `DrawRules(byAgreement: true)` et
`DrawRules(repetitionLimit: 3)`, la nulle devient possible par accord
(`Game.agreeToDraw()`) et par triple répétition.

Fins déclarées (hors position), gérées par `Game` :

- abandon (`resign`) ;
- dépassement du temps (`loseOnTime`), réservé au futur mode compétitif ;
- nulle par accord, si elle est autorisée.

**Annuler / rétablir** n'est pas une règle du jeu mais une fonction de
l'application. C'est `UndoPolicy` qui la gouverne : désactivé par défaut, à
activer pour les parties locales seulement, jamais en ligne.

## 13. Format de match — `match.threeRounds` — VARIANT

« Deux joueurs s'affrontent en trois manches » ; « une défaite ne compte que
si elle intervient trois fois de suite » [S8, presse]. Utile pour les
tournois (phase 11), à confirmer auprès de la Fédération.

## Confirmed Rules

Règles confirmées par au moins deux sources indépendantes. Elles sont
implémentées et testées, et ne doivent pas changer sans nouvelle source.

| Id | Règle | Sources |
|---|---|---|
| `board.grid` | 81 intersections, grille de 9 × 9 lignes | S1, S2, S3, S4 |
| `board.diagonals` | Tracé d'alquerque : 14 diagonales passant par les points vastes (`colonne + rangée` pair) | S1, S3, S4, S5 |
| `setup.pieces` | 40 pièces par camp, centre e5 vide | S1, S2, S3, S7 |
| `setup.middleRow` | 4 pièces par camp sur la rangée 5, à sa droite | S1, S3, S7 |
| `pawn.move` | Un pas en avant, tout droit ou en diagonale ; ni recul ni pas latéral | S1, S2, S3, S4, S7, S8 |
| `capture.pawnDirections` | Prise par saut court dans toutes les directions | S1, S2, S3, S4, S7 |
| `capture.mandatory` | Prise obligatoire | S1, S2, S3, S4, S5 |
| `capture.maximum` | Rafle complète, et celle qui prend le plus de pièces | S1, S2, S3, S4, S5 |
| `capture.immediateRemoval` | Pièces retirées au fur et à mesure de la rafle | S1, S3, S4, S5 |
| `promotion.lastRow` | Pion terminant son coup sur la dernière rangée : Sultan | S1, S2, S3, S4, S7 |
| `promotion.notDuringCapture` | Pas de promotion en simple passage pendant une rafle | S2, S4 |
| `sultan.flying` | Sultan volant : déplacement et prise à distance | S1, S2, S3, S4, S5 |
| `end.elimination` | Le camp sans pièce perd | S1, S2, S3, S4, S8 |
| `end.blocked` | Le camp sans coup légal perd | S1, S2, S5 |

## Unconfirmed Rules

Règles contradictoires, ambiguës ou non documentées. Chacune a un
comportement par défaut prudent et reste **à confirmer** (voir § 14).

| Id | Statut | Comportement par défaut | À confirmer |
|---|---|---|---|
| `turn.startingPlayer` | NEEDS_VERIFICATION | Blancs | Quel camp commence (S1 contre S3-S6) |
| `sultan.landing` | LIKELY | N'importe où derrière la pièce prise | Seulement juste derrière ? |
| `sultan.reverseDuringCapture` | NEEDS_VERIFICATION | Demi-tour autorisé | Aucune source |
| `capture.maximumSultanWeight` | NEEDS_VERIFICATION | Seul le nombre de pièces compte (non paramétrable) | Un Sultan compte-t-il plus ? |
| `souvlet` | NEEDS_VERIFICATION | Désactivé : seuls les coups légaux sont jouables | Déclencheur, pièce retirée, coup maintenu… (§ 10) |
| `opening.rencontre` | VARIANT | Jeu libre | Rencontre obligatoire ou convention ? |
| `end.draw` | NEEDS_VERIFICATION | Aucune nulle | Accord ? Répétition ? Autre ? |
| `match.threeRounds` | VARIANT | Non implémenté | Format de match de la Fédération |

## Configurable Rules

Tous les paramètres de `DhametRules`, sauvegardés avec chaque partie. Une
partie ancienne sans un paramètre récent prend sa valeur par défaut.

| Paramètre | Défaut | Autres valeurs | Règle | Statut |
|---|---|---|---|---|
| `startingPlayer` | `white` | `black` | `turn.startingPlayer` | NEEDS_VERIFICATION |
| `mandatoryCapture` | `true` | `false` | `capture.mandatory` | CONFIRMED |
| `captureChoice` | `maximumPieces` | `free` | `capture.maximum` | CONFIRMED |
| `capturedPieceRemoval` | `immediate` | `endOfSequence` (Zamma) | `capture.immediateRemoval` | CONFIRMED |
| `pawnCapturesBackward` | `true` | `false` | `capture.pawnDirections` | CONFIRMED |
| `pawnCapturesSideways` | `true` | `false` | `capture.pawnDirections` | CONFIRMED |
| `sultanFlies` | `true` | `false` (pas unique) | `sultan.flying` | CONFIRMED |
| `sultanLanding` | `anyEmptyPointBeyond` | `immediatelyBehind` | `sultan.landing` | LIKELY |
| `sultanMayReverseDuringCapture` | `true` | `false` | `sultan.reverseDuringCapture` | NEEDS_VERIFICATION |
| `opening` | `free` | `traditionalEncounter` | `opening.rencontre` | VARIANT |
| `souvlet` | `SouvletRule.disabled` | `enabled` (refusé tant que non confirmé) | `souvlet` | NEEDS_VERIFICATION |
| `draw` | `DrawRules.none` | `byAgreement`, `repetitionLimit` | `end.draw` | NEEDS_VERIFICATION |

Les valeurs par défaut des règles CONFIRMED ne doivent pas être modifiées.
Les autres valeurs servent aux variantes, au tutoriel et aux tests.

## 14. Questions à poser aux joueurs ou à la Fédération

1. Quel camp (bâtonnets ou crottes) joue en premier ? Y a-t-il un tirage au sort ?
2. La « rencontre » est-elle obligatoire, en compétition comme en partie libre ?
3. Soufflé : qui choisit la pièce retirée ? Le coup fautif est-il maintenu ?
   Le soufflé compte-t-il comme un coup ? S'applique-t-il en compétition ?
4. Un Sultan compte-t-il plus qu'un pion dans la prise majoritaire ?
5. Le Sultan peut-il faire demi-tour au cours d'une rafle ?
6. Le Sultan peut-il s'arrêter n'importe où derrière la pièce prise ?
7. Comment se termine une partie qui n'avance plus (Sultans contre Sultans) ?
8. Existe-t-il un règlement écrit de la Fédération mauritanienne de Dhamet ?
9. Sens exact de السله et لكريف.

## 15. Sources

Consultées en ligne le 30/09/2026.

- **[S1]** « Strand ou Dhamet », jeuxstrategieter.free.fr —
  <http://jeuxstrategieter.free.fr/Strand_complet.php>. Règle complète avec
  exemples, soufflé et ouverture « rencontre ». La source la plus détaillée.
- **[S2]** « Dhamet », Wikipédia (fr) — <https://fr.wikipedia.org/wiki/Dhamet>.
  Cite : Abdallahi Ol Bah, « Les dames du désert », *Jeux et Stratégie*
  n° 27, juin-juillet 1984, p. 46-48 ; Jean-Manuel Mascort, *Les Jeux du
  Sahara*, 2021, p. 56-59.
- **[S3]** « Zamma », Wikipedia (en) — <https://en.wikipedia.org/wiki/Zamma>.
  Largement fondé sur [S4].
- **[S4]** Mats Winther, « Zamma – an archaic game from Africa » —
  <https://mats-winther.github.io/bg/zamma.htm>. Bibliographie : Alemanni,
  *Les Jeux de Dames dans le Monde* (2005) ; Ould Hamidoun, *Précis sur la
  Mauritanie*, IFAN (1952) ; Ol Bah (1984) ; Pennick, *Games of the Gods*
  (1988).
- **[S5]** « Zamma », mindsports.nl —
  <https://www.mindsports.nl/index.php/on-the-evolution-of-draughts-variants/draughts-variants/505-zamma>.
  Aucune source citée.
- **[S6]** J. P. Neto, *World of Abstract Games*, « Alquerque » —
  <https://jpneto.github.io/world_abstract_games/alquerque.htm>. Reprend [S4].
- **[S7]** Noonpost (ar), « موريتانيا.. ألعاب شعبية تأبى الاندثار » —
  <https://www.noonpost.com/26480/>. Terminologie hassaniya, disposition de la
  5ᵉ rangée, prise dans toutes les directions.
- **[S8]** Al-Araby Al-Jadeed (ar), « لعبة "ظامت"... ترفيه تقليدي » —
  <https://www.alaraby.co.uk/>. Interdiction du déplacement latéral et du
  recul, format en trois manches.
- **[S9]** Sky News Arabia (ar), « لعبة "ظامت".. الحرب الرمزية » —
  <https://www.skynewsarabia.com/varieties/1392656>. Fédération mauritanienne
  de Dhamet, Coupe de l'indépendance (28 novembre).

**Indépendance des sources.** [S3] et [S6] dérivent de [S4]. [S1] et [S2]
relèvent de la tradition française, peut-être issue de l'article d'Ol Bah
(1984). Une règle est donc dite CONFIRMED quand elle apparaît au moins dans
la lignée française ([S1] ou [S2]) **et** dans la lignée de Winther ([S4]),
ou dans une source arabe ([S7] à [S9]).

**Sources primaires non consultées, à obtenir :** l'article d'Ol Bah (1984),
le livre de Mascort (2021), Ould Hamidoun (1952), Alemanni (2005) et surtout
un éventuel **règlement écrit de la Fédération mauritanienne de Dhamet**.
