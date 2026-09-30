/// An intersection of the 9×9 Dhamet grid.
///
/// Pieces stand on intersections, not in squares. Columns are lettered
/// `a`–`i` (index 0–8, left to right as seen from White's side) and rows are
/// numbered `1`–`9` (index 0–8, from White's home row to Black's home row).
/// This is the algebraic notation used by the French description of the
/// traditional opening (see `docs/rules.md`).
///
/// Instances are canonical: there is exactly one [Position] object per
/// intersection, which makes them cheap to compare and to use as map keys.
final class Position implements Comparable<Position> {
  const Position._(this.column, this.row);

  /// Returns the intersection at [column], [row] (both 0-based).
  ///
  /// Throws a [RangeError] if the coordinates are outside the board.
  factory Position(int column, int row) {
    if (!isValidCoordinate(column, row)) {
      throw RangeError(
        'Position ($column, $row) is outside the $size×$size board',
      );
    }
    return all[row * size + column];
  }

  /// Returns the intersection whose [index] is `row * 9 + column`.
  factory Position.fromIndex(int index) {
    RangeError.checkValidIndex(index, all, 'index');
    return all[index];
  }

  /// Parses algebraic notation such as `e5`.
  ///
  /// Throws a [FormatException] if [notation] is not a board intersection.
  factory Position.parse(String notation) {
    final position = tryParse(notation);
    if (position == null) {
      throw FormatException('Invalid board position', notation);
    }
    return position;
  }

  /// Number of lines (and columns) of the board.
  static const int size = 9;

  /// Number of intersections on the board.
  static const int count = size * size;

  /// Every intersection, ordered by [index] (a1, b1, … i1, a2, … i9).
  static final List<Position> all = List.unmodifiable([
    for (var row = 0; row < size; row++)
      for (var column = 0; column < size; column++) Position._(column, row),
  ]);

  /// The central intersection e5, empty at the start of the game.
  static final Position center = all[count ~/ 2];

  /// Whether ([column], [row]) is on the board.
  static bool isValidCoordinate(int column, int row) =>
      column >= 0 && column < size && row >= 0 && row < size;

  /// Returns the intersection at ([column], [row]) or `null` if it is off the
  /// board.
  static Position? tryAt(int column, int row) =>
      isValidCoordinate(column, row) ? all[row * size + column] : null;

  /// Parses algebraic notation such as `e5`, returning `null` if invalid.
  static Position? tryParse(String notation) {
    final text = notation.trim().toLowerCase();
    if (text.length != 2) return null;
    final column = text.codeUnitAt(0) - _letterA;
    final row = text.codeUnitAt(1) - _digitOne;
    return tryAt(column, row);
  }

  static const int _letterA = 0x61;
  static const int _digitOne = 0x31;

  /// 0-based column: 0 is `a`, 8 is `i`.
  final int column;

  /// 0-based row: 0 is row `1` (White's home row), 8 is row `9`.
  final int row;

  /// Index of this intersection in [all].
  int get index => row * size + column;

  /// Algebraic notation, e.g. `e5`.
  String get notation => '${String.fromCharCode(_letterA + column)}${row + 1}';

  @override
  bool operator ==(Object other) =>
      other is Position && other.column == column && other.row == row;

  @override
  int get hashCode => index;

  @override
  int compareTo(Position other) => index.compareTo(other.index);

  @override
  String toString() => notation;
}
