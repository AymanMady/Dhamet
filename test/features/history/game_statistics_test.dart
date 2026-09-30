import 'package:dhamet/features/game/data/saved_game.dart';
import 'package:dhamet/features/game/domain/game_mode.dart';
import 'package:dhamet/features/history/game_statistics.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

SavedGame saved(GameMode mode, Game game) => SavedGame(
  id: '${game.hashCode}',
  mode: mode,
  game: game,
  startedAt: DateTime.utc(2026, 9, 30),
  finishedAt: DateTime.utc(2026, 9, 30, 1),
);

Game play(GameState start, List<String> moves) {
  var game = Game.start(initialState: start);
  for (final notation in moves) {
    game = game.play(game.state.legalMovesMatching(notation).single);
  }
  return game;
}

void main() {
  const human = AiMode(level: AiLevel.easy, humanSide: Player.white);

  test('counts wins, losses, captures and Sultans against the AI', () {
    // White takes two pieces, then promotes: a win for the player.
    final won = play(
      position({
        'e5': Piece.whitePawn,
        'd5': Piece.blackPawn,
        'b5': Piece.blackPawn,
      }),
      ['e5xa5'],
    );
    final lost = Game.start().resign(Player.white);
    final promoted = play(
      position({'d8': Piece.whitePawn, 'a3': Piece.blackPawn}),
      ['d8-d9'],
    ).resign(Player.black);

    final stats = GameStatistics.from([
      saved(human, won),
      saved(human, lost),
      saved(human, promoted),
    ]);
    expect(stats.gamesPlayed, 3);
    expect(stats.aiGames, 3);
    expect(stats.wins, 2);
    expect(stats.losses, 1);
    expect(stats.draws, 0);
    expect(stats.piecesCaptured, 2);
    expect(stats.sultansCreated, 1);
    expect(stats.winRate, closeTo(2 / 3, 1e-9));
    expect(stats.longestGame, 1);
  });

  test('local games count as played but not as wins or losses', () {
    final local = Game.start().resign(Player.black);
    final drawn = Game.start(
      rules: const DhametRules(draw: DrawRules(byAgreement: true)),
    ).agreeToDraw();
    final stats = GameStatistics.from([
      saved(const LocalMode(), local),
      saved(const LocalMode(), drawn),
    ]);
    expect(stats.gamesPlayed, 2);
    expect(stats.aiGames, 0);
    expect(stats.wins + stats.losses, 0);
    expect(stats.draws, 1);
    expect(stats.winRate, 0);
  });

  test('unfinished games are ignored', () {
    expect(GameStatistics.from([saved(human, Game.start())]).gamesPlayed, 0);
  });
}
