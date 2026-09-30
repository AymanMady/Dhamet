import 'dart:math';

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:test/test.dart';

/// Plays random games and checks, at every position, invariants that any
/// legal move list must satisfy. This catches rule bugs that hand-written
/// positions miss.
void main() {
  const ruleSets = {
    'standard': DhametRules.standard,
    'black first': DhametRules(firstPlayer: Player.black),
    'removal at end of sequence': DhametRules(
      capturedPieceRemoval: CapturedPieceRemoval.endOfSequence,
    ),
    'Sultan lands right behind, no reversal': DhametRules(
      sultanLanding: SultanLanding.immediatelyBehind,
      sultanMayReverseDuringCapture: false,
    ),
    'free capture choice': DhametRules(captureChoice: CaptureChoice.free),
  };

  ruleSets.forEach((name, rules) {
    test('random games keep every invariant ($name)', () {
      var positions = 0;
      for (var seed = 0; seed < 25; seed++) {
        final random = Random(seed);
        var state = GameState.initial(rules: rules);
        for (var ply = 0; ply < 300 && state.legalMoves.isNotEmpty; ply++) {
          _checkMoveList(state);
          final move =
              state.legalMoves[random.nextInt(state.legalMoves.length)];
          final next = state.play(move);
          _checkTransition(state, move, next);
          state = next;
          positions++;
        }
      }
      expect(positions, greaterThan(1000));
    });
  });

  test('capture timing never matters for pawns (parity argument)', () {
    // A pawn always lands at an even offset from its start and jumps over
    // pieces at odd offsets, so it can never land on or pass through an
    // intersection emptied earlier in the sequence.
    const deferred = DhametRules(
      capturedPieceRemoval: CapturedPieceRemoval.endOfSequence,
    );
    final random = Random(42);
    for (var i = 0; i < 300; i++) {
      final pieces = <Position, Piece>{};
      for (final position in Position.all) {
        final roll = random.nextInt(10);
        if (roll < 2) pieces[position] = Piece.whitePawn;
        if (roll >= 2 && roll < 6) pieces[position] = Piece.blackPawn;
      }
      final board = Board.fromPieces(pieces);
      for (final player in Player.values) {
        final immediate = GameState(board: board, currentPlayer: player);
        final atEnd = GameState(
          board: board,
          currentPlayer: player,
          rules: deferred,
        );
        expect(immediate.legalMoves.toSet(), atEnd.legalMoves.toSet());
      }
    }
  });
}

void _checkMoveList(GameState state) {
  final moves = state.legalMoves;
  final board = state.board;
  final topology = BoardTopology.standard;

  final captures = moves.where((m) => m.isCapture).toList();
  if (captures.isNotEmpty) {
    expect(captures, hasLength(moves.length), reason: 'capture is mandatory');
    if (state.rules.captureChoice == CaptureChoice.maximumPieces) {
      final counts = captures.map((m) => m.captureCount).toSet();
      expect(counts, hasLength(1), reason: 'only maximal sequences');
    }
  }
  expect(moves.toSet(), hasLength(moves.length), reason: 'no duplicates');

  for (final move in moves) {
    expect(move.player, state.currentPlayer);
    expect(board[move.from], move.piece);
    // With immediate removal a Sultan may end on the intersection of a
    // piece it took earlier in the same sequence.
    final endsOnCaptured = move.captured.contains(move.to);
    expect(
      move.to == move.from || board.isEmpty(move.to) || endsOnCaptured,
      isTrue,
    );
    if (endsOnCaptured) {
      expect(move.piece.isSultan, isTrue);
      expect(state.rules.capturedPieceRemoval, CapturedPieceRemoval.immediate);
    }

    final reachesLastRow = move.to.row == move.player.promotionRow;
    expect(move.promotes, move.piece.isPawn && reachesLastRow);

    if (!move.isCapture) {
      expect(move.path, hasLength(1));
      expect(board.isEmpty(move.to), isTrue);
      if (move.piece.isPawn) {
        expect(topology.areConnected(move.from, move.to), isTrue);
        expect(move.to.row - move.from.row, move.player.rowStep);
      }
    } else {
      expect(move.captured.toSet(), hasLength(move.captured.length));
      for (final captured in move.captured) {
        expect(board[captured]?.owner, move.player.opponent);
      }
      if (move.piece.isPawn) {
        var at = move.from;
        for (var i = 0; i < move.path.length; i++) {
          final landing = move.path[i];
          final over = move.captured[i];
          expect(topology.areConnected(at, over), isTrue);
          expect(topology.areConnected(over, landing), isTrue);
          expect(over.column * 2, at.column + landing.column);
          expect(over.row * 2, at.row + landing.row);
          at = landing;
        }
      }
    }
  }
}

void _checkTransition(GameState before, Move move, GameState after) {
  final player = move.player;
  final opponent = player.opponent;
  expect(after.currentPlayer, opponent);
  expect(after.plyCount, before.plyCount + 1);
  expect(after.lastMove, move);
  expect(after.board.count(player), before.board.count(player));
  expect(
    after.board.count(opponent),
    before.board.count(opponent) - move.captureCount,
  );
  expect(
    after.board.count(player, type: PieceType.sultan),
    before.board.count(player, type: PieceType.sultan) +
        (move.promotes ? 1 : 0),
  );
  expect(after.board[move.to]?.owner, player);
  for (final captured in move.captured) {
    if (captured != move.to) expect(after.board.isEmpty(captured), isTrue);
  }
}
