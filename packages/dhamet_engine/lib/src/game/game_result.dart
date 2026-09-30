import '../pieces/player.dart';
import '../serialization/json_reader.dart';

/// Why a game ended.
enum GameEndReason {
  /// The loser has no piece left (`end.elimination`, CONFIRMED).
  elimination(isDraw: false, isDeclared: false),

  /// The loser has pieces but no legal move (`end.blocked`, CONFIRMED).
  blocked(isDraw: false, isDeclared: false),

  /// The same position occurred [DrawRules.repetitionLimit] times
  /// (`end.draw`, NEEDS_VERIFICATION, disabled by default).
  repetition(isDraw: true, isDeclared: false),

  /// Both players agreed to a draw (`end.draw`, NEEDS_VERIFICATION,
  /// disabled by default).
  agreement(isDraw: true, isDeclared: true),

  /// The loser resigned.
  resignation(isDraw: false, isDeclared: true),

  /// The loser ran out of time. Reserved for competitive games with a clock
  /// (an application rule: Dhamet has no traditional time limit).
  timeout(isDraw: false, isDeclared: true);

  const GameEndReason({required this.isDraw, required this.isDeclared});

  /// Whether this reason ends the game in a draw.
  final bool isDraw;

  /// Whether this end is declared by the players (or the clock) rather than
  /// read from the position by `GameEndDetector`.
  final bool isDeclared;
}

/// The outcome of a finished game.
final class GameResult {
  /// [winner] won for [reason].
  const GameResult.win(Player this.winner, this.reason)
    : assert(
        reason != GameEndReason.repetition && reason != GameEndReason.agreement,
        'Use GameResult.draw for a draw',
      );

  /// A draw for [reason].
  const GameResult.draw(this.reason)
    : winner = null,
      assert(
        reason == GameEndReason.repetition || reason == GameEndReason.agreement,
        'Use GameResult.win for a decisive result',
      );

  /// The winner, or `null` for a draw.
  final Player? winner;

  final GameEndReason reason;

  bool get isDraw => winner == null;

  /// The loser, or `null` for a draw.
  Player? get loser => winner?.opponent;

  Map<String, Object?> toJson() => {
    'winner': winner?.toJson(),
    'reason': reason.name,
  };

  static GameResult fromJson(Object? json) {
    final map = readMap(json, 'result');
    final reason = readEnum(
      GameEndReason.values,
      map['reason'],
      'result.reason',
    );
    final winner = map['winner'];
    if (reason.isDraw) {
      if (winner != null) {
        throw FormatException('result: a draw has no winner', json);
      }
      return GameResult.draw(reason);
    }
    return GameResult.win(Player.fromJson(winner), reason);
  }

  @override
  bool operator ==(Object other) =>
      other is GameResult && other.winner == winner && other.reason == reason;

  @override
  int get hashCode => Object.hash(winner, reason);

  @override
  String toString() => isDraw
      ? 'GameResult.draw(${reason.name})'
      : 'GameResult.win(${winner!.name}, ${reason.name})';
}
