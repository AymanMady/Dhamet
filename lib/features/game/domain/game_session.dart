import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/foundation.dart';

import 'board_interaction.dart';
import 'game_mode.dart';

/// A game being played in the app: the engine [game] plus what the user
/// interface needs around it (mode, selection, AI activity).
@immutable
class GameSession {
  const GameSession({
    required this.id,
    required this.mode,
    required this.game,
    required this.startedAt,
    this.selected,
    this.pendingChoices = const [],
    this.aiThinking = false,
    this.lastAiDuration,
  });

  final String id;
  final GameMode mode;
  final Game game;
  final DateTime startedAt;

  /// The piece the user has selected, if any.
  final Position? selected;

  /// Several capture sequences share the chosen destination: the user must
  /// pick one.
  final List<Move> pendingChoices;

  final bool aiThinking;

  /// Time the AI took for its last move (developer mode).
  final Duration? lastAiDuration;

  GameState get state => game.state;

  bool get isOver => game.isOver;

  GameResult? get result => game.result;

  /// The side the user plays against the computer, `null` in local games
  /// where both sides are human.
  Player? get humanSide => switch (mode) {
    AiMode(:final humanSide) => humanSide,
    LocalMode() => null,
  };

  /// Whether the side to move is played by a person on this device.
  bool get isHumanTurn =>
      !isOver && (humanSide == null || state.currentPlayer == humanSide);

  /// Pieces that may move now.
  Set<Position> get movablePieces => {
    if (isHumanTurn && !aiThinking)
      for (final move in state.legalMoves) move.from,
  };

  /// Legal moves of the selected piece, one per distinct outcome.
  List<Move> get selectedMoves => selected == null
      ? const []
      : distinctOutcomes(state.legalMovesFrom(selected!));

  GameSession copyWith({
    Game? game,
    Position? Function()? selected,
    List<Move>? pendingChoices,
    bool? aiThinking,
    Duration? Function()? lastAiDuration,
  }) => GameSession(
    id: id,
    mode: mode,
    game: game ?? this.game,
    startedAt: startedAt,
    selected: selected == null ? this.selected : selected(),
    pendingChoices: pendingChoices ?? this.pendingChoices,
    aiThinking: aiThinking ?? this.aiThinking,
    lastAiDuration: lastAiDuration == null
        ? this.lastAiDuration
        : lastAiDuration(),
  );
}
