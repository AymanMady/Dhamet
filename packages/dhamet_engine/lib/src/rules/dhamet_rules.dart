import '../pieces/player.dart';
import '../serialization/json_reader.dart';
import 'draw_rules.dart';
import 'opening_rule.dart';
import 'souvlet_rule.dart';

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
    this.startingPlayer = Player.white,
    this.mandatoryCapture = true,
    this.captureChoice = CaptureChoice.maximumPieces,
    this.capturedPieceRemoval = CapturedPieceRemoval.immediate,
    this.pawnCapturesBackward = true,
    this.pawnCapturesSideways = true,
    this.sultanFlies = true,
    this.sultanLanding = SultanLanding.anyEmptyPointBeyond,
    this.sultanMayReverseDuringCapture = true,
    this.opening = OpeningRule.free,
    this.souvlet = SouvletRule.disabled,
    this.draw = DrawRules.none,
  });

  /// The default rule set.
  static const DhametRules standard = DhametRules();

  /// Side that makes the first move.
  ///
  /// NEEDS_VERIFICATION (`turn.startingPlayer`): White according to the French
  /// description of the traditional opening, Black according to Wikipedia,
  /// mindsports.nl and Mats Winther. Since the starting position is
  /// symmetric, this only decides which colour name the first player gets.
  final Player startingPlayer;

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

  /// How the game opens.
  ///
  /// VARIANT (`opening.rencontre`): free by default; the traditional
  /// "rencontre" is available but never imposed.
  final OpeningRule opening;

  /// The Souvlet (soufflé) penalty.
  ///
  /// NEEDS_VERIFICATION (`souvlet`): disabled; enabling it is not supported
  /// until its behaviour is confirmed.
  final SouvletRule souvlet;

  /// Draw rules.
  ///
  /// NEEDS_VERIFICATION (`end.draw`): none by default.
  final DrawRules draw;

  DhametRules copyWith({
    Player? startingPlayer,
    bool? mandatoryCapture,
    CaptureChoice? captureChoice,
    CapturedPieceRemoval? capturedPieceRemoval,
    bool? pawnCapturesBackward,
    bool? pawnCapturesSideways,
    bool? sultanFlies,
    SultanLanding? sultanLanding,
    bool? sultanMayReverseDuringCapture,
    OpeningRule? opening,
    SouvletRule? souvlet,
    DrawRules? draw,
  }) => DhametRules(
    startingPlayer: startingPlayer ?? this.startingPlayer,
    mandatoryCapture: mandatoryCapture ?? this.mandatoryCapture,
    captureChoice: captureChoice ?? this.captureChoice,
    capturedPieceRemoval: capturedPieceRemoval ?? this.capturedPieceRemoval,
    pawnCapturesBackward: pawnCapturesBackward ?? this.pawnCapturesBackward,
    pawnCapturesSideways: pawnCapturesSideways ?? this.pawnCapturesSideways,
    sultanFlies: sultanFlies ?? this.sultanFlies,
    sultanLanding: sultanLanding ?? this.sultanLanding,
    sultanMayReverseDuringCapture:
        sultanMayReverseDuringCapture ?? this.sultanMayReverseDuringCapture,
    opening: opening ?? this.opening,
    souvlet: souvlet ?? this.souvlet,
    draw: draw ?? this.draw,
  );

  /// A JSON representation listing every setting.
  Map<String, Object?> toJson() => {
    'startingPlayer': startingPlayer.toJson(),
    'mandatoryCapture': mandatoryCapture,
    'captureChoice': captureChoice.name,
    'capturedPieceRemoval': capturedPieceRemoval.name,
    'pawnCapturesBackward': pawnCapturesBackward,
    'pawnCapturesSideways': pawnCapturesSideways,
    'sultanFlies': sultanFlies,
    'sultanLanding': sultanLanding.name,
    'sultanMayReverseDuringCapture': sultanMayReverseDuringCapture,
    'opening': opening.name,
    'souvlet': souvlet.toJson(),
    'draw': draw.toJson(),
  };

  /// Reads [toJson] output. A missing setting takes its default value, so
  /// that games saved before a setting existed still load.
  static DhametRules fromJson(Object? json) {
    final map = readMap(json, 'rules');
    const defaults = DhametRules.standard;
    E enumOr<E extends Enum>(List<E> values, String key, E fallback) =>
        map[key] == null ? fallback : readEnum(values, map[key], 'rules.$key');
    bool flag(String key, bool fallback) =>
        readOptional(map, key, 'rules', fallback);
    return DhametRules(
      startingPlayer: map['startingPlayer'] == null
          ? defaults.startingPlayer
          : Player.fromJson(map['startingPlayer']),
      mandatoryCapture: flag('mandatoryCapture', defaults.mandatoryCapture),
      captureChoice: enumOr(
        CaptureChoice.values,
        'captureChoice',
        defaults.captureChoice,
      ),
      capturedPieceRemoval: enumOr(
        CapturedPieceRemoval.values,
        'capturedPieceRemoval',
        defaults.capturedPieceRemoval,
      ),
      pawnCapturesBackward: flag(
        'pawnCapturesBackward',
        defaults.pawnCapturesBackward,
      ),
      pawnCapturesSideways: flag(
        'pawnCapturesSideways',
        defaults.pawnCapturesSideways,
      ),
      sultanFlies: flag('sultanFlies', defaults.sultanFlies),
      sultanLanding: enumOr(
        SultanLanding.values,
        'sultanLanding',
        defaults.sultanLanding,
      ),
      sultanMayReverseDuringCapture: flag(
        'sultanMayReverseDuringCapture',
        defaults.sultanMayReverseDuringCapture,
      ),
      opening: enumOr(OpeningRule.values, 'opening', defaults.opening),
      souvlet: map['souvlet'] == null
          ? defaults.souvlet
          : SouvletRule.fromJson(map['souvlet']),
      draw: map['draw'] == null
          ? defaults.draw
          : DrawRules.fromJson(map['draw']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DhametRules &&
      other.startingPlayer == startingPlayer &&
      other.mandatoryCapture == mandatoryCapture &&
      other.captureChoice == captureChoice &&
      other.capturedPieceRemoval == capturedPieceRemoval &&
      other.pawnCapturesBackward == pawnCapturesBackward &&
      other.pawnCapturesSideways == pawnCapturesSideways &&
      other.sultanFlies == sultanFlies &&
      other.sultanLanding == sultanLanding &&
      other.sultanMayReverseDuringCapture == sultanMayReverseDuringCapture &&
      other.opening == opening &&
      other.souvlet == souvlet &&
      other.draw == draw;

  @override
  int get hashCode => Object.hash(
    startingPlayer,
    mandatoryCapture,
    captureChoice,
    capturedPieceRemoval,
    pawnCapturesBackward,
    pawnCapturesSideways,
    sultanFlies,
    sultanLanding,
    sultanMayReverseDuringCapture,
    opening,
    souvlet,
    draw,
  );
}
