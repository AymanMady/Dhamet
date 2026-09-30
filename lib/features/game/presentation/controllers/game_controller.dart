import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/utils/ids.dart';
import '../../../ai/ai_player.dart';
import '../../data/game_archive.dart';
import '../../data/saved_game.dart';
import '../../domain/board_interaction.dart';
import '../../domain/game_mode.dart';
import '../../domain/game_session.dart';

final gameControllerProvider = NotifierProvider<GameController, GameSession?>(
  GameController.new,
);

/// Runs the game on this device: user input, computer moves, undo/redo and
/// saving. All rules are delegated to the engine.
class GameController extends Notifier<GameSession?> {
  /// Incremented whenever a pending computer move becomes obsolete.
  int _aiRequest = 0;

  @override
  GameSession? build() => null;

  void startLocal({DhametRules rules = DhametRules.standard}) =>
      _start(const LocalMode(), rules);

  void startAgainstAi({
    required AiLevel level,
    required Player humanSide,
    DhametRules rules = DhametRules.standard,
  }) => _start(AiMode(level: level, humanSide: humanSide), rules);

  /// A new game from [initialState], e.g. a set-up position.
  void startFrom(GameState initialState, {GameMode mode = const LocalMode()}) =>
      _start(mode, initialState.rules, initialState: initialState);

  /// A new game with the same mode and starting position.
  void restart() {
    final session = state;
    if (session != null) {
      _start(
        session.mode,
        session.game.rules,
        initialState: session.game.history.initialState,
      );
    }
  }

  /// Continues a saved, unfinished game.
  void resume(SavedGame saved) {
    _aiRequest++;
    state = saved.toSession();
    _scheduleAi();
  }

  /// Leaves the current game; it stays saved and can be resumed.
  void close() {
    _aiRequest++;
    state = null;
  }

  /// A tap on [position]: plays a highlighted destination, or selects or
  /// deselects a piece.
  void tap(Position position) {
    final session = state;
    if (session == null || !session.isHumanTurn || session.aiThinking) return;
    switch (resolveTap(session.state, session.selected, position)) {
      case PlayMove(:final move):
        _play(session, move);
      case ChooseMove(:final moves):
        state = session.copyWith(pendingChoices: moves);
      case SelectPiece(:final position):
        state = session.copyWith(
          selected: () => position,
          pendingChoices: const [],
        );
        ref.read(feedbackServiceProvider).play(FeedbackEvent.select);
      case ClearSelection():
        state = session.copyWith(
          selected: () => null,
          pendingChoices: const [],
        );
    }
  }

  /// Plays one of the capture sequences offered in
  /// [GameSession.pendingChoices].
  void choose(Move move) {
    final session = state;
    if (session == null || !session.pendingChoices.contains(move)) return;
    _play(session, move);
  }

  void cancelChoice() {
    final session = state;
    if (session != null) state = session.copyWith(pendingChoices: const []);
  }

  bool get canUndo {
    final session = state;
    return session != null && session.game.canUndo;
  }

  bool get canRedo {
    final session = state;
    return session != null && session.game.canRedo;
  }

  /// Takes back the last move; against the computer, takes back moves
  /// until it is the player's turn again.
  void undo() {
    final session = state;
    if (session == null || !session.game.canUndo) return;
    _aiRequest++;
    var game = session.game.undo();
    final human = session.humanSide;
    while (human != null && game.canUndo && game.state.currentPlayer != human) {
      game = game.undo();
    }
    if (session.isOver) {
      ref.read(gameArchiveProvider).deleteFinished(session.id);
    }
    _update(session, game, aiThinking: false);
    _save();
    _scheduleAi();
  }

  void redo() {
    final session = state;
    if (session == null || !session.game.canRedo) return;
    _aiRequest++;
    var game = session.game.redo();
    final human = session.humanSide;
    while (human != null && game.canRedo && game.state.currentPlayer != human) {
      game = game.redo();
    }
    _update(session, game, aiThinking: false);
    _afterMove();
  }

  /// The player (or, in a local game, the side to move) resigns.
  void resign() {
    final session = state;
    if (session == null || session.isOver) return;
    _aiRequest++;
    final loser = session.humanSide ?? session.state.currentPlayer;
    _update(session, session.game.resign(loser), aiThinking: false);
    _afterMove();
  }

  void _start(GameMode mode, DhametRules rules, {GameState? initialState}) {
    _aiRequest++;
    state = GameSession(
      id: newId(),
      mode: mode,
      game: Game.start(
        initialState: initialState,
        rules: rules,
        undoPolicy: UndoPolicy.unlimited,
      ),
      startedAt: DateTime.now(),
    );
    ref
        .read(analyticsServiceProvider)
        .gameStarted(mode: mode.id, difficulty: _difficulty(mode));
    _save();
    _scheduleAi();
  }

  void _play(GameSession session, Move move) {
    final game = session.game.play(move, timestamp: DateTime.now());
    _update(session, game);
    _feedbackFor(move);
    _afterMove();
  }

  void _update(GameSession session, Game game, {bool? aiThinking}) {
    state = session.copyWith(
      game: game,
      selected: () => null,
      pendingChoices: const [],
      aiThinking: aiThinking,
    );
  }

  void _afterMove() {
    final session = state;
    if (session == null) return;
    if (!session.isOver) {
      _save();
      _scheduleAi();
      return;
    }
    final archive = ref.read(gameArchiveProvider);
    archive.clearCurrent();
    archive.addFinished(
      SavedGame.fromSession(session, finishedAt: DateTime.now()),
    );
    final result = session.result!;
    final human = session.humanSide;
    ref
        .read(feedbackServiceProvider)
        .play(
          human != null && result.loser == human
              ? FeedbackEvent.defeat
              : FeedbackEvent.victory,
        );
    ref
        .read(analyticsServiceProvider)
        .gameFinished(
          mode: session.mode.id,
          duration: DateTime.now().difference(session.startedAt),
          result: result.isDraw ? 'draw' : result.reason.name,
          difficulty: _difficulty(session.mode),
        );
  }

  Future<void> _scheduleAi() async {
    final session = state;
    final mode = session?.mode;
    if (session == null ||
        session.isOver ||
        mode is! AiMode ||
        session.state.currentPlayer != mode.aiSide) {
      return;
    }
    final request = ++_aiRequest;
    state = session.copyWith(aiThinking: true);
    final stopwatch = Stopwatch()..start();
    final Move move;
    try {
      move = await ref
          .read(aiPlayerProvider)
          .chooseMove(session.state, mode.level);
    } catch (error, stack) {
      debugPrint('AI failed: $error\n$stack');
      if (ref.mounted && request == _aiRequest) {
        state = state?.copyWith(aiThinking: false);
      }
      return;
    }
    if (!ref.mounted || request != _aiRequest) return;
    final current = state;
    if (current == null || current.id != session.id) return;
    final game = current.game.play(move, timestamp: DateTime.now());
    state = current.copyWith(
      game: game,
      selected: () => null,
      pendingChoices: const [],
      aiThinking: false,
      lastAiDuration: () => stopwatch.elapsed,
    );
    _feedbackFor(move);
    _afterMove();
  }

  void _feedbackFor(Move move) {
    ref
        .read(feedbackServiceProvider)
        .play(
          move.promotes
              ? FeedbackEvent.promotion
              : move.isCapture
              ? FeedbackEvent.capture
              : FeedbackEvent.move,
        );
  }

  void _save() {
    final session = state;
    if (session != null && !session.isOver) {
      ref.read(gameArchiveProvider).saveCurrent(SavedGame.fromSession(session));
    }
  }

  static String? _difficulty(GameMode mode) =>
      mode is AiMode ? mode.level.name : null;
}
