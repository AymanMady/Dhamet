import '../pieces/player.dart';

/// Which capture sequences are allowed when several are available.
enum CaptureChoice {
  /// Only the sequences taking the largest number of pieces (majority rule).
  maximumPieces,

  /// Any complete capture sequence.
  free,
}

/// When the pieces taken during a capture sequence leave the board.
enum CapturedPieceRemoval {
  /// Each piece is removed as soon as it is jumped, so its intersection can
  /// be crossed or landed on later in the same sequence (Mauritanian rule).
  immediate,

  /// Pieces are removed once the sequence is over; until then they block
  /// the way and cannot be captured twice (Zamma rule elsewhere).
  endOfSequence,
}

/// Where a Sultan may land after capturing.
enum SultanLanding {
  /// On any empty intersection beyond the captured piece, up to the next
  /// piece or the end of the line.
  anyEmptyPointBeyond,

  /// Only on the intersection immediately behind the captured piece.
  immediatelyBehind,
}

/// The rule set applied by the engine.
///
/// Each setting controls one rule whose status is documented in
/// `docs/rules.md` and in `dhametRuleCatalog`. Defaults follow the best
/// documented Mauritanian rules; settings marked NEEDS_VERIFICATION or
/// LIKELY must be confirmed by Dhamet players before being considered final.
final class DhametRules {
  const DhametRules({
    this.firstPlayer = Player.white,
    this.mandatoryCapture = true,
    this.captureChoice = CaptureChoice.maximumPieces,
    this.capturedPieceRemoval = CapturedPieceRemoval.immediate,
    this.pawnCapturesBackward = true,
    this.pawnCapturesSideways = true,
    this.sultanFlies = true,
    this.sultanLanding = SultanLanding.anyEmptyPointBeyond,
    this.sultanMayReverseDuringCapture = true,
  });

  /// The default rule set.
  static const DhametRules standard = DhametRules();

  /// Side that makes the first move.
  ///
  /// NEEDS_VERIFICATION (`turn.firstPlayer`): White according to the French
  /// description of the traditional opening, Black according to Wikipedia,
  /// mindsports.nl and Mats Winther. Since the starting position is
  /// symmetric, this only decides which colour name the first player gets.
  final Player firstPlayer;

  /// Whether a player who can capture must capture.
  ///
  /// CONFIRMED (`capture.mandatory`).
  final bool mandatoryCapture;

  /// Which capture sequences may be chosen.
  ///
  /// CONFIRMED (`capture.maximum`): the sequence taking the most pieces must
  /// be played. NEEDS_VERIFICATION (`capture.maximumSultanWeight`): no source
  /// says whether a Sultan counts for more than a pawn; the engine counts
  /// pieces only.
  final CaptureChoice captureChoice;

  /// When pieces taken during a sequence leave the board.
  ///
  /// CONFIRMED (`capture.immediateRemoval`): immediately, which is the
  /// distinctive Mauritanian rule.
  final CapturedPieceRemoval capturedPieceRemoval;

  /// Whether pawns may capture backwards.
  ///
  /// CONFIRMED (`capture.pawnDirections`).
  final bool pawnCapturesBackward;

  /// Whether pawns may capture along their row.
  ///
  /// CONFIRMED (`capture.pawnDirections`).
  final bool pawnCapturesSideways;

  /// Whether the Sultan moves and captures at any distance along a line.
  ///
  /// CONFIRMED (`sultan.flying`). When `false` the Sultan moves one step in
  /// any direction and captures by the short leap.
  final bool sultanFlies;

  /// Where a flying Sultan may land after a capture.
  ///
  /// LIKELY (`sultan.landing`): "anywhere beyond" per fr.wikipedia,
  /// Wikipedia and mindsports.nl; the French opening description only shows
  /// an example landing right behind the captured piece.
  final SultanLanding sultanLanding;

  /// Whether a Sultan may continue a capture sequence in the direction
  /// opposite to its previous capture (crossing back over the intersection
  /// just emptied).
  ///
  /// NEEDS_VERIFICATION (`sultan.reverseDuringCapture`): no source mentions
  /// it. Allowed by default because nothing forbids it.
  final bool sultanMayReverseDuringCapture;

  DhametRules copyWith({
    Player? firstPlayer,
    bool? mandatoryCapture,
    CaptureChoice? captureChoice,
    CapturedPieceRemoval? capturedPieceRemoval,
    bool? pawnCapturesBackward,
    bool? pawnCapturesSideways,
    bool? sultanFlies,
    SultanLanding? sultanLanding,
    bool? sultanMayReverseDuringCapture,
  }) => DhametRules(
    firstPlayer: firstPlayer ?? this.firstPlayer,
    mandatoryCapture: mandatoryCapture ?? this.mandatoryCapture,
    captureChoice: captureChoice ?? this.captureChoice,
    capturedPieceRemoval: capturedPieceRemoval ?? this.capturedPieceRemoval,
    pawnCapturesBackward: pawnCapturesBackward ?? this.pawnCapturesBackward,
    pawnCapturesSideways: pawnCapturesSideways ?? this.pawnCapturesSideways,
    sultanFlies: sultanFlies ?? this.sultanFlies,
    sultanLanding: sultanLanding ?? this.sultanLanding,
    sultanMayReverseDuringCapture:
        sultanMayReverseDuringCapture ?? this.sultanMayReverseDuringCapture,
  );

  @override
  bool operator ==(Object other) =>
      other is DhametRules &&
      other.firstPlayer == firstPlayer &&
      other.mandatoryCapture == mandatoryCapture &&
      other.captureChoice == captureChoice &&
      other.capturedPieceRemoval == capturedPieceRemoval &&
      other.pawnCapturesBackward == pawnCapturesBackward &&
      other.pawnCapturesSideways == pawnCapturesSideways &&
      other.sultanFlies == sultanFlies &&
      other.sultanLanding == sultanLanding &&
      other.sultanMayReverseDuringCapture == sultanMayReverseDuringCapture;

  @override
  int get hashCode => Object.hash(
    firstPlayer,
    mandatoryCapture,
    captureChoice,
    capturedPieceRemoval,
    pawnCapturesBackward,
    pawnCapturesSideways,
    sultanFlies,
    sultanLanding,
    sultanMayReverseDuringCapture,
  );
}
