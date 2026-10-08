import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Languages offered by the app. [hassaniya] uses the `ar_MR` locale, so
/// any string not yet translated falls back to Arabic (and the layout is
/// right-to-left).
enum AppLanguage {
  arabic('ar'),
  hassaniya('ar', 'MR'),
  french('fr'),
  english('en');

  const AppLanguage(this.languageCode, [this.countryCode]);

  final String languageCode;
  final String? countryCode;

  Locale get locale => Locale(languageCode, countryCode);

  String get code =>
      countryCode == null ? languageCode : '${languageCode}_$countryCode';

  static AppLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}

/// User preferences, persisted on the device.
@immutable
class AppSettings {
  const AppSettings({
    this.language,
    this.themeMode = ThemeMode.system,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.animationsEnabled = true,
    this.showCoordinates = false,
    this.showMoveHints = true,
    this.analyticsConsent = false,
    this.serverUrl = defaultServerUrl,
  });

  /// The multiplayer server of this build, set with
  /// `--dart-define=DHAMET_SERVER=https://…` (see docs/release.md). Debug
  /// builds default to the development machine, which Android emulators
  /// reach through 10.0.2.2; a release build without a server has no online
  /// play.
  static const String defaultServerUrl = String.fromEnvironment(
    'DHAMET_SERVER',
    defaultValue: kReleaseMode ? '' : 'http://10.0.2.2:3000',
  );

  /// `null` follows the device language.
  final AppLanguage? language;
  final ThemeMode themeMode;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool animationsEnabled;
  final bool showCoordinates;

  /// Highlight the legal destinations of the selected piece.
  final bool showMoveHints;

  /// Anonymous usage statistics; off until the user explicitly agrees.
  final bool analyticsConsent;

  /// Base URL of the multiplayer server; empty when there is none.
  final String serverUrl;

  bool get onlineAvailable => serverUrl.isNotEmpty;

  AppSettings copyWith({
    AppLanguage? Function()? language,
    ThemeMode? themeMode,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? animationsEnabled,
    bool? showCoordinates,
    bool? showMoveHints,
    bool? analyticsConsent,
    String? serverUrl,
  }) => AppSettings(
    language: language == null ? this.language : language(),
    themeMode: themeMode ?? this.themeMode,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    showCoordinates: showCoordinates ?? this.showCoordinates,
    showMoveHints: showMoveHints ?? this.showMoveHints,
    analyticsConsent: analyticsConsent ?? this.analyticsConsent,
    serverUrl: serverUrl ?? this.serverUrl,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.language == language &&
      other.themeMode == themeMode &&
      other.soundEnabled == soundEnabled &&
      other.hapticsEnabled == hapticsEnabled &&
      other.animationsEnabled == animationsEnabled &&
      other.showCoordinates == showCoordinates &&
      other.showMoveHints == showMoveHints &&
      other.analyticsConsent == analyticsConsent &&
      other.serverUrl == serverUrl;

  @override
  int get hashCode => Object.hash(
    language,
    themeMode,
    soundEnabled,
    hapticsEnabled,
    animationsEnabled,
    showCoordinates,
    showMoveHints,
    analyticsConsent,
    serverUrl,
  );
}
