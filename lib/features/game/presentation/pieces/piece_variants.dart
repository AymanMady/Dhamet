import 'package:dhamet_engine/dhamet_engine.dart';

import 'piece_look.dart';

/// Keeps each piece's [PieceLook] attached to it when it moves, so that a
/// pebble keeps its shape from one intersection to the next. Purely visual:
/// the engine has no notion of piece identity.
class PieceVariants {
  PieceVariants(Board board) {
    sync(board);
  }

  final Map<Position, int> _seeds = {};

  /// Incremented whenever a look changes place.
  int get version => _version;
  int _version = 0;

  PieceLook lookAt(Position position) =>
      PieceLook.fromSeed(_seeds[position] ?? seedFor(position));

  /// Follows [move], played.
  void play(Move move) {
    final seed = _seeds.remove(move.from) ?? seedFor(move.from);
    for (final captured in move.captured) {
      _seeds.remove(captured);
    }
    _seeds[move.to] = seed;
    _version++;
  }

  /// Follows [move], taken back.
  void takeBack(Move move) {
    final seed = _seeds.remove(move.to) ?? seedFor(move.to);
    _seeds[move.from] = seed;
    for (final captured in move.captured) {
      _seeds[captured] = seedFor(captured);
    }
    _version++;
  }

  /// Forgets pieces that are gone and gives a look to new ones.
  void sync(Board board) {
    final pieces = board.pieces;
    final before = _seeds.length;
    _seeds.removeWhere((position, _) => !pieces.containsKey(position));
    var changed = _seeds.length != before;
    for (final position in pieces.keys) {
      if (!_seeds.containsKey(position)) {
        _seeds[position] = seedFor(position);
        changed = true;
      }
    }
    if (changed) _version++;
  }

  /// The look a piece gets when it first appears on [position].
  static int seedFor(Position position) => position.index * 7919 + 17;
}
