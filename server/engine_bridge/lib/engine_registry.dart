import 'dart:convert';

import 'package:dhamet_engine/dhamet_engine.dart';

/// Open games keyed by an id chosen by the caller, driven with JSON strings.
///
/// This is the whole API seen by the Node.js server. Keeping each [Game]
/// alive between calls avoids replaying its history (`Game.fromJson`) at
/// every move. Every answer is a JSON string; expected failures (illegal
/// move, game over, bad JSON) are returned as `{"ok": false, "error": …}`
/// rather than thrown, so that no Dart exception crosses into JavaScript.
///
/// Online games always use [UndoPolicy.disabled].
final class EngineRegistry {
  final Map<String, Game> _games = {};

  /// Number of open games.
  int get size => _games.length;

  /// Opens a new game under [id] with [DhametRules.standard], the rules of
  /// every online game.
  String create(String id) => _guard(() => _open(id, Game.start()));

  /// Opens a saved game (`Game.toJson` output) under [id], replaying and
  /// checking every move.
  String load(String id, String gameJson) => _guard(() {
    final game = Game.fromJson(jsonDecode(gameJson));
    if (game.undoPolicy.isEnabled) {
      throw const FormatException('online games must not allow undo');
    }
    return _open(id, game);
  });

  /// Plays [moveJson] (a `Move` JSON) at [timestamp] (ISO 8601).
  ///
  /// On success, `move` is the engine's own copy of the move: callers should
  /// broadcast it rather than the move they received.
  String play(String id, String moveJson, String timestamp) => _guard(() {
    final game = _game(id);
    final Move move;
    try {
      move = Move.fromJson(jsonDecode(moveJson));
    } on FormatException catch (e) {
      return _failure('ILLEGAL_MOVE', 'Malformed move: ${e.message}');
    }
    if (game.isOver) return _failure('GAME_OVER', 'The game is over');
    final index = game.state.legalMoves.indexOf(move);
    if (index < 0) {
      return _failure('ILLEGAL_MOVE', '$move is not a legal move');
    }
    final legal = game.state.legalMoves[index];
    final next = game.play(legal, timestamp: DateTime.parse(timestamp));
    _games[id] = next;
    return _success(next, extra: {'move': legal.toJson()});
  });

  /// [color] (`"white"` or `"black"`) resigns.
  String resign(String id, String color) =>
      _declare(id, (game) => game.resign(Player.fromJson(color)));

  /// [color] (`"white"` or `"black"`) loses on time.
  String loseOnTime(String id, String color) =>
      _declare(id, (game) => game.loseOnTime(Player.fromJson(color)));

  /// The current snapshot of game [id].
  String snapshot(String id) => _guard(() => _success(_game(id)));

  /// The legal moves of game [id], each as `{move, notation}`.
  String legalMoves(String id) => _guard(() {
    final game = _game(id);
    return jsonEncode({
      'ok': true,
      'moves': [
        for (final move in game.isOver ? const <Move>[] : game.state.legalMoves)
          {'move': move.toJson(), 'notation': move.notation},
      ],
    });
  });

  /// Forgets game [id]. Unknown ids are ignored.
  void close(String id) => _games.remove(id);

  String _open(String id, Game game) {
    if (_games.containsKey(id)) {
      return _failure('GAME_EXISTS', 'A game is already open under $id');
    }
    _games[id] = game;
    return _success(game);
  }

  String _declare(String id, Game Function(Game game) action) => _guard(() {
    final game = _game(id);
    if (game.isOver) return _failure('GAME_OVER', 'The game is over');
    final next = action(game);
    _games[id] = next;
    return _success(next);
  });

  Game _game(String id) {
    final game = _games[id];
    if (game == null) throw _UnknownGame(id);
    return game;
  }

  static String _guard(String Function() body) {
    try {
      return body();
    } on _UnknownGame catch (e) {
      return _failure('UNKNOWN_GAME', 'No open game under ${e.id}');
    } on FormatException catch (e) {
      return _failure('INVALID_JSON', e.message);
    }
  }

  static String _success(Game game, {Map<String, Object?> extra = const {}}) {
    final state = game.state;
    return jsonEncode({
      'ok': true,
      ...extra,
      'snapshot': {
        'currentPlayer': state.currentPlayer.toJson(),
        'plyCount': state.plyCount,
        'result': game.result?.toJson(),
        'pieceCounts': {
          for (final player in Player.values)
            player.toJson(): state.board.count(player),
        },
        'game': game.toJson(),
      },
    });
  }

  static String _failure(String code, String message) => jsonEncode({
    'ok': false,
    'error': {'code': code, 'message': message},
  });
}

final class _UnknownGame implements Exception {
  const _UnknownGame(this.id);

  final String id;
}
