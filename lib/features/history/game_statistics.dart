import 'dart:math';

import '../game/data/saved_game.dart';
import '../game/domain/game_mode.dart';

/// Statistics over the finished games stored on the device.
///
/// Wins, losses, captures and Sultans are counted from the player's point
/// of view, so only in games against the AI; games played, draws and the
/// longest game include local games too.
class GameStatistics {
  const GameStatistics({
    this.gamesPlayed = 0,
    this.aiGames = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.piecesCaptured = 0,
    this.sultansCreated = 0,
    this.longestGame = 0,
  });

  factory GameStatistics.from(Iterable<SavedGame> games) {
    var played = 0, aiGames = 0, wins = 0, losses = 0, draws = 0;
    var captured = 0, sultans = 0, longest = 0;
    for (final saved in games) {
      final result = saved.game.result;
      if (result == null) continue;
      played++;
      longest = max(longest, saved.game.state.plyCount);
      if (result.isDraw) draws++;
      final mode = saved.mode;
      if (mode is! AiMode) continue;
      aiGames++;
      if (result.winner == mode.humanSide) wins++;
      if (result.loser == mode.humanSide) losses++;
      for (final record in saved.game.history.playedMoves) {
        if (record.player != mode.humanSide) continue;
        captured += record.capturedPieces.length;
        if (record.promoted) sultans++;
      }
    }
    return GameStatistics(
      gamesPlayed: played,
      aiGames: aiGames,
      wins: wins,
      losses: losses,
      draws: draws,
      piecesCaptured: captured,
      sultansCreated: sultans,
      longestGame: longest,
    );
  }

  final int gamesPlayed;
  final int aiGames;
  final int wins;
  final int losses;
  final int draws;
  final int piecesCaptured;
  final int sultansCreated;

  /// Number of moves (plies) of the longest game.
  final int longestGame;

  /// Share of games won against the AI, from 0 to 1.
  double get winRate => aiGames == 0 ? 0 : wins / aiGames;
}
