import '../moves/move.dart';
import '../pieces/player.dart';
import '../rules/dhamet_rules.dart';
import '../serialization/json_reader.dart';
import '../state/game_state.dart';
import 'game_end_detector.dart';
import 'game_history.dart';
import 'game_result.dart';
import 'undo_policy.dart';

/// A game session: its history, its undo policy and its result.
///
/// Immutable: every action returns a new [Game]. This is the object the
/// application saves, restores and displays.
final class Game {
  Game._(this.history, this.undoPolicy, this.declaredResult);

  /// A new game from [initialState] (by default the traditional starting
  /// position under [rules]).
  ///
  /// Undo is disabled unless [undoPolicy] says otherwise: enable it for
  /// local games only.
  factory Game.start({
    GameState? initialState,
    DhametRules rules = DhametRules.standard,
    UndoPolicy undoPolicy = UndoPolicy.disabled,
  }) => Game._(
    GameHistory.start(initialState ?? GameState.initial(rules: rules)),
    undoPolicy,
    null,
  );

  /// Reads [toJson] output, replaying and checking every move.
  ///
  /// Throws a [FormatException] if [json] is not a valid saved game.
  factory Game.fromJson(Object? json) {
    final map = readMap(json, 'game');
    if (map['format'] != formatName) {
      throw FormatException(
        'game.format: expected "$formatName"',
        map['format'],
      );
    }
    final version = map['version'];
    if (version is! int || version < 1 || version > formatVersion) {
      throw FormatException(
        'game.version: supported versions are 1 to $formatVersion',
        version,
      );
    }
    final declared = map['declaredResult'] == null
        ? null
        : GameResult.fromJson(map['declaredResult']);
    if (declared != null && !declared.reason.isDeclared) {
      throw FormatException(
        'game.declaredResult: ${declared.reason.name} is read from the board',
        map['declaredResult'],
      );
    }
    return Game._(
      GameHistory.fromJson(map['history']),
      UndoPolicy.fromJson(map['undoPolicy']),
      declared,
    );
  }

  /// Identifies saved games.
  static const String formatName = 'dhamet.game';

  /// Current version of the saved-game format.
  static const int formatVersion = 1;

  final GameHistory history;

  final UndoPolicy undoPolicy;

  /// A result declared by the players or the clock (resignation, draw by
  /// agreement, timeout), if any.
  final GameResult? declaredResult;

  /// The current state.
  GameState get state => history.currentState;

  DhametRules get rules => history.initialState.rules;

  /// The result, or `null` while the game goes on.
  late final GameResult? result =
      declaredResult ??
      const GameEndDetector().detect(
        state,
        previousStates: [
          for (final record in history.playedMoves) record.stateBefore,
        ],
      );

  bool get isOver => result != null;

  /// The game after [move]. Throws a [StateError] if the game is over and an
  /// `IllegalMoveException` if [move] is not legal.
  Game play(Move move, {DateTime? timestamp}) {
    _ensureNotOver();
    return Game._(history.play(move, timestamp: timestamp), undoPolicy, null);
  }

  /// Whether [undo] is allowed now.
  ///
  /// It is not when undo is disabled, when no move was played, when
  /// [UndoPolicy.maxDepth] moves have already been taken back, or when the
  /// game ended by a declared result.
  bool get canUndo {
    if (!undoPolicy.isEnabled || declaredResult != null) return false;
    if (!history.canUndo) return false;
    final maxDepth = undoPolicy.maxDepth;
    return maxDepth == null || history.undoneMoves.length < maxDepth;
  }

  /// Whether [redo] is allowed now.
  bool get canRedo =>
      undoPolicy.isEnabled && declaredResult == null && history.canRedo;

  /// The game with the last move taken back. Undoing the move that ended the
  /// game (elimination, blocking) resumes it.
  ///
  /// Throws a [StateError] if [canUndo] is false.
  Game undo() {
    if (!canUndo) throw StateError('Undo is not allowed: ${_undoRefusal()}');
    return Game._(history.undo(), undoPolicy, null);
  }

  /// The game with the last undone move played again.
  ///
  /// Throws a [StateError] if [canRedo] is false.
  Game redo() {
    if (!canRedo) throw StateError('Redo is not allowed: ${_undoRefusal()}');
    return Game._(history.redo(), undoPolicy, null);
  }

  /// The game after [player] resigns: the opponent wins.
  Game resign(Player player) =>
      _declare(GameResult.win(player.opponent, GameEndReason.resignation));

  /// The game after [player] runs out of time: the opponent wins. For
  /// competitive games with a clock.
  Game loseOnTime(Player player) =>
      _declare(GameResult.win(player.opponent, GameEndReason.timeout));

  /// The game drawn by agreement. Throws a [StateError] unless
  /// [DhametRules.draw] allows it (disabled by default: `end.draw` is
  /// NEEDS_VERIFICATION).
  Game agreeToDraw() {
    if (!rules.draw.byAgreement) {
      throw StateError('Draw by agreement is disabled by the rules');
    }
    return _declare(const GameResult.draw(GameEndReason.agreement));
  }

  /// JSON representation, suitable to save an unfinished game.
  Map<String, Object?> toJson() => {
    'format': formatName,
    'version': formatVersion,
    'undoPolicy': undoPolicy.toJson(),
    'declaredResult': declaredResult?.toJson(),
    'history': history.toJson(),
  };

  Game _declare(GameResult result) {
    _ensureNotOver();
    return Game._(history, undoPolicy, result);
  }

  void _ensureNotOver() {
    if (isOver) throw StateError('The game is over: $result');
  }

  String _undoRefusal() {
    if (!undoPolicy.isEnabled) return 'undo is disabled for this game';
    if (declaredResult != null) return 'the game ended by $declaredResult';
    return 'no move available';
  }
}
