import 'dart:collection';

import '../moves/move.dart';
import '../pieces/piece.dart';
import '../pieces/player.dart';
import '../serialization/json_reader.dart';
import 'position.dart';

/// Read access to an arrangement of pieces, as needed by move generation.
abstract interface class BoardView {
  /// The piece on [position], or `null` if it is empty.
  Piece? pieceAt(Position position);

  /// Whether a moving piece may stop on or travel through [position].
  bool isEmpty(Position position);

  /// Whether [position] holds a piece that [player] is allowed to capture.
  bool isCapturableBy(Position position, Player player);
}

/// An immutable arrangement of pieces on the 81 intersections.
///
/// A board knows nothing about whose turn it is or which moves are legal;
/// see `GameState` and `MoveGenerator`.
final class Board implements BoardView {
  Board._(this._cells);

  /// A board without any piece.
  factory Board.empty() => Board._(
    List<Piece?>.unmodifiable(List<Piece?>.filled(Position.count, null)),
  );

  /// A board holding exactly [pieces].
  factory Board.fromPieces(Map<Position, Piece> pieces) {
    final cells = List<Piece?>.filled(Position.count, null);
    pieces.forEach((position, piece) => cells[position.index] = piece);
    return Board._(UnmodifiableListView(cells));
  }

  /// The traditional starting position.
  ///
  /// Each side has 40 pawns: White fills rows 1–4 and Black rows 6–9. On the
  /// middle row each side places its 4 remaining pawns on its own right-hand
  /// side, so row 5 reads `b b b b . w w w w` from `a5` to `i5`. The centre
  /// e5 ("case de rencontre", عين المورده) stays empty.
  ///
  /// Rule status (docs/rules.md, `setup.*`): CONFIRMED.
  factory Board.initial() {
    final middle = Position.center;
    final cells = List<Piece?>.filled(Position.count, null);
    for (final position in Position.all) {
      if (position.row < middle.row) {
        cells[position.index] = Piece.whitePawn;
      } else if (position.row > middle.row) {
        cells[position.index] = Piece.blackPawn;
      } else if (position.column > middle.column) {
        cells[position.index] = Piece.whitePawn;
      } else if (position.column < middle.column) {
        cells[position.index] = Piece.blackPawn;
      }
    }
    return Board._(UnmodifiableListView(cells));
  }

  /// Parses a diagram with row 9 on top, one line per row, such as:
  ///
  /// ```text
  /// 9  . . . . . . . . .
  /// …
  /// 1  w . . . . . . . .
  ///    a b c d e f g h i
  /// ```
  ///
  /// Symbols: `.` empty, `w` white pawn, `W` white Sultan, `b` black pawn,
  /// `B` black Sultan. Row numbers and the column footer are optional.
  /// Throws a [FormatException] on malformed input.
  factory Board.parse(String diagram) {
    final rows = <String>[];
    for (final rawLine in diagram.split('\n')) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;
      final content = line.replaceAll(RegExp(r'\s'), '');
      if (content == 'abcdefghi') continue;
      final label = RegExp(r'^(\d)\s+').firstMatch(line);
      if (label != null) {
        final expected = Position.size - rows.length;
        if (int.parse(label.group(1)!) != expected) {
          throw FormatException('Expected row $expected', rawLine);
        }
        line = line.substring(label.end);
      }
      rows.add(line.replaceAll(RegExp(r'\s'), ''));
    }
    if (rows.length != Position.size) {
      throw FormatException(
        'Expected ${Position.size} rows, found ${rows.length}',
        diagram,
      );
    }
    final cells = List<Piece?>.filled(Position.count, null);
    for (var i = 0; i < rows.length; i++) {
      final row = Position.size - 1 - i;
      final symbols = rows[i];
      if (symbols.length != Position.size) {
        throw FormatException('Row ${row + 1} must have 9 symbols', symbols);
      }
      for (var column = 0; column < Position.size; column++) {
        final symbol = symbols[column];
        if (symbol == '.') continue;
        final piece = Piece.fromSymbol(symbol);
        if (piece == null) {
          throw FormatException('Unknown symbol "$symbol"', symbols);
        }
        cells[row * Position.size + column] = piece;
      }
    }
    return Board._(UnmodifiableListView(cells));
  }

  /// Reads [toJson] output: 9 rows of 9 symbols, row 9 first.
  factory Board.fromJson(Object? json) {
    final rows = readList(json, 'board');
    if (rows.length != Position.size) {
      throw FormatException('board: expected ${Position.size} rows', json);
    }
    final cells = List<Piece?>.filled(Position.count, null);
    for (var i = 0; i < rows.length; i++) {
      final symbols = rows[i];
      if (symbols is! String || symbols.length != Position.size) {
        throw FormatException('board: row ${9 - i} must be 9 symbols', symbols);
      }
      final row = Position.size - 1 - i;
      for (var column = 0; column < Position.size; column++) {
        final symbol = symbols[column];
        if (symbol == '.') continue;
        final piece = Piece.fromSymbol(symbol);
        if (piece == null) {
          throw FormatException('board: unknown symbol "$symbol"', symbols);
        }
        cells[row * Position.size + column] = piece;
      }
    }
    return Board._(UnmodifiableListView(cells));
  }

  final List<Piece?> _cells;

  @override
  Piece? pieceAt(Position position) => _cells[position.index];

  /// The piece on [position], or `null` if it is empty.
  Piece? operator [](Position position) => _cells[position.index];

  @override
  bool isEmpty(Position position) => _cells[position.index] == null;

  @override
  bool isCapturableBy(Position position, Player player) {
    final piece = _cells[position.index];
    return piece != null && piece.owner != player;
  }

  /// Every occupied intersection with its piece, ordered by position.
  Map<Position, Piece> get pieces => {
    for (final position in Position.all) position: ?_cells[position.index],
  };

  /// The intersections occupied by [player]'s pieces, ordered by position.
  List<Position> positionsOf(Player player) => [
    for (final position in Position.all)
      if (_cells[position.index]?.owner == player) position,
  ];

  /// Number of pieces of [player], optionally restricted to one [type].
  int count(Player player, {PieceType? type}) => _cells
      .where(
        (piece) =>
            piece != null &&
            piece.owner == player &&
            (type == null || piece.type == type),
      )
      .length;

  /// A copy of this board with [piece] placed on [position] (or removed when
  /// [piece] is `null`).
  Board withPiece(Position position, Piece? piece) {
    final cells = List<Piece?>.of(_cells);
    cells[position.index] = piece;
    return Board._(UnmodifiableListView(cells));
  }

  /// The board after [move]: the piece travels to its destination, captured
  /// pieces are removed, and the piece is promoted if [Move.promotes].
  ///
  /// This does not check that [move] is legal; use `GameState.play` for
  /// that. Throws an [ArgumentError] if [Move.piece] is not on [Move.from].
  Board applyMove(Move move) {
    final moving = _cells[move.from.index];
    if (moving != move.piece) {
      throw ArgumentError.value(
        move,
        'move',
        'No ${move.piece.name} on ${move.from}',
      );
    }
    final cells = List<Piece?>.of(_cells);
    cells[move.from.index] = null;
    for (final captured in move.captured) {
      cells[captured.index] = null;
    }
    cells[move.to.index] = move.promotes ? move.piece.promoted : move.piece;
    return Board._(UnmodifiableListView(cells));
  }

  /// JSON representation: 9 strings of 9 symbols (`.`, `w`, `W`, `b`, `B`),
  /// from row 9 down to row 1, as in a diagram.
  List<String> toJson() => [
    for (var row = Position.size - 1; row >= 0; row--)
      [
        for (var column = 0; column < Position.size; column++)
          _cells[row * Position.size + column]?.symbol ?? '.',
      ].join(),
  ];

  /// The board as a diagram readable by [Board.parse].
  String toDiagram() {
    final buffer = StringBuffer();
    for (var row = Position.size - 1; row >= 0; row--) {
      buffer.write('${row + 1} ');
      for (var column = 0; column < Position.size; column++) {
        buffer.write(' ${_cells[row * Position.size + column]?.symbol ?? '.'}');
      }
      buffer.writeln();
    }
    buffer.write('   a b c d e f g h i');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (other is! Board) return false;
    for (var i = 0; i < Position.count; i++) {
      if (_cells[i] != other._cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_cells);

  @override
  String toString() => toDiagram();
}
