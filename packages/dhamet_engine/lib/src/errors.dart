import 'moves/move.dart';

/// Thrown when a move that is not legal in the current state is played.
final class IllegalMoveException implements Exception {
  const IllegalMoveException(this.move, this.reason);

  final Move move;

  /// Why the move was refused, in English, for logs and debugging.
  final String reason;

  @override
  String toString() => 'IllegalMoveException: $move ($reason)';
}
