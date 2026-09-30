import '../serialization/json_reader.dart';

/// Whether moves may be taken back in a game.
///
/// Undo is for local games only: online and competitive games must use
/// [UndoPolicy.disabled], which is also the default of `Game.start`.
final class UndoPolicy {
  const UndoPolicy._(this.isEnabled, this.maxDepth);

  /// At most [maxDepth] moves may be taken back in a row.
  const UndoPolicy.limited(int this.maxDepth)
    : isEnabled = true,
      assert(maxDepth > 0, 'maxDepth must be positive');

  /// No undo, no redo.
  static const UndoPolicy disabled = UndoPolicy._(false, null);

  /// Any number of moves may be taken back.
  static const UndoPolicy unlimited = UndoPolicy._(true, null);

  final bool isEnabled;

  /// Maximum number of moves taken back in a row, or `null` for no limit.
  final int? maxDepth;

  Map<String, Object?> toJson() => {'enabled': isEnabled, 'maxDepth': maxDepth};

  static UndoPolicy fromJson(Object? json) {
    final map = readMap(json, 'undoPolicy');
    final enabled = readField<bool>(map, 'enabled', 'undoPolicy');
    final maxDepth = map['maxDepth'];
    if (!enabled) return disabled;
    if (maxDepth == null) return unlimited;
    if (maxDepth is! int || maxDepth <= 0) {
      throw FormatException(
        'undoPolicy.maxDepth: expected a positive int',
        maxDepth,
      );
    }
    return UndoPolicy.limited(maxDepth);
  }

  @override
  bool operator ==(Object other) =>
      other is UndoPolicy &&
      other.isEnabled == isEnabled &&
      other.maxDepth == maxDepth;

  @override
  int get hashCode => Object.hash(isEnabled, maxDepth);

  @override
  String toString() => !isEnabled
      ? 'UndoPolicy.disabled'
      : maxDepth == null
      ? 'UndoPolicy.unlimited'
      : 'UndoPolicy.limited($maxDepth)';
}
