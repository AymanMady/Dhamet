import 'package:dhamet_engine/dhamet_engine.dart';

import '../domain/game_mode.dart';
import '../domain/game_session.dart';

/// A game as stored on the device: the engine game plus app metadata.
class SavedGame {
  const SavedGame({
    required this.id,
    required this.mode,
    required this.game,
    required this.startedAt,
    this.finishedAt,
  });

  factory SavedGame.fromSession(GameSession session, {DateTime? finishedAt}) =>
      SavedGame(
        id: session.id,
        mode: session.mode,
        game: session.game,
        startedAt: session.startedAt,
        finishedAt: finishedAt,
      );

  /// Throws a [FormatException] if [json] is not a valid saved game.
  factory SavedGame.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('savedGame: expected an object', json);
    }
    final id = json['id'];
    final startedAt = json['startedAt'];
    final finishedAt = json['finishedAt'];
    if (id is! String || startedAt is! String) {
      throw FormatException('savedGame: missing id or startedAt', json);
    }
    return SavedGame(
      id: id,
      mode: GameMode.fromJson(json['mode']),
      game: Game.fromJson(json['game']),
      startedAt: DateTime.parse(startedAt),
      finishedAt: finishedAt is String ? DateTime.parse(finishedAt) : null,
    );
  }

  final String id;
  final GameMode mode;
  final Game game;
  final DateTime startedAt;
  final DateTime? finishedAt;

  GameSession toSession() =>
      GameSession(id: id, mode: mode, game: game, startedAt: startedAt);

  Map<String, Object?> toJson() => {
    'id': id,
    'mode': mode.toJson(),
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt?.toUtc().toIso8601String(),
    'game': game.toJson(),
  };
}
