import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  const detector = GameEndDetector();

  group('elimination (end.elimination)', () {
    test('the side to move without pieces loses', () {
      final state = stateWith({'e5': Piece.whitePawn}, toMove: Player.black);
      expect(
        detector.detect(state),
        const GameResult.win(Player.white, GameEndReason.elimination),
      );
    });

    test('the side not to move without pieces loses', () {
      final state = stateWith({'e5': Piece.blackSultan}, toMove: Player.black);
      expect(
        detector.detect(state),
        const GameResult.win(Player.black, GameEndReason.elimination),
      );
    });

    test('capturing the last white piece makes Black win', () {
      final game = playAll(
        localGame(
          state: stateWith({
            'e5': Piece.blackPawn,
            'e4': Piece.whitePawn,
            'a9': Piece.blackPawn,
          }, toMove: Player.black),
        ),
        ['e5xe3'],
      );
      expect(
        game.result,
        const GameResult.win(Player.black, GameEndReason.elimination),
      );
      expect(game.result!.loser, Player.white);
      expect(game.isOver, isTrue);
    });

    test('a rafle taking the last pieces makes White win', () {
      final game = playAll(
        localGame(
          state: stateWith({
            'e5': Piece.whitePawn,
            'd5': Piece.blackPawn,
            'b5': Piece.blackSultan,
          }),
        ),
        ['e5xa5'],
      );
      expect(
        game.result,
        const GameResult.win(Player.white, GameEndReason.elimination),
      );
    });

    test('an empty board is not a valid game', () {
      expect(
        () => detector.detect(
          GameState(board: Board.empty(), currentPlayer: Player.white),
        ),
        throwsStateError,
      );
    });
  });

  group('blocking (end.blocked)', () {
    test('White with a pawn but no legal move loses', () {
      final state = stateWith({'e8': Piece.whitePawn, 'e9': Piece.blackPawn});
      expect(
        detector.detect(state),
        const GameResult.win(Player.black, GameEndReason.blocked),
      );
    });

    test('Black with a pawn but no legal move loses', () {
      final state = stateWith({
        'e2': Piece.blackPawn,
        'e1': Piece.whitePawn,
      }, toMove: Player.black);
      expect(
        detector.detect(state),
        const GameResult.win(Player.white, GameEndReason.blocked),
      );
    });

    test('several blocked pieces', () {
      final state = stateWith({
        'd8': Piece.whitePawn,
        'e8': Piece.whitePawn,
        'c9': Piece.blackPawn,
        'd9': Piece.blackPawn,
        'e9': Piece.blackPawn,
      });
      expect(state.board.count(Player.white), 2);
      expect(
        detector.detect(state),
        const GameResult.win(Player.black, GameEndReason.blocked),
      );
    });

    test('only the side to move is checked for blocking', () {
      // Black is blocked but it is White's turn, and White can move.
      final state = stateWith({
        'e2': Piece.blackPawn,
        'e1': Piece.whitePawn,
        'a5': Piece.whitePawn,
      });
      expect(detector.detect(state), isNull);
    });
  });

  group('game goes on', () {
    test('initial position', () {
      expect(detector.detect(GameState.initial()), isNull);
    });

    test('through the traditional opening', () {
      final game = playAll(localGame(), TraditionalEncounter.whiteFirst);
      expect(game.result, isNull);
      expect(game.isOver, isFalse);
    });
  });

  group('draws (end.draw, NEEDS_VERIFICATION)', () {
    // Two Sultans shuffling: after 4 plies the position repeats.
    final shuffle = stateWith({
      'a1': Piece.whiteSultan,
      'i9': Piece.blackSultan,
    });
    const cycle = ['a1-a2', 'i9-i8', 'a2-a1', 'i8-i9'];

    test('no draw rule by default: repetitions never end the game', () {
      var game = localGame(state: shuffle);
      for (var i = 0; i < 5; i++) {
        game = playAll(game, cycle);
      }
      expect(game.state.board, shuffle.board);
      expect(game.result, isNull);
    });

    test('threefold repetition when enabled', () {
      const rules = DhametRules(draw: DrawRules(repetitionLimit: 3));
      final start = stateWith({
        'a1': Piece.whiteSultan,
        'i9': Piece.blackSultan,
      }, rules: rules);
      var game = localGame(state: start);
      game = playAll(game, cycle);
      expect(game.result, isNull, reason: 'second occurrence');
      game = playAll(game, cycle.sublist(0, 3));
      expect(game.result, isNull);
      game = playAll(game, cycle.sublist(3));
      expect(game.result, const GameResult.draw(GameEndReason.repetition));
      expect(game.result!.isDraw, isTrue);
      expect(game.result!.winner, isNull);
    });

    test('a repeated board with the other side to move does not count', () {
      const rules = DhametRules(draw: DrawRules(repetitionLimit: 2));
      final whiteToMove = stateWith({
        'a1': Piece.whiteSultan,
        'i9': Piece.blackSultan,
      }, rules: rules);
      final blackToMove = GameState(
        board: whiteToMove.board,
        currentPlayer: Player.black,
        rules: rules,
      );
      expect(
        detector.detect(whiteToMove, previousStates: [blackToMove]),
        isNull,
      );
      expect(
        detector.detect(whiteToMove, previousStates: [whiteToMove]),
        const GameResult.draw(GameEndReason.repetition),
      );
    });

    test('a decisive result takes precedence over repetition', () {
      const rules = DhametRules(draw: DrawRules(repetitionLimit: 2));
      final blocked = stateWith({
        'e8': Piece.whitePawn,
        'e9': Piece.blackPawn,
      }, rules: rules);
      expect(
        detector.detect(blocked, previousStates: [blocked]),
        const GameResult.win(Player.black, GameEndReason.blocked),
      );
    });
  });

  group('GameResult', () {
    test('draw reasons and decisive reasons', () {
      final draws = {
        for (final reason in GameEndReason.values)
          if (reason.isDraw) reason,
      };
      expect(draws, {GameEndReason.repetition, GameEndReason.agreement});
      final declared = {
        for (final reason in GameEndReason.values)
          if (reason.isDeclared) reason,
      };
      expect(declared, {
        GameEndReason.agreement,
        GameEndReason.resignation,
        GameEndReason.timeout,
      });
    });

    test('equality and description', () {
      const result = GameResult.win(Player.white, GameEndReason.blocked);
      expect(result, const GameResult.win(Player.white, GameEndReason.blocked));
      expect(
        result == const GameResult.win(Player.black, GameEndReason.blocked),
        isFalse,
      );
      expect(
        result.hashCode,
        const GameResult.win(Player.white, GameEndReason.blocked).hashCode,
      );
      expect(result.toString(), 'GameResult.win(white, blocked)');
      expect(
        const GameResult.draw(GameEndReason.agreement).toString(),
        'GameResult.draw(agreement)',
      );
    });
  });
}
