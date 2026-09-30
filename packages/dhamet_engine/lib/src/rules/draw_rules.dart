import '../serialization/json_reader.dart';

/// Draw rules (`end.draw`, NEEDS_VERIFICATION). See docs/rules.md § 12.
///
/// No draw rule is confirmed for Dhamet. mindsports.nl alone mentions
/// "mutual agreement or 3-fold" repetition, without citing a source. Both
/// are therefore **disabled by default** and only available as options.
final class DrawRules {
  const DrawRules({this.byAgreement = false, this.repetitionLimit})
    : assert(
        repetitionLimit == null || repetitionLimit >= 2,
        'A position must occur at least twice to be repeated',
      );

  /// No draw: a game only ends by elimination, blocking or a declared
  /// result (resignation, timeout).
  static const DrawRules none = DrawRules();

  /// Whether both players may agree to a draw.
  final bool byAgreement;

  /// The game is drawn when the same position (same board, same side to
  /// move) occurs this many times; `null` disables it. The only source
  /// mentioning it says 3.
  final int? repetitionLimit;

  bool get isEnabled => byAgreement || repetitionLimit != null;

  Map<String, Object?> toJson() => {
    'byAgreement': byAgreement,
    'repetitionLimit': repetitionLimit,
  };

  static DrawRules fromJson(Object? json) {
    final map = readMap(json, 'draw');
    final limit = map['repetitionLimit'];
    if (limit != null && (limit is! int || limit < 2)) {
      throw FormatException(
        'draw.repetitionLimit: expected null or >= 2',
        limit,
      );
    }
    return DrawRules(
      byAgreement: readOptional(map, 'byAgreement', 'draw', false),
      repetitionLimit: limit as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DrawRules &&
      other.byAgreement == byAgreement &&
      other.repetitionLimit == repetitionLimit;

  @override
  int get hashCode => Object.hash(byAgreement, repetitionLimit);

  @override
  String toString() =>
      'DrawRules(byAgreement: $byAgreement, repetitionLimit: $repetitionLimit)';
}
