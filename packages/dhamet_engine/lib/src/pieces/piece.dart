import 'player.dart';

/// Rank of a piece.
enum PieceType {
  /// An ordinary piece (جندي), moving forward one step at a time.
  pawn,

  /// A promoted piece (سلطان, also called ظايم), moving along whole lines.
  sultan,
}

/// A piece standing on the board: its owner and its rank.
enum Piece {
  whitePawn(Player.white, PieceType.pawn, 'w'),
  whiteSultan(Player.white, PieceType.sultan, 'W'),
  blackPawn(Player.black, PieceType.pawn, 'b'),
  blackSultan(Player.black, PieceType.sultan, 'B');

  const Piece(this.owner, this.type, this.symbol);

  /// The side this piece belongs to.
  final Player owner;

  /// Pawn or Sultan.
  final PieceType type;

  /// One-character symbol used in board diagrams: `w`, `W`, `b`, `B`.
  final String symbol;

  /// The piece of [owner] with rank [type].
  static Piece of(Player owner, PieceType type) => switch ((owner, type)) {
    (Player.white, PieceType.pawn) => whitePawn,
    (Player.white, PieceType.sultan) => whiteSultan,
    (Player.black, PieceType.pawn) => blackPawn,
    (Player.black, PieceType.sultan) => blackSultan,
  };

  /// The piece drawn as [symbol] in a board diagram, or `null`.
  static Piece? fromSymbol(String symbol) {
    for (final piece in values) {
      if (piece.symbol == symbol) return piece;
    }
    return null;
  }

  bool get isPawn => type == PieceType.pawn;

  bool get isSultan => type == PieceType.sultan;

  /// The Sultan of the same owner.
  Piece get promoted => of(owner, PieceType.sultan);

  /// JSON representation: the diagram [symbol] (`w`, `W`, `b`, `B`).
  String toJson() => symbol;

  static Piece fromJson(Object? json) {
    final piece = json is String ? fromSymbol(json) : null;
    if (piece == null) {
      throw FormatException('piece: expected one of w, W, b, B', json);
    }
    return piece;
  }
}
