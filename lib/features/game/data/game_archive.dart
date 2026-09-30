import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'saved_game.dart';

/// Where games are kept on the device: the unfinished game to resume, and
/// the finished games for the history and statistics.
abstract interface class GameArchive {
  Future<SavedGame?> loadCurrent();

  Future<void> saveCurrent(SavedGame game);

  Future<void> clearCurrent();

  Future<void> addFinished(SavedGame game);

  /// Finished games, most recent first.
  Future<List<SavedGame>> finishedGames();

  Future<SavedGame?> finishedGame(String id);

  Future<void> deleteFinished(String id);
}

/// Keeps games in memory only (tests, or before storage is available).
class InMemoryGameArchive implements GameArchive {
  SavedGame? _current;
  final List<SavedGame> _finished = [];

  @override
  Future<SavedGame?> loadCurrent() async => _current;

  @override
  Future<void> saveCurrent(SavedGame game) async => _current = game;

  @override
  Future<void> clearCurrent() async => _current = null;

  @override
  Future<void> addFinished(SavedGame game) async {
    _finished
      ..removeWhere((saved) => saved.id == game.id)
      ..insert(0, game);
  }

  @override
  Future<List<SavedGame>> finishedGames() async => List.unmodifiable(_finished);

  @override
  Future<SavedGame?> finishedGame(String id) async {
    for (final game in _finished) {
      if (game.id == id) return game;
    }
    return null;
  }

  @override
  Future<void> deleteFinished(String id) async =>
      _finished.removeWhere((game) => game.id == id);
}

final gameArchiveProvider = Provider<GameArchive>(
  (ref) => InMemoryGameArchive(),
);
