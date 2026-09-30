import 'dart:collection';

import '../moves/move.dart';
import '../pieces/piece.dart';
import '../serialization/json_reader.dart';
import '../state/game_state.dart';
import 'move_record.dart';

/// The moves of a game from its initial state, with an undo/redo cursor.
///
/// Immutable: [play], [undo] and [redo] return a new history. Undo and redo
/// only move the cursor between recorded states, so they are exact. Playing
/// a move after an undo discards the undone moves.
///
/// Whether undo is *allowed* (local games only) is decided by `Game`.
final class GameHistory {
  GameHistory._(this.initialState, List<MoveRecord> records, this._cursor)
    : _records = List.unmodifiable(records);

  /// An empty history starting at [initialState].
  GameHistory.start(GameState initialState) : this._(initialState, const [], 0);

  /// Reads [toJson] output.
  ///
  /// The moves are replayed from the initial state and checked: an illegal
  /// move, or captured pieces that do not match the replay, raise a
  /// [FormatException].
  factory GameHistory.fromJson(Object? json) {
    final map = readMap(json, 'history');
    final initialState = GameState.fromJson(map['initialState']);
    final entries = readList(map['moves'], 'history.moves');
    final records = <MoveRecord>[];
    var state = initialState;
    for (var i = 0; i < entries.length; i++) {
      final entry = readMap(entries[i], 'history.moves[$i]');
      final move = Move.fromJson(entry['move']);
      if (!state.isLegal(move)) {
        throw FormatException('history.moves[$i]: $move is not legal', entry);
      }
      final timestamp = entry['timestamp'];
      if (timestamp != null && timestamp is! String) {
        throw FormatException('history.moves[$i].timestamp', timestamp);
      }
      final record = MoveRecord.play(
        state,
        move,
        timestamp: timestamp == null
            ? null
            : DateTime.parse(timestamp as String),
      );
      final saved = [
        for (final piece in readList(
          entry['capturedPieces'] ?? const [],
          'history.moves[$i].capturedPieces',
        ))
          Piece.fromJson(piece),
      ];
      if (!_samePieces(saved, record.capturedPieces)) {
        throw FormatException(
          'history.moves[$i]: captured pieces do not match the replay',
          entry,
        );
      }
      records.add(record);
      state = record.stateAfter;
    }
    final cursor = readField<int>(map, 'cursor', 'history');
    if (cursor < 0 || cursor > records.length) {
      throw FormatException('history.cursor: out of range', cursor);
    }
    return GameHistory._(initialState, records, cursor);
  }

  /// The state before the first move.
  final GameState initialState;

  final List<MoveRecord> _records;
  final int _cursor;

  /// The moves currently played, oldest first.
  List<MoveRecord> get playedMoves =>
      UnmodifiableListView(_records.sublist(0, _cursor));

  /// The moves taken back and available for redo, in playing order.
  List<MoveRecord> get undoneMoves =>
      UnmodifiableListView(_records.sublist(_cursor));

  /// The last move played, if any.
  MoveRecord? get lastRecord => _cursor == 0 ? null : _records[_cursor - 1];

  /// The current state.
  GameState get currentState => lastRecord?.stateAfter ?? initialState;

  /// Every state from the initial one to the current one.
  List<GameState> get states => UnmodifiableListView([
    initialState,
    for (final record in playedMoves) record.stateAfter,
  ]);

  bool get canUndo => _cursor > 0;

  bool get canRedo => _cursor < _records.length;

  /// The history after playing [move] in [currentState].
  ///
  /// Throws an `IllegalMoveException` if [move] is not legal. Discards the
  /// moves available for redo.
  GameHistory play(Move move, {DateTime? timestamp}) {
    final record = MoveRecord.play(currentState, move, timestamp: timestamp);
    return GameHistory._(initialState, [...playedMoves, record], _cursor + 1);
  }

  /// The history with the last move taken back. Throws a [StateError] if no
  /// move has been played.
  GameHistory undo() {
    if (!canUndo) throw StateError('There is no move to undo');
    return GameHistory._(initialState, _records, _cursor - 1);
  }

  /// The history with the last undone move played again. Throws a
  /// [StateError] if there is nothing to redo.
  GameHistory redo() {
    if (!canRedo) throw StateError('There is no move to redo');
    return GameHistory._(initialState, _records, _cursor + 1);
  }

  /// JSON representation, including the moves available for redo.
  Map<String, Object?> toJson() => {
    'initialState': initialState.toJson(),
    'moves': [for (final record in _records) record.toJson()],
    'cursor': _cursor,
  };

  static bool _samePieces(List<Piece> a, List<Piece> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
