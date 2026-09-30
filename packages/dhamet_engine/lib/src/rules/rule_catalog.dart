/// Confidence in a rule, as documented in `docs/rules.md`.
enum RuleStatus {
  /// Stated consistently by at least two independent sources.
  confirmed,

  /// Stated by several sources, but one source is ambiguous about it.
  likely,

  /// A documented alternative, not the default.
  variant,

  /// Contradictory or missing sources: must be checked with Dhamet players.
  needsVerification,
}

/// One rule of the game, its status and the setting that controls it.
final class RuleInfo {
  const RuleInfo({
    required this.id,
    required this.status,
    required this.summary,
    this.setting,
    this.implemented = true,
  });

  /// Stable identifier, also used in `docs/rules.md`.
  final String id;

  final RuleStatus status;

  /// One-line description in English.
  final String summary;

  /// Name of the `DhametRules` field controlling this rule, if any.
  final String? setting;

  /// Whether the engine implements this rule yet.
  final bool implemented;
}

/// Every rule known to the engine. Keep in sync with `docs/rules.md`.
const List<RuleInfo> dhametRuleCatalog = [
  RuleInfo(
    id: 'board.grid',
    status: RuleStatus.confirmed,
    summary: 'Pieces stand on the 81 intersections of a 9×9 grid of lines.',
  ),
  RuleInfo(
    id: 'board.diagonals',
    status: RuleStatus.confirmed,
    summary:
        'Diagonals pass through intersections whose column + row is even '
        '(quadruple alquerque, 14 diagonal lines).',
  ),
  RuleInfo(
    id: 'setup.pieces',
    status: RuleStatus.confirmed,
    summary: '40 pieces per side; only the centre e5 is empty.',
  ),
  RuleInfo(
    id: 'setup.middleRow',
    status: RuleStatus.confirmed,
    summary: 'On row 5 each side places 4 pieces on its own right-hand side.',
  ),
  RuleInfo(
    id: 'turn.firstPlayer',
    status: RuleStatus.needsVerification,
    summary: 'Which colour moves first (sources disagree).',
    setting: 'firstPlayer',
  ),
  RuleInfo(
    id: 'opening.rencontre',
    status: RuleStatus.variant,
    summary:
        'The first five moves of each side follow the traditional '
        '"rencontre" sequence (mandatory or merely conventional?).',
    implemented: false,
  ),
  RuleInfo(
    id: 'pawn.move',
    status: RuleStatus.confirmed,
    summary:
        'A pawn moves one step forward, straight or diagonally along a '
        'line; never sideways or backwards.',
  ),
  RuleInfo(
    id: 'capture.pawnDirections',
    status: RuleStatus.confirmed,
    summary:
        'A pawn captures by the short leap in every direction along the '
        'lines, including backwards and sideways.',
    setting: 'pawnCapturesBackward, pawnCapturesSideways',
  ),
  RuleInfo(
    id: 'capture.mandatory',
    status: RuleStatus.confirmed,
    summary: 'Capturing is mandatory.',
    setting: 'mandatoryCapture',
  ),
  RuleInfo(
    id: 'capture.maximum',
    status: RuleStatus.confirmed,
    summary: 'The capture sequence taking the most pieces must be played.',
    setting: 'captureChoice',
  ),
  RuleInfo(
    id: 'capture.maximumSultanWeight',
    status: RuleStatus.needsVerification,
    summary: 'Whether a Sultan weighs more than a pawn in the majority rule.',
    setting: 'captureChoice',
    implemented: false,
  ),
  RuleInfo(
    id: 'capture.immediateRemoval',
    status: RuleStatus.confirmed,
    summary: 'Captured pieces are removed immediately, during the sequence.',
    setting: 'capturedPieceRemoval',
  ),
  RuleInfo(
    id: 'promotion.lastRow',
    status: RuleStatus.confirmed,
    summary:
        "A pawn ending its move on the opponent's home row becomes a Sultan.",
  ),
  RuleInfo(
    id: 'promotion.notDuringCapture',
    status: RuleStatus.confirmed,
    summary:
        'A pawn only passing through the last row during a capture sequence '
        'is not promoted.',
  ),
  RuleInfo(
    id: 'sultan.flying',
    status: RuleStatus.confirmed,
    summary:
        'The Sultan moves any distance along a line and captures a piece at '
        'any distance on it.',
    setting: 'sultanFlies',
  ),
  RuleInfo(
    id: 'sultan.landing',
    status: RuleStatus.likely,
    summary:
        'The Sultan may land on any empty point beyond the captured piece.',
    setting: 'sultanLanding',
  ),
  RuleInfo(
    id: 'sultan.reverseDuringCapture',
    status: RuleStatus.needsVerification,
    summary: 'Whether a Sultan may turn back 180° between two captures.',
    setting: 'sultanMayReverseDuringCapture',
  ),
  RuleInfo(
    id: 'souvlet',
    status: RuleStatus.needsVerification,
    summary:
        'Soufflé: after an incomplete capture the opponent may demand the '
        'correct move or remove the offending piece. Details unknown.',
    implemented: false,
  ),
  RuleInfo(
    id: 'end.elimination',
    status: RuleStatus.confirmed,
    summary: 'A player who has lost all pieces loses.',
    implemented: false,
  ),
  RuleInfo(
    id: 'end.blocked',
    status: RuleStatus.confirmed,
    summary: 'A player who cannot move loses.',
    implemented: false,
  ),
  RuleInfo(
    id: 'end.draw',
    status: RuleStatus.needsVerification,
    summary: 'Draw by agreement or threefold repetition (single source).',
    implemented: false,
  ),
  RuleInfo(
    id: 'match.threeRounds',
    status: RuleStatus.variant,
    summary: 'A match is played over three rounds (single press source).',
    implemented: false,
  ),
];
