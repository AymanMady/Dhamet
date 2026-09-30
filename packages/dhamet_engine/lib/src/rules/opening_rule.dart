/// How the game opens (`opening.rencontre`, VARIANT). See docs/rules.md § 11.
enum OpeningRule {
  /// Any legal move from the start. The default.
  free,

  /// The first five moves of each side follow the traditional "rencontre"
  /// (see `TraditionalEncounter`). fr.wikipedia says they are "fixed by
  /// rule", while the most detailed French source calls them a mere
  /// convention: never imposed by default.
  traditionalEncounter,
}
