/// The playing strength offered to players.
enum AiDifficulty { easy, medium, hard, expert }

/// How much the AI searches and how much it varies its play.
///
/// The search stops at [maxDepth] plies or when [timeLimit] is reached,
/// whichever comes first. On a slow device the time limit wins: the AI
/// answers just as fast but searches less deeply.
final class AiConfig {
  const AiConfig({
    required this.maxDepth,
    required this.timeLimit,
    this.randomness = 0,
    this.quiescenceDepth = defaultQuiescenceDepth,
  }) : assert(
         maxDepth >= 1 && maxDepth <= maxSupportedDepth,
         'maxDepth must be between 1 and $maxSupportedDepth',
       ),
       assert(randomness >= 0, 'randomness must not be negative'),
       assert(
         quiescenceDepth >= 0 && quiescenceDepth <= maxSupportedDepth,
         'quiescenceDepth must be between 0 and $maxSupportedDepth',
       );

  /// The preset for [difficulty]: [easy], [medium], [hard] or [expert].
  factory AiConfig.forDifficulty(AiDifficulty difficulty) =>
      switch (difficulty) {
        AiDifficulty.easy => easy,
        AiDifficulty.medium => medium,
        AiDifficulty.hard => hard,
        AiDifficulty.expert => expert,
      };

  // The reasons for the preset values are given in the package README.

  /// Shallow search and wide randomness: often gives away material.
  static const AiConfig easy = AiConfig(
    maxDepth: 1,
    quiescenceDepth: 2,
    timeLimit: Duration(milliseconds: 250),
    randomness: 1.5,
  );

  /// Sees simple tactics; varies its play among nearly equal moves.
  static const AiConfig medium = AiConfig(
    maxDepth: 3,
    quiescenceDepth: 6,
    timeLimit: Duration(milliseconds: 700),
    randomness: 0.4,
  );

  /// Deep search, only varies between practically equal moves.
  static const AiConfig hard = AiConfig(
    maxDepth: 6,
    quiescenceDepth: 10,
    timeLimit: Duration(milliseconds: 1800),
    randomness: 0.05,
  );

  /// Deepest search and longest thinking time, no randomness.
  static const AiConfig expert = AiConfig(
    maxDepth: 16,
    quiescenceDepth: 16,
    timeLimit: Duration(milliseconds: 3500),
  );

  /// Largest accepted [maxDepth] and [quiescenceDepth].
  static const int maxSupportedDepth = 48;

  static const int defaultQuiescenceDepth = 8;

  /// Maximum number of full-width plies.
  final int maxDepth;

  /// Hard budget for one move, measured from the start of the search.
  final Duration timeLimit;

  /// 0 always plays the best move found. Otherwise the AI picks at random
  /// among the moves scoring at most `randomness` pawns (of 100 points)
  /// below the best one, so a higher value gives weaker, more varied play.
  /// A forced win is always played.
  final double randomness;

  /// Maximum number of extra plies searched, beyond [maxDepth], while the
  /// side to move is forced to capture.
  final int quiescenceDepth;

  /// A copy of this configuration with the given fields replaced.
  AiConfig copyWith({
    int? maxDepth,
    Duration? timeLimit,
    double? randomness,
    int? quiescenceDepth,
  }) => AiConfig(
    maxDepth: maxDepth ?? this.maxDepth,
    timeLimit: timeLimit ?? this.timeLimit,
    randomness: randomness ?? this.randomness,
    quiescenceDepth: quiescenceDepth ?? this.quiescenceDepth,
  );

  @override
  bool operator ==(Object other) =>
      other is AiConfig &&
      other.maxDepth == maxDepth &&
      other.timeLimit == timeLimit &&
      other.randomness == randomness &&
      other.quiescenceDepth == quiescenceDepth;

  @override
  int get hashCode =>
      Object.hash(maxDepth, timeLimit, randomness, quiescenceDepth);

  @override
  String toString() =>
      'AiConfig(maxDepth: $maxDepth, quiescenceDepth: $quiescenceDepth, '
      'timeLimit: ${timeLimit.inMilliseconds} ms, randomness: $randomness)';
}
