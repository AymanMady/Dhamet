import 'dart:async';

import 'package:dhamet/features/ai/ai_player.dart';
import 'package:dhamet/features/game/data/game_archive.dart';
import 'package:dhamet/features/game/domain/game_mode.dart';
import 'package:dhamet/features/game/presentation/controllers/game_controller.dart';
import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

/// An AI whose answers are released by the test.
class ControlledAi implements AiPlayer {
  final requests = <Completer<Move>>[];
  final states = <GameState>[];

  @override
  Future<Move> chooseMove(GameState state, AiLevel level) {
    final completer = Completer<Move>();
    requests.add(completer);
    states.add(state);
    return completer.future;
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late ProviderContainer container;
  late GameController controller;
  late InMemoryGameArchive archive;

  Future<void> setUpContainer({AiPlayer? ai}) async {
    archive = InMemoryGameArchive();
    container = await testContainer(ai: ai, archive: archive);
    controller = container.read(gameControllerProvider.notifier);
  }

  group('local game', () {
    setUp(() => setUpContainer());

    test('starts from the traditional position', () {
      controller.startLocal();
      final session = container.read(gameControllerProvider)!;
      expect(session.mode, const LocalMode());
      expect(session.state.legalMoves, hasLength(3));
      expect(session.isHumanTurn, isTrue);
    });

    test('select then tap a destination plays the move', () {
      controller
        ..startLocal()
        ..tap(sq('d4'));
      expect(container.read(gameControllerProvider)!.selected, sq('d4'));
      controller.tap(sq('e5'));
      final session = container.read(gameControllerProvider)!;
      expect(session.state.lastMove!.notation, 'd4-e5');
      expect(session.state.currentPlayer, Player.black);
      expect(session.selected, isNull);
    });

    test('equivalent capture sequences need no choice', () {
      controller.startFrom(
        position({
          'c3': Piece.whitePawn,
          'c4': Piece.blackPawn,
          'd5': Piece.blackPawn,
          'e4': Piece.blackPawn,
          'd3': Piece.blackPawn,
        }),
      );
      controller.tap(sq('c3'));
      expect(
        container.read(gameControllerProvider)!.selectedMoves,
        hasLength(1),
      );
      controller.tap(sq('c3'));
      final session = container.read(gameControllerProvider)!;
      expect(session.pendingChoices, isEmpty);
      expect(session.state.plyCount, 1);
      expect(session.state.lastMove!.captureCount, 4);
    });

    test('a pending choice is played with choose', () {
      controller.startLocal();
      final session = container.read(gameControllerProvider)!;
      final moves = session.state.legalMoves;
      // Simulate two distinct options offered to the player.
      container.read(gameControllerProvider.notifier).state = session.copyWith(
        pendingChoices: moves.take(2).toList(),
      );
      controller.choose(moves[1]);
      expect(container.read(gameControllerProvider)!.state.lastMove, moves[1]);
      controller.choose(moves[0]);
      expect(
        container.read(gameControllerProvider)!.state.plyCount,
        1,
        reason: 'a move no longer offered is ignored',
      );
    });

    test('undo and redo one move at a time', () {
      controller
        ..startLocal()
        ..tap(sq('d4'))
        ..tap(sq('e5'))
        ..tap(sq('f6'))
        ..tap(sq('d4'));
      expect(container.read(gameControllerProvider)!.state.plyCount, 2);
      controller.undo();
      expect(container.read(gameControllerProvider)!.state.plyCount, 1);
      expect(controller.canRedo, isTrue);
      controller.redo();
      expect(container.read(gameControllerProvider)!.state.plyCount, 2);
    });

    test('a winning capture ends the game and archives it', () async {
      controller.startFrom(
        position({'e3': Piece.whitePawn, 'e4': Piece.blackPawn}),
      );
      controller
        ..tap(sq('e3'))
        ..tap(sq('e5'));
      await settle();
      final session = container.read(gameControllerProvider)!;
      expect(
        session.result,
        const GameResult.win(Player.white, GameEndReason.elimination),
      );
      expect(await archive.loadCurrent(), isNull);
      expect(await archive.finishedGames(), hasLength(1));
    });

    test('resigning gives the game to the opponent', () async {
      controller
        ..startLocal()
        ..resign();
      await settle();
      expect(
        container.read(gameControllerProvider)!.result,
        const GameResult.win(Player.black, GameEndReason.resignation),
      );
      expect(await archive.finishedGames(), hasLength(1));
    });

    test('the game in progress is saved after each move', () async {
      controller
        ..startLocal()
        ..tap(sq('d4'))
        ..tap(sq('e5'));
      await settle();
      final saved = await archive.loadCurrent();
      expect(saved!.id, container.read(gameControllerProvider)!.id);
      expect(saved.game.state.plyCount, 1);
    });

    test('restart keeps the mode and the starting position', () {
      final start = position({'e3': Piece.whitePawn, 'a9': Piece.blackPawn});
      controller
        ..startFrom(start)
        ..tap(sq('e3'))
        ..tap(sq('e4'));
      final firstId = container.read(gameControllerProvider)!.id;
      controller.restart();
      final session = container.read(gameControllerProvider)!;
      expect(session.id, isNot(firstId));
      expect(session.state.board, start.board);
    });
  });

  group('against the AI', () {
    test('the AI moves first when the player takes Black', () async {
      final ai = FirstMoveAi();
      await setUpContainer(ai: ai);
      controller.startAgainstAi(level: AiLevel.easy, humanSide: Player.black);
      await settle();
      final session = container.read(gameControllerProvider)!;
      expect(ai.calls, 1);
      expect(session.state.plyCount, 1);
      expect(session.state.currentPlayer, Player.black);
      expect(session.aiThinking, isFalse);
      expect(session.lastAiDuration, isNotNull);
    });

    test(
      'the AI replies to the player and undo returns to the player',
      () async {
        await setUpContainer(ai: FirstMoveAi());
        controller
          ..startAgainstAi(level: AiLevel.medium, humanSide: Player.white)
          ..tap(sq('d4'))
          ..tap(sq('e5'));
        await settle();
        var session = container.read(gameControllerProvider)!;
        expect(session.state.plyCount, 2);
        expect(session.state.lastMove!.notation, 'f6xd4');

        controller.undo();
        session = container.read(gameControllerProvider)!;
        expect(session.state.plyCount, 0);
        expect(session.isHumanTurn, isTrue);
      },
    );

    test('the player cannot move while the AI thinks', () async {
      final ai = ControlledAi();
      await setUpContainer(ai: ai);
      controller.startAgainstAi(level: AiLevel.hard, humanSide: Player.black);
      await settle();
      expect(container.read(gameControllerProvider)!.aiThinking, isTrue);
      controller.tap(sq('d6'));
      expect(container.read(gameControllerProvider)!.selected, isNull);
      ai.requests.single.complete(ai.states.single.legalMoves.first);
      await settle();
      expect(container.read(gameControllerProvider)!.aiThinking, isFalse);
    });

    test('an obsolete AI answer is ignored', () async {
      final ai = ControlledAi();
      await setUpContainer(ai: ai);
      controller.startAgainstAi(level: AiLevel.hard, humanSide: Player.black);
      await settle();
      controller.restart();
      await settle();
      expect(ai.requests, hasLength(2));
      ai.requests.first.complete(ai.states.first.legalMoves.first);
      await settle();
      expect(container.read(gameControllerProvider)!.state.plyCount, 0);
      ai.requests.last.complete(ai.states.last.legalMoves.last);
      await settle();
      expect(container.read(gameControllerProvider)!.state.plyCount, 1);
    });
  });
}
