import 'dart:io';

import 'package:dhamet/features/game/data/file_game_archive.dart';
import 'package:dhamet/features/game/data/saved_game.dart';
import 'package:dhamet/features/game/domain/game_mode.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_test/flutter_test.dart';

SavedGame game(String id, {DateTime? finishedAt, int plies = 0}) {
  var engine = Game.start(undoPolicy: UndoPolicy.unlimited);
  for (var i = 0; i < plies; i++) {
    engine = engine.play(engine.state.legalMoves.first);
  }
  return SavedGame(
    id: id,
    mode: const AiMode(level: AiLevel.hard, humanSide: Player.black),
    game: engine,
    startedAt: DateTime.utc(2026, 9, 30, 10),
    finishedAt: finishedAt,
  );
}

void main() {
  late Directory directory;
  late FileGameArchive archive;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('dhamet_archive_');
    archive = FileGameArchive(directory);
  });
  tearDown(() => directory.deleteSync(recursive: true));

  test('the unfinished game survives a restart', () async {
    await archive.saveCurrent(game('current-1', plies: 3));
    final reopened = FileGameArchive(directory);
    final loaded = await reopened.loadCurrent();
    expect(loaded!.id, 'current-1');
    expect(
      loaded.mode,
      const AiMode(level: AiLevel.hard, humanSide: Player.black),
    );
    expect(loaded.game.state.plyCount, 3);
    expect(loaded.game.canUndo, isTrue);
    await reopened.clearCurrent();
    expect(await reopened.loadCurrent(), isNull);
  });

  test('finished games are listed most recent first', () async {
    await archive.addFinished(
      game('old', finishedAt: DateTime.utc(2026, 9, 1)),
    );
    await archive.addFinished(
      game('new', finishedAt: DateTime.utc(2026, 9, 30)),
    );
    final games = await archive.finishedGames();
    expect(games.map((g) => g.id), ['new', 'old']);
    expect((await archive.finishedGame('old'))!.id, 'old');
    await archive.deleteFinished('old');
    expect((await archive.finishedGames()).map((g) => g.id), ['new']);
    expect(await archive.finishedGame('old'), isNull);
  });

  test('an unreadable file is set aside instead of breaking the app', () async {
    File('${directory.path}/current_game.json').writeAsStringSync('{broken');
    expect(await archive.loadCurrent(), isNull);
    expect(
      File('${directory.path}/current_game.json.corrupt').existsSync(),
      isTrue,
    );

    Directory('${directory.path}/history').createSync();
    File('${directory.path}/history/bad.json').writeAsStringSync('{"id": 3}');
    await archive.addFinished(game('good', finishedAt: DateTime.utc(2026)));
    expect((await archive.finishedGames()).map((g) => g.id), ['good']);
  });

  test('writes are queued and atomic', () async {
    await Future.wait([
      for (var i = 0; i < 10; i++) archive.saveCurrent(game('g$i', plies: i)),
    ]);
    final loaded = await archive.loadCurrent();
    expect(loaded!.id, 'g9');
    expect(
      directory.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.tmp'),
      ),
      isEmpty,
    );
  });

  test('identifiers cannot escape the history folder', () {
    expect(() => archive.finishedGame('../current_game'), throwsArgumentError);
  });
}
