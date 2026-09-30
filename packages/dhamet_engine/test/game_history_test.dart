import 'dart:math';

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('MoveRecord', () {
    test('records everything needed to replay or take back a move', () {
      final start = GameState.initial();
      final history = GameHistory.start(start)
          .play(start.legalMovesMatching('d4-e5').single)
          .play(
            start
                .play(start.legalMovesMatching('d4-e5').single)
                .legalMoves
                .single,
            timestamp: DateTime.utc(2026, 9, 30, 12),
          );
      final first = history.playedMoves[0];
      final second = history.playedMoves[1];

      expect(first.ply, 1);
      expect(first.moveNumber, 1);
      expect(first.player, Player.white);
      expect(first.from, sq('d4'));
      expect(first.to, sq('e5'));
      expect(first.piece, Piece.whitePawn);
      expect(first.capturedPositions, isEmpty);
      expect(first.capturedPieces, isEmpty);
      expect(first.promoted, isFalse);
      expect(first.timestamp, isNull);
      expect(first.stateBefore, same(start));

      expect(second.ply, 2);
      expect(second.moveNumber, 1);
      expect(second.player, Player.black);
      expect(second.move.notation, 'f6xd4');
      expect(second.capturedPositions, [sq('e5')]);
      expect(second.capturedPieces, [Piece.whitePawn]);
      expect(second.stateBefore, same(first.stateAfter));
      expect(second.stateAfter, same(history.currentState));
      expect(second.timestamp, DateTime.utc(2026, 9, 30, 12));
      expect(second.toString(), '2. f6xd4');
    });

    test('keeps the type of each captured piece', () {
      final state = stateWith({
        'e5': Piece.whitePawn,
        'd5': Piece.blackSultan,
        'b5': Piece.blackPawn,
      });
      final record = MoveRecord.play(state, state.legalMoves.single);
      expect(record.capturedPositions, [sq('d5'), sq('b5')]);
      expect(record.capturedPieces, [Piece.blackSultan, Piece.blackPawn]);
    });

    test('timestamps are stored in UTC', () {
      final local = DateTime(2026, 9, 30, 12, 30);
      final state = GameState.initial();
      final record = MoveRecord.play(
        state,
        state.legalMoves.first,
        timestamp: local,
      );
      expect(record.timestamp!.isUtc, isTrue);
      expect(record.timestamp, local.toUtc());
    });

    test('move numbers count one move of each side', () {
      final game = playAll(
        localGame(),
        TraditionalEncounter.whiteFirst.sublist(0, 5),
      );
      expect(game.history.playedMoves.map((r) => (r.ply, r.moveNumber)), [
        (1, 1),
        (2, 1),
        (3, 2),
        (4, 2),
        (5, 3),
      ]);
    });

    test('an illegal move is refused and nothing is recorded', () {
      final start = GameState.initial();
      final history = GameHistory.start(start);
      expect(
        () => history.play(
          Move(piece: Piece.whitePawn, from: sq('e3'), path: [sq('e5')]),
        ),
        throwsA(isA<IllegalMoveException>()),
      );
      expect(history.playedMoves, isEmpty);
      expect(history.currentState, same(start));
    });
  });

  group('GameHistory', () {
    final start = GameState.initial();

    test('starts empty', () {
      final history = GameHistory.start(start);
      expect(history.currentState, same(start));
      expect(history.playedMoves, isEmpty);
      expect(history.undoneMoves, isEmpty);
      expect(history.lastRecord, isNull);
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.states, [start]);
      expect(history.undo, throwsStateError);
      expect(history.redo, throwsStateError);
    });

    test('undo and redo restore the exact recorded states', () {
      var history = GameHistory.start(start);
      for (final notation in TraditionalEncounter.whiteFirst.sublist(0, 4)) {
        history = history.play(
          history.currentState.legalMovesMatching(notation).single,
        );
      }
      final states = history.states;
      expect(states, hasLength(5));

      var undone = history;
      for (var i = 3; i >= 0; i--) {
        undone = undone.undo();
        expect(undone.currentState, same(states[i]));
      }
      expect(undone.canUndo, isFalse);
      expect(undone.undoneMoves, hasLength(4));

      var redone = undone;
      for (var i = 1; i <= 4; i++) {
        redone = redone.redo();
        expect(redone.currentState, same(states[i]));
      }
      expect(redone.canRedo, isFalse);
    });

    test('a new move after undo discards the undone moves', () {
      var history = GameHistory.start(start);
      history = history.play(start.legalMovesMatching('d4-e5').single);
      history = history.play(history.currentState.legalMoves.single);
      history = history.undo().undo();
      expect(history.undoneMoves, hasLength(2));

      history = history.play(start.legalMovesMatching('f4-e5').single);
      expect(history.canRedo, isFalse);
      expect(history.undoneMoves, isEmpty);
      expect(history.playedMoves.single.move.notation, 'f4-e5');
      expect(history.redo, throwsStateError);
    });

    test('histories are immutable', () {
      final empty = GameHistory.start(start);
      final one = empty.play(start.legalMoves.first);
      one.undo();
      expect(empty.playedMoves, isEmpty);
      expect(one.playedMoves, hasLength(1));
      expect(
        () => one.playedMoves.add(one.lastRecord!),
        throwsUnsupportedError,
      );
    });
  });

  group('undo regression', () {
    GameState afterUndo(GameState start, String notation) {
      final game = playAll(localGame(state: start), [notation]);
      final undone = game.undo();
      expect(undone.state, same(start));
      expect(undone.redo().state, same(game.state));
      return undone.state;
    }

    test('after a capture', () {
      final start = playAll(localGame(), ['d4-e5']).state;
      final restored = afterUndo(start, 'f6xd4');
      expect(restored.board[sq('e5')], Piece.whitePawn);
      expect(restored.board[sq('f6')], Piece.blackPawn);
      expect(restored.board.isEmpty(sq('d4')), isTrue);
      expect(restored.currentPlayer, Player.black);
    });

    test('after a rafle', () {
      final start = stateWith({
        'e5': Piece.whitePawn,
        'd5': Piece.blackPawn,
        'b5': Piece.blackSultan,
      });
      final restored = afterUndo(start, 'e5xa5');
      expect(restored.board.pieces, {
        sq('e5'): Piece.whitePawn,
        sq('d5'): Piece.blackPawn,
        sq('b5'): Piece.blackSultan,
      });
    });

    test('after a promotion', () {
      final start = stateWith({'d8': Piece.whitePawn, 'a9': Piece.blackPawn});
      final game = playAll(localGame(state: start), ['d8-d9']);
      expect(game.state.board[sq('d9')], Piece.whiteSultan);
      final restored = afterUndo(start, 'd8-d9');
      expect(restored.board[sq('d8')], Piece.whitePawn);
      expect(restored.board.count(Player.white, type: PieceType.sultan), 0);
    });

    test('after a rafle ending in promotion (French source rafle)', () {
      final start = stateFrom('''
        9  . . . . . . . . .
        8  . . . b . . . . .
        7  . . . . . . w . .
        6  . . . . . b . b .
        5  . . . . . . . . .
        4  . . . . . . b b .
        3  . . . . . . . . .
        2  . . . . . . . . .
        1  . . . . . . . . .
           a b c d e f g h i
      ''');
      final restored = afterUndo(start, 'g7xi5xg3xg5xe7xc9');
      expect(restored.board, start.board);
      expect(restored.board.count(Player.black), 5);
    });

    test('after a Sultan move', () {
      final start = stateWith({'e5': Piece.whiteSultan, 'a9': Piece.blackPawn});
      final restored = afterUndo(start, 'e5-a1');
      expect(restored.board[sq('e5')], Piece.whiteSultan);
      expect(restored.board.isEmpty(sq('a1')), isTrue);
    });

    test('after a Sultan rafle ending on a captured piece intersection', () {
      // With immediate removal the Sultan may end where it took a piece.
      final start = stateWith({
        'e5': Piece.whiteSultan,
        'e4': Piece.blackPawn,
        'c2': Piece.blackPawn,
        'a3': Piece.blackPawn,
        'g4': Piece.blackPawn,
      });
      final restored = afterUndo(start, 'e5xe2xa2xa4xh4');
      expect(restored.board, start.board);
    });

    test('undo then a different move', () {
      final game = playAll(localGame(), ['d4-e5', 'f6xd4']);
      final other = game.undo().undo();
      final replayed = playAll(other, ['e4-e5']);
      expect(replayed.canRedo, isFalse);
      expect(replayed.history.playedMoves.single.move.notation, 'e4-e5');
      expect(replayed.state.board[sq('e5')], Piece.whitePawn);
      expect(replayed.state.board[sq('e4')], isNull);
    });
  });

  test('random play, undo and redo always match a reference model', () {
    for (var seed = 0; seed < 20; seed++) {
      final random = Random(seed);
      var game = localGame();
      // Reference: every state from the start, and the cursor.
      final model = <GameState>[game.state];
      var cursor = 0;
      for (var step = 0; step < 200; step++) {
        final roll = random.nextInt(10);
        if (roll < 2 && game.canUndo) {
          game = game.undo();
          cursor--;
        } else if (roll < 4 && game.canRedo) {
          game = game.redo();
          cursor++;
        } else if (!game.isOver) {
          final moves = game.state.legalMoves;
          game = game.play(moves[random.nextInt(moves.length)]);
          model
            ..removeRange(cursor + 1, model.length)
            ..add(game.state);
          cursor++;
        }
        expect(
          game.state,
          same(model[cursor]),
          reason: 'seed $seed step $step',
        );
        expect(game.canUndo, cursor > 0);
        expect(game.canRedo, cursor < model.length - 1);
        expect(game.history.states, model.sublist(0, cursor + 1));
      }
    }
  });
}
