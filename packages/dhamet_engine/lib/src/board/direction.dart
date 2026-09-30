/// One of the eight directions along which a line of the board may run.
///
/// "North" points from White's home row (row 1) towards Black's (row 9).
/// Whether a line actually exists in a direction depends on the
/// intersection; see `BoardTopology`.
enum Direction {
  north(0, 1),
  northEast(1, 1),
  east(1, 0),
  southEast(1, -1),
  south(0, -1),
  southWest(-1, -1),
  west(-1, 0),
  northWest(-1, 1);

  const Direction(this.columnStep, this.rowStep);

  /// Change of column when moving one intersection in this direction.
  final int columnStep;

  /// Change of row when moving one intersection in this direction.
  final int rowStep;

  /// Whether this direction follows a diagonal line.
  bool get isDiagonal => columnStep != 0 && rowStep != 0;

  /// Whether this direction follows a row or a column.
  bool get isOrthogonal => !isDiagonal;

  /// The direction pointing the other way.
  Direction get opposite => values[(index + 4) % values.length];
}
