import 'direction.dart';
import 'position.dart';

/// Decides whether diagonal lines pass through an intersection.
typedef DiagonalPattern = bool Function(Position position);

/// The graph of lines drawn on the board.
///
/// Pieces may only travel along drawn lines, so every movement rule is
/// expressed through this graph: which intersections are connected, and in
/// which directions. Every row and every column is a line. A diagonal
/// segment joins two diagonal neighbours only when the [DiagonalPattern]
/// accepts both of them.
///
/// Rule status (docs/rules.md, `board.diagonals`): CONFIRMED. The Dhamet
/// board is a quadruple alquerque: diagonals pass through the intersections
/// whose `column + row` is even ("open" or "wide" points, لوسع), giving 14
/// diagonal lines. The other intersections are "closed" or "narrow" points
/// (الظيك) and are only crossed by their row and column.
final class BoardTopology {
  BoardTopology._(this._open, this._neighbors, this._rays, this._directions);

  /// Builds the topology of a 9×9 grid whose diagonals follow [hasDiagonals].
  factory BoardTopology({required DiagonalPattern hasDiagonals}) {
    final open = List<bool>.unmodifiable([
      for (final position in Position.all) hasDiagonals(position),
    ]);

    final neighbors = List<Position?>.filled(Position.count * _slots, null);
    for (final from in Position.all) {
      for (final direction in Direction.values) {
        final to = Position.tryAt(
          from.column + direction.columnStep,
          from.row + direction.rowStep,
        );
        if (to == null) continue;
        if (direction.isDiagonal && !(open[from.index] && open[to.index])) {
          continue;
        }
        neighbors[_slot(from, direction)] = to;
      }
    }

    final rays = List<List<Position>>.unmodifiable([
      for (final from in Position.all)
        for (final direction in Direction.values)
          _walk(neighbors, from, direction),
    ]);

    final directions = List<List<Direction>>.unmodifiable([
      for (final from in Position.all)
        List<Direction>.unmodifiable([
          for (final direction in Direction.values)
            if (neighbors[_slot(from, direction)] != null) direction,
        ]),
    ]);

    return BoardTopology._(
      open,
      List.unmodifiable(neighbors),
      rays,
      directions,
    );
  }

  /// The Dhamet board (quadruple alquerque pattern).
  static final BoardTopology standard = BoardTopology(
    hasDiagonals: (position) => (position.column + position.row).isEven,
  );

  static const int _slots = 8;

  static int _slot(Position from, Direction direction) =>
      from.index * _slots + direction.index;

  static List<Position> _walk(
    List<Position?> neighbors,
    Position from,
    Direction direction,
  ) {
    final ray = <Position>[];
    var next = neighbors[_slot(from, direction)];
    while (next != null) {
      ray.add(next);
      next = neighbors[_slot(next, direction)];
    }
    return List.unmodifiable(ray);
  }

  final List<bool> _open;
  final List<Position?> _neighbors;
  final List<List<Position>> _rays;
  final List<List<Direction>> _directions;

  /// Whether diagonal lines pass through [position] (an "open" point).
  bool isOpen(Position position) => _open[position.index];

  /// The intersection connected to [from] in [direction], or `null` when no
  /// line leaves [from] in that direction.
  Position? neighbor(Position from, Direction direction) =>
      _neighbors[_slot(from, direction)];

  /// The directions in which a line leaves [from].
  List<Direction> directionsFrom(Position from) => _directions[from.index];

  /// The intersections met when following the line from [from] in
  /// [direction], nearest first, excluding [from]. Empty if there is no
  /// line in that direction.
  List<Position> ray(Position from, Direction direction) =>
      _rays[_slot(from, direction)];

  /// Whether a line segment directly joins [a] and [b].
  bool areConnected(Position a, Position b) =>
      directionsFrom(a).any((direction) => neighbor(a, direction) == b);

  /// The explicit graph: every intersection with its connected neighbours.
  late final Map<Position, List<Position>> adjacency = Map.unmodifiable({
    for (final from in Position.all)
      from: List<Position>.unmodifiable([
        for (final direction in directionsFrom(from))
          neighbor(from, direction)!,
      ]),
  });

  /// Every line segment of the board, each listed once. Useful to draw the
  /// board.
  late final List<(Position, Position)> segments = List.unmodifiable([
    for (final from in Position.all)
      for (final direction in const [
        Direction.east,
        Direction.north,
        Direction.northEast,
        Direction.northWest,
      ])
        if (neighbor(from, direction) case final to?) (from, to),
  ]);
}
