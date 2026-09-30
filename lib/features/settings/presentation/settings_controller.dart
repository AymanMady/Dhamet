import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

/// The platform key-value store, provided in `main` once loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> update(AppSettings Function(AppSettings) change) async {
    state = change(state);
    await ref.read(settingsRepositoryProvider).save(state);
  }
}
