import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'game_archive.dart';
import 'saved_game.dart';

/// Stores games as JSON files on the device:
///
/// ```text
/// <directory>/current_game.json      the unfinished game
/// <directory>/history/<id>.json      one file per finished game
/// ```
///
/// Writes are atomic (temporary file then rename) and queued, so a crash
/// never leaves a half-written save. Unreadable files are set aside with a
/// `.corrupt` suffix instead of breaking the app.
class FileGameArchive implements GameArchive {
  FileGameArchive(this.directory);

  final Directory directory;

  Future<void> _queue = Future<void>.value();

  File get _currentFile => File('${directory.path}/current_game.json');

  Directory get _historyDirectory => Directory('${directory.path}/history');

  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  File _historyFile(String id) {
    if (!_safeId.hasMatch(id)) {
      throw ArgumentError.value(id, 'id', 'not a valid game identifier');
    }
    return File('${_historyDirectory.path}/$id.json');
  }

  /// Runs file operations one after the other.
  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _queue.then((_) => operation());
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  @override
  Future<SavedGame?> loadCurrent() => _serialized(() => _read(_currentFile));

  @override
  Future<void> saveCurrent(SavedGame game) =>
      _serialized(() => _write(_currentFile, game));

  @override
  Future<void> clearCurrent() => _serialized(() async {
    if (await _currentFile.exists()) await _currentFile.delete();
  });

  @override
  Future<void> addFinished(SavedGame game) =>
      _serialized(() => _write(_historyFile(game.id), game));

  @override
  Future<List<SavedGame>> finishedGames() => _serialized(() async {
    if (!await _historyDirectory.exists()) return const [];
    final games = <SavedGame>[];
    await for (final entity in _historyDirectory.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final game = await _read(entity);
        if (game != null) games.add(game);
      }
    }
    games.sort(
      (a, b) =>
          (b.finishedAt ?? b.startedAt).compareTo(a.finishedAt ?? a.startedAt),
    );
    return games;
  });

  @override
  Future<SavedGame?> finishedGame(String id) =>
      _serialized(() => _read(_historyFile(id)));

  @override
  Future<void> deleteFinished(String id) => _serialized(() async {
    final file = _historyFile(id);
    if (await file.exists()) await file.delete();
  });

  Future<SavedGame?> _read(File file) async {
    if (!await file.exists()) return null;
    try {
      return SavedGame.fromJson(jsonDecode(await file.readAsString()));
    } catch (error) {
      if (error is! FormatException &&
          error is! TypeError &&
          error is! ArgumentError) {
        rethrow;
      }
      debugPrint('Unreadable save ${file.path}: $error');
      await file.rename('${file.path}.corrupt');
      return null;
    }
  }

  Future<void> _write(File file, SavedGame game) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(game.toJson()), flush: true);
    await temporary.rename(file.path);
  }
}
