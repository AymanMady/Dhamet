import '../board/position.dart';
import '../pieces/piece.dart';
import '../pieces/player.dart';
import '../serialization/json_reader.dart';

/// Kind of move, derived from the number of captured pieces.
enum MoveType {
  /// A move without capture.
  normal,

  /// A single capture.
  capture,

  /// A capture sequence ("rafle") taking two pieces or more.
  multipleCapture,
}

/// A complete move of one piece, as produced by `MoveGenerator`.
///
/// For a capture sequence, [path] lists every landing intersection in order
/// and [captured] lists the piece taken to reach each of them, so both lists
/// have the same length. For a normal move, [path] holds the destination
/// only and [captured] is empty.
final class Move {
  Move({
    required this.piece,
    required this.from,
    required List<Position> path,
    List<Position> captured = const [],
    this.promotes = false,
  }) : assert(path.isNotEmpty, 'A move needs a destination'),
       assert(
         captured.isEmpty || captured.length == path.length,
         'A capture sequence captures exactly one piece per landing',
       ),
       path = List.unmodifiable(path),
       captured = List.unmodifiable(captured);

  /// The moving piece, before any promotion.
  final Piece piece;

  /// Starting intersection.
  final Position from;

  /// Landing intersections, in order. The last one is [to].
  final List<Position> path;

  /// Intersections of the captured pieces, in capture order.
  final List<Position> captured;

  /// Whether the pawn becomes a Sultan at the end of this move.
  final bool promotes;

  /// Final intersection.
  Position get to => path.last;

  /// The side making the move.
  Player get player => piece.owner;

  bool get isCapture => captured.isNotEmpty;

  int get captureCount => captured.length;

  bool get isSultanMove => piece.isSultan;

  MoveType get type => switch (captured.length) {
    0 => MoveType.normal,
    1 => MoveType.capture,
    _ => MoveType.multipleCapture,
  };

  /// Algebraic notation: `d4-e5` for a normal move, `c3xe5` for a capture
  /// and `g7xi5xg3` for a capture sequence (every landing listed).
  String get notation => [from, ...path].join(isCapture ? 'x' : '-');

  /// Whether [text] describes this move.
  ///
  /// Accepts the full notation (`e5xc5xa5`) or the abbreviated form giving
  /// only the start and end of a capture sequence (`e5xa5`), as written in
  /// the traditional sources. A trailing promotion mark `=S` is ignored.
  bool matchesNotation(String text) {
    final cleaned = text.replaceAll(' ', '').replaceAll('=S', '').toLowerCase();
    final isCaptureText = cleaned.contains('x');
    if (isCaptureText == cleaned.contains('-')) return false;
    if (isCaptureText != isCapture) return false;
    final squares = cleaned.split(isCaptureText ? 'x' : '-');
    final positions = squares.map(Position.tryParse).toList();
    if (positions.length < 2 || positions.contains(null)) return false;
    if (positions.first != from) return false;
    if (positions.length == 2) return positions.last == to;
    if (positions.length != path.length + 1) return false;
    for (var i = 0; i < path.length; i++) {
      if (positions[i + 1] != path[i]) return false;
    }
    return true;
  }

  /// JSON representation.
  Map<String, Object?> toJson() => {
    'piece': piece.toJson(),
    'from': from.toJson(),
    'path': [for (final p in path) p.toJson()],
    'captured': [for (final p in captured) p.toJson()],
    'promotes': promotes,
  };

  /// Reads [toJson] output. Only checks that the move is well formed;
  /// whether it is legal depends on the game state.
  static Move fromJson(Object? json) {
    final map = readMap(json, 'move');
    final path = [
      for (final p in readList(map['path'], 'move.path')) Position.fromJson(p),
    ];
    final captured = [
      for (final p in readList(map['captured'] ?? const [], 'move.captured'))
        Position.fromJson(p),
    ];
    if (path.isEmpty) {
      throw FormatException('move.path: a move needs a destination', json);
    }
    if (captured.isNotEmpty && captured.length != path.length) {
      throw FormatException('move.captured: one piece per landing', json);
    }
    return Move(
      piece: Piece.fromJson(map['piece']),
      from: Position.fromJson(map['from']),
      path: path,
      captured: captured,
      promotes: readOptional(map, 'promotes', 'move', false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! Move ||
        other.piece != piece ||
        other.from != from ||
        other.promotes != promotes ||
        other.path.length != path.length ||
        other.captured.length != captured.length) {
      return false;
    }
    for (var i = 0; i < path.length; i++) {
      if (other.path[i] != path[i]) return false;
    }
    for (var i = 0; i < captured.length; i++) {
      if (other.captured[i] != captured[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    piece,
    from,
    promotes,
    Object.hashAll(path),
    Object.hashAll(captured),
  );

  @override
  String toString() => promotes ? '$notation=S' : notation;
}
