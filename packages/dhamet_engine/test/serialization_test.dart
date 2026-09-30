import 'dart:convert';
import 'dart:math';

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

/// Encodes to a JSON string and decodes it back, as a save file would.
Object? throughJsonText(Object? value) => jsonDecode(jsonEncode(value));

void main() {
  group('values', () {
    test('Player, Piece and Position', () {
      for (final player in Player.values) {
        expect(Player.fromJson(throughJsonText(player.toJson())), player);
      }
      for (final piece in Piece.values) {
        expect(Piece.fromJson(throughJsonText(piece.toJson())), piece);
      }
      for (final position in Position.all) {
        expect(Position.fromJson(position.toJson()), same(position));
      }
      expect(Player.white.toJson(), 'white');
      expect(Piece.blackSultan.toJson(), 'B');
      expect(sq('e5').toJson(), 'e5');
    });

    test('invalid values are rejected', () {
      expect(() => Player.fromJson('red'), throwsFormatException);
      expect(() => Player.fromJson(null), throwsFormatException);
      expect(() => Piece.fromJson('x'), throwsFormatException);
      expect(() => Piece.fromJson(1), throwsFormatException);
      expect(() => Position.fromJson('j1'), throwsFormatException);
      expect(() => Position.fromJson(null), throwsFormatException);
    });
  });

  group('Board', () {
    test('initial board format (stable)', () {
      expect(Board.initial().toJson(), [
        'bbbbbbbbb',
        'bbbbbbbbb',
        'bbbbbbbbb',
        'bbbbbbbbb',
        'bbbb.wwww',
        'wwwwwwwww',
        'wwwwwwwww',
        'wwwwwwwww',
        'wwwwwwwww',
      ]);
    });

    test('round trip', () {
      final board = Board.fromPieces({
        sq('a1'): Piece.whiteSultan,
        sq('i9'): Piece.blackPawn,
        sq('e5'): Piece.blackSultan,
      });
      expect(Board.fromJson(throughJsonText(board.toJson())), board);
      expect(
        Board.fromJson(throughJsonText(Board.empty().toJson())),
        Board.empty(),
      );
    });

    test('malformed boards are rejected', () {
      final rows = Board.initial().toJson();
      expect(() => Board.fromJson(rows.sublist(1)), throwsFormatException);
      expect(
        () => Board.fromJson([...rows.sublist(1), 'wwww']),
        throwsFormatException,
      );
      expect(
        () => Board.fromJson([...rows.sublist(1), 'wwwwwwwwx']),
        throwsFormatException,
      );
      expect(
        () => Board.fromJson([...rows.sublist(1), 3]),
        throwsFormatException,
      );
      expect(() => Board.fromJson('bbbb'), throwsFormatException);
    });
  });

  group('Move', () {
    test('format (stable) and round trip', () {
      final move = Move(
        piece: Piece.whitePawn,
        from: sq('e5'),
        path: [sq('c5'), sq('a5')],
        captured: [sq('d5'), sq('b5')],
      );
      expect(move.toJson(), {
        'piece': 'w',
        'from': 'e5',
        'path': ['c5', 'a5'],
        'captured': ['d5', 'b5'],
        'promotes': false,
      });
      expect(Move.fromJson(throughJsonText(move.toJson())), move);

      final promotion = Move(
        piece: Piece.blackPawn,
        from: sq('b2'),
        path: [sq('b1')],
        promotes: true,
      );
      expect(Move.fromJson(throughJsonText(promotion.toJson())), promotion);
    });

    test('malformed moves are rejected', () {
      final valid = {
        'piece': 'w',
        'from': 'e5',
        'path': ['c5', 'a5'],
        'captured': ['d5', 'b5'],
        'promotes': false,
      };
      expect(
        () => Move.fromJson({...valid, 'path': <String>[]}),
        throwsFormatException,
      );
      expect(
        () => Move.fromJson({
          ...valid,
          'captured': ['d5'],
        }),
        throwsFormatException,
      );
      expect(
        () => Move.fromJson({...valid, 'piece': 'k'}),
        throwsFormatException,
      );
      expect(
        () => Move.fromJson({...valid, 'from': 'z1'}),
        throwsFormatException,
      );
      expect(
        () => Move.fromJson({...valid, 'promotes': 'no'}),
        throwsFormatException,
      );
      expect(() => Move.fromJson('e5xa5'), throwsFormatException);
    });
  });

  group('DhametRules', () {
    test('standard rules format (stable)', () {
      expect(DhametRules.standard.toJson(), {
        'startingPlayer': 'white',
        'mandatoryCapture': true,
        'captureChoice': 'maximumPieces',
        'capturedPieceRemoval': 'immediate',
        'pawnCapturesBackward': true,
        'pawnCapturesSideways': true,
        'sultanFlies': true,
        'sultanLanding': 'anyEmptyPointBeyond',
        'sultanMayReverseDuringCapture': true,
        'opening': 'free',
        'souvlet': {'mode': 'disabled'},
        'draw': {'byAgreement': false, 'repetitionLimit': null},
      });
    });

    test('round trip of every variant', () {
      final variants = [
        DhametRules.standard,
        const DhametRules(
          startingPlayer: Player.black,
          mandatoryCapture: false,
          captureChoice: CaptureChoice.free,
          capturedPieceRemoval: CapturedPieceRemoval.endOfSequence,
          pawnCapturesBackward: false,
          pawnCapturesSideways: false,
          sultanFlies: false,
          sultanLanding: SultanLanding.immediatelyBehind,
          sultanMayReverseDuringCapture: false,
          opening: OpeningRule.traditionalEncounter,
          souvlet: SouvletRule.enabled,
          draw: DrawRules(byAgreement: true, repetitionLimit: 3),
        ),
      ];
      for (final rules in variants) {
        expect(DhametRules.fromJson(throughJsonText(rules.toJson())), rules);
      }
    });

    test('missing settings take their default value (older saves)', () {
      expect(DhametRules.fromJson(<String, Object?>{}), DhametRules.standard);
      expect(
        DhametRules.fromJson({'startingPlayer': 'black'}),
        const DhametRules(startingPlayer: Player.black),
      );
    });

    test('invalid settings are rejected', () {
      expect(
        () => DhametRules.fromJson({'captureChoice': 'some'}),
        throwsFormatException,
      );
      expect(
        () => DhametRules.fromJson({'sultanFlies': 'yes'}),
        throwsFormatException,
      );
      expect(
        () => DhametRules.fromJson({
          'souvlet': {'mode': 'maybe'},
        }),
        throwsFormatException,
      );
      expect(
        () => DhametRules.fromJson({
          'draw': {'repetitionLimit': 1},
        }),
        throwsFormatException,
      );
      expect(() => DhametRules.fromJson([]), throwsFormatException);
    });
  });

  group('GameState', () {
    test('initial state format (stable)', () {
      expect(GameState.initial().toJson(), {
        'board': Board.initial().toJson(),
        'currentPlayer': 'white',
        'plyCount': 0,
        'rules': DhametRules.standard.toJson(),
        'lastMove': null,
      });
    });

    test('round trip, including the last move', () {
      final state = playAll(localGame(), ['d4-e5', 'f6xd4']).state;
      final restored = GameState.fromJson(throughJsonText(state.toJson()));
      expect(restored, state);
      expect(restored.hashCode, state.hashCode);
      expect(restored.lastMove!.notation, 'f6xd4');
      expect(restored.legalMoves, state.legalMoves);
    });

    test('malformed states are rejected', () {
      final valid = GameState.initial().toJson();
      expect(
        () => GameState.fromJson({...valid, 'plyCount': -1}),
        throwsFormatException,
      );
      expect(
        () => GameState.fromJson({...valid, 'plyCount': '0'}),
        throwsFormatException,
      );
      expect(
        () => GameState.fromJson({...valid, 'currentPlayer': 'red'}),
        throwsFormatException,
      );
      expect(
        () => GameState.fromJson({...valid, 'board': null}),
        throwsFormatException,
      );
    });
  });

  group('GameHistory and Game', () {
    test('a saved game keeps its moves, redo list and timestamps', () {
      var game = localGame();
      var time = DateTime.utc(2026, 9, 30, 10);
      for (final notation in TraditionalEncounter.whiteFirst.sublist(0, 6)) {
        game = game.play(
          game.state.legalMovesMatching(notation).single,
          timestamp: time,
        );
        time = time.add(const Duration(seconds: 30));
      }
      game = game.undo().undo();

      final restored = Game.fromJson(throughJsonText(game.toJson()));
      expect(restored.state, game.state);
      expect(restored.undoPolicy, UndoPolicy.unlimited);
      expect(restored.history.playedMoves, hasLength(4));
      expect(restored.history.undoneMoves, hasLength(2));
      expect(
        restored.history.playedMoves.map((r) => r.timestamp),
        game.history.playedMoves.map((r) => r.timestamp),
      );
      expect(restored.redo().redo().state, game.redo().redo().state);
      expect(restored.history.states, game.history.states);
    });

    test('game file format (stable)', () {
      final game = playAll(localGame(), ['d4-e5']);
      final json = game.toJson();
      expect(json.keys, [
        'format',
        'version',
        'undoPolicy',
        'declaredResult',
        'history',
      ]);
      expect(json['format'], 'dhamet.game');
      expect(json['version'], 1);
      expect(json['undoPolicy'], {'enabled': true, 'maxDepth': null});
      expect(json['history'], {
        'initialState': GameState.initial().toJson(),
        'moves': [
          {
            'move': {
              'piece': 'w',
              'from': 'd4',
              'path': ['e5'],
              'captured': <String>[],
              'promotes': false,
            },
            'capturedPieces': <String>[],
            'timestamp': null,
          },
        ],
        'cursor': 1,
      });
    });

    test('declared results and undo policies are kept', () {
      final resigned = Game.start(undoPolicy: const UndoPolicy.limited(3))
          .resign(Player.white);
      final restored = Game.fromJson(throughJsonText(resigned.toJson()));
      expect(
        restored.result,
        const GameResult.win(Player.black, GameEndReason.resignation),
      );
      expect(restored.undoPolicy, const UndoPolicy.limited(3));

      final drawn = Game.start(
        rules: const DhametRules(draw: DrawRules(byAgreement: true)),
      ).agreeToDraw();
      expect(
        Game.fromJson(throughJsonText(drawn.toJson())).result,
        const GameResult.draw(GameEndReason.agreement),
      );
    });

    test('a finished game reloads finished', () {
      final over = playAll(
        localGame(
          state: stateWith({'e3': Piece.whitePawn, 'e4': Piece.blackPawn}),
        ),
        ['e3xe5'],
      );
      final restored = Game.fromJson(throughJsonText(over.toJson()));
      expect(
        restored.result,
        const GameResult.win(Player.white, GameEndReason.elimination),
      );
    });

    test('random games survive a save and reload', () {
      for (var seed = 0; seed < 15; seed++) {
        final random = Random(seed);
        var game = localGame();
        for (var ply = 0; ply < 200 && !game.isOver; ply++) {
          final moves = game.state.legalMoves;
          game = game.play(moves[random.nextInt(moves.length)]);
        }
        if (random.nextBool() && game.canUndo) game = game.undo();
        final restored = Game.fromJson(throughJsonText(game.toJson()));
        expect(restored.state, game.state, reason: 'seed $seed');
        expect(restored.result, game.result);
        expect(restored.canUndo, game.canUndo);
        expect(restored.canRedo, game.canRedo);
        expect(restored.toJson(), game.toJson());
      }
    });

    group('corrupted saves are rejected', () {
      Map<String, Object?> saved() =>
          throughJsonText(playAll(localGame(), ['d4-e5', 'f6xd4']).toJson())
              as Map<String, Object?>;
      Map<String, Object?> historyOf(Map<String, Object?> json) =>
          json['history']! as Map<String, Object?>;
      List<Object?> movesOf(Map<String, Object?> json) =>
          historyOf(json)['moves']! as List<Object?>;

      test('unknown format or version', () {
        expect(
          () => Game.fromJson({...saved(), 'format': 'chess'}),
          throwsFormatException,
        );
        expect(
          () => Game.fromJson({...saved(), 'version': 2}),
          throwsFormatException,
        );
        expect(
          () => Game.fromJson({...saved(), 'version': '1'}),
          throwsFormatException,
        );
        expect(() => Game.fromJson('game'), throwsFormatException);
      });

      test('an illegal move in the history', () {
        final json = saved();
        final first = movesOf(json)[0]! as Map<String, Object?>;
        first['move'] = {
          'piece': 'w',
          'from': 'e3',
          'path': ['e5'],
          'captured': <String>[],
          'promotes': false,
        };
        expect(() => Game.fromJson(json), throwsFormatException);
      });

      test('captured pieces that do not match the replay', () {
        final json = saved();
        (movesOf(json)[1]! as Map<String, Object?>)['capturedPieces'] = ['W'];
        expect(() => Game.fromJson(json), throwsFormatException);
      });

      test('a cursor out of range', () {
        final json = saved();
        historyOf(json)['cursor'] = 3;
        expect(() => Game.fromJson(json), throwsFormatException);
      });

      test('a declared result that must be read from the board', () {
        final json = {
          ...saved(),
          'declaredResult': {'winner': 'white', 'reason': 'elimination'},
        };
        expect(() => Game.fromJson(json), throwsFormatException);
      });

      test('a malformed result, policy or timestamp', () {
        expect(
          () => Game.fromJson({
            ...saved(),
            'declaredResult': {'winner': 'white', 'reason': 'agreement'},
          }),
          throwsFormatException,
        );
        expect(
          () => Game.fromJson({
            ...saved(),
            'undoPolicy': {'enabled': true, 'maxDepth': 0},
          }),
          throwsFormatException,
        );
        final json = saved();
        (movesOf(json)[0]! as Map<String, Object?>)['timestamp'] = 12;
        expect(() => Game.fromJson(json), throwsFormatException);
      });
    });
  });
}
