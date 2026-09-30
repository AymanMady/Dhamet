import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/game/data/file_game_archive.dart';
import 'features/game/data/game_archive.dart';
import 'features/settings/presentation/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/fonts/OFL-ReemKufi.txt',
    );
    yield LicenseEntryWithLineBreaks(const ['Reem Kufi'], license);
  });
  final preferences = await SharedPreferences.getInstance();
  final documents = await getApplicationDocumentsDirectory();
  final archive = FileGameArchive(Directory('${documents.path}/dhamet'));
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        gameArchiveProvider.overrideWithValue(archive),
      ],
      child: const DhametApp(),
    ),
  );
}
