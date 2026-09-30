import '../serialization/json_reader.dart';

/// Whether the Souvlet (soufflé) penalty is in force.
enum SouvletMode {
  /// The engine only offers legal moves, so a player can never fail to make
  /// the maximal capture and there is nothing to penalise. This amounts to
  /// the opponent always "demanding" the correct move.
  disabled,

  /// Players may make a faulty move and the opponent may penalise it.
  ///
  /// NOT IMPLEMENTED: the exact behaviour is unconfirmed.
  enabled,
}

/// Configuration of the Souvlet / soufflé rule (`souvlet`,
/// NEEDS_VERIFICATION). See docs/rules.md § 10.
///
/// What the sources say: when a player does not complete the maximal
/// capture sequence, the opponent may either demand the correct move or
/// "blow" (remove) the piece that should have captured. For complicated
/// sequences, the player announces beforehand how many pieces they will
/// take.
///
/// TODO(CONFIRMATION_NEEDED): before [SouvletMode.enabled] can be
/// implemented, the following must be confirmed by Dhamet players:
/// - does a non-capturing move, when a capture exists, trigger it too?
/// - which piece is removed when several pieces could have captured, and
///   who chooses it?
/// - does the faulty move stand after the piece is removed?
/// - does blowing a piece count as the opponent's move?
/// - when must the number of captures be announced?
/// - is the rule used in competition?
///
/// Only [SouvletRule.disabled] is supported. Generating moves with the
/// Souvlet enabled throws an [UnsupportedError], so the unconfirmed rule can
/// never be applied silently.
final class SouvletRule {
  const SouvletRule._(this.mode);

  /// The default: only legal moves can be played.
  static const SouvletRule disabled = SouvletRule._(SouvletMode.disabled);

  /// Reserved for a future, confirmed implementation.
  static const SouvletRule enabled = SouvletRule._(SouvletMode.enabled);

  final SouvletMode mode;

  bool get isEnabled => mode == SouvletMode.enabled;

  Map<String, Object?> toJson() => {'mode': mode.name};

  static SouvletRule fromJson(Object? json) {
    final map = readMap(json, 'souvlet');
    return switch (readEnum(SouvletMode.values, map['mode'], 'souvlet.mode')) {
      SouvletMode.disabled => disabled,
      SouvletMode.enabled => enabled,
    };
  }

  @override
  bool operator ==(Object other) => other is SouvletRule && other.mode == mode;

  @override
  int get hashCode => mode.hashCode;

  @override
  String toString() => 'SouvletRule.${mode.name}';
}
