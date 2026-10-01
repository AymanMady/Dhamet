import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

/// Stores [AppSettings] in the platform key-value store.
class SettingsRepository {
  SettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _prefix = 'settings.';

  AppSettings load() {
    const defaults = AppSettings();
    bool flag(String key, bool fallback) =>
        _preferences.getBool('$_prefix$key') ?? fallback;
    final themeName = _preferences.getString('${_prefix}themeMode');
    return AppSettings(
      language: AppLanguage.fromCode(
        _preferences.getString('${_prefix}language'),
      ),
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => defaults.themeMode,
      ),
      soundEnabled: flag('soundEnabled', defaults.soundEnabled),
      hapticsEnabled: flag('hapticsEnabled', defaults.hapticsEnabled),
      animationsEnabled: flag('animationsEnabled', defaults.animationsEnabled),
      showCoordinates: flag('showCoordinates', defaults.showCoordinates),
      showMoveHints: flag('showMoveHints', defaults.showMoveHints),
      developerMode: flag('developerMode', defaults.developerMode),
      showPerformanceOverlay: flag(
        'showPerformanceOverlay',
        defaults.showPerformanceOverlay,
      ),
      analyticsConsent: flag('analyticsConsent', defaults.analyticsConsent),
      serverUrl:
          _preferences.getString('${_prefix}serverUrl') ?? defaults.serverUrl,
    );
  }

  Future<void> save(AppSettings settings) async {
    final language = settings.language;
    if (language == null) {
      await _preferences.remove('${_prefix}language');
    } else {
      await _preferences.setString('${_prefix}language', language.code);
    }
    await _preferences.setString(
      '${_prefix}themeMode',
      settings.themeMode.name,
    );
    final flags = {
      'soundEnabled': settings.soundEnabled,
      'hapticsEnabled': settings.hapticsEnabled,
      'animationsEnabled': settings.animationsEnabled,
      'showCoordinates': settings.showCoordinates,
      'showMoveHints': settings.showMoveHints,
      'developerMode': settings.developerMode,
      'showPerformanceOverlay': settings.showPerformanceOverlay,
      'analyticsConsent': settings.analyticsConsent,
    };
    for (final entry in flags.entries) {
      await _preferences.setBool('$_prefix${entry.key}', entry.value);
    }
    // Only an address chosen by the user is kept: the build's default may
    // change with an update (a release without a server, then one with).
    if (settings.serverUrl == AppSettings.defaultServerUrl) {
      await _preferences.remove('${_prefix}serverUrl');
    } else {
      await _preferences.setString('${_prefix}serverUrl', settings.serverUrl);
    }
  }
}
