import 'package:dhamet_engine/dhamet_engine.dart';

/// Strength of the computer opponent.
enum AiLevel { easy, medium, hard, expert }

/// Who plays a game.
sealed class GameMode {
  const GameMode();

  /// Stable identifier, used in saved games and analytics.
  String get id;

  /// Whether both sides are played on this device.
  bool get isLocal;

  Map<String, Object?> toJson();

  static GameMode fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw FormatException('mode: expected an object', json);
    }
    return switch (json['type']) {
      'local' => const LocalMode(),
      'ai' => AiMode(
        level: AiLevel.values.byName(json['level']! as String),
        humanSide: Player.fromJson(json['humanSide']),
      ),
      _ => throw FormatException('mode: unknown type', json['type']),
    };
  }
}

/// Two players on the same device.
final class LocalMode extends GameMode {
  const LocalMode();

  @override
  String get id => 'local';

  @override
  bool get isLocal => true;

  @override
  Map<String, Object?> toJson() => {'type': 'local'};

  @override
  bool operator ==(Object other) => other is LocalMode;

  @override
  int get hashCode => 0;
}

/// A player against the computer.
final class AiMode extends GameMode {
  const AiMode({required this.level, required this.humanSide});

  final AiLevel level;
  final Player humanSide;

  Player get aiSide => humanSide.opponent;

  @override
  String get id => 'ai';

  @override
  bool get isLocal => true;

  @override
  Map<String, Object?> toJson() => {
    'type': 'ai',
    'level': level.name,
    'humanSide': humanSide.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is AiMode && other.level == level && other.humanSide == humanSide;

  @override
  int get hashCode => Object.hash(level, humanSide);
}
