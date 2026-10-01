import 'package:dhamet/features/settings/data/settings_repository.dart';
import 'package:dhamet/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SettingsRepository> repository([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return SettingsRepository(await SharedPreferences.getInstance());
  }

  test('settings survive a save and a load', () async {
    final settings = const AppSettings().copyWith(
      themeMode: ThemeMode.dark,
      soundEnabled: false,
      serverUrl: 'https://example.org',
    );
    final repo = await repository();
    await repo.save(settings);
    expect(repo.load(), settings);
  });

  test('the default server address is not stored', () async {
    // Otherwise a release without a server would keep online play hidden
    // after an update that brings one.
    final repo = await repository({'settings.serverUrl': 'https://old.org'});
    await repo.save(const AppSettings().copyWith(themeMode: ThemeMode.light));
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('settings.serverUrl'), isFalse);
    expect(repo.load().serverUrl, AppSettings.defaultServerUrl);
  });

  test('online play needs a server address', () {
    expect(const AppSettings(serverUrl: '').onlineAvailable, isFalse);
    expect(
      const AppSettings(serverUrl: 'https://example.org').onlineAvailable,
      isTrue,
    );
  });
}
