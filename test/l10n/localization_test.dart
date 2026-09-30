import 'dart:convert';
import 'dart:io';

import 'package:dhamet/core/localization/l10n.dart';
import 'package:dhamet/features/game/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Set<String> messages(String file) {
  final json = jsonDecode(
    File('lib/l10n/$file').readAsStringSync(),
  ) as Map<String, Object?>;
  return {
    for (final key in json.keys)
      if (!key.startsWith('@')) key,
  };
}

void main() {
  test('French, English and Arabic are complete', () {
    final template = messages('app_fr.arb');
    expect(messages('app_en.arb'), template);
    expect(messages('app_ar.arb'), template);
    expect(File('docs/l10n_untranslated.json').readAsStringSync().trim(), '{}');
  });

  test('Hassaniya only overrides existing messages', () {
    expect(
      messages('app_fr.arb').containsAll(messages('app_ar_MR.arb')),
      isTrue,
    );
  });

  test('Arabic plural forms', () {
    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(ar.piecesCount(0), 'لا قطع');
    expect(ar.piecesCount(1), 'قطعة واحدة');
    expect(ar.piecesCount(2), 'قطعتان');
    expect(ar.piecesCount(3), '3 قطع');
    expect(ar.piecesCount(11), '11 قطعة');
    expect(ar.piecesCount(40), '40 قطعة');
    expect(ar.piecesCount(100), '100 قطعة');
  });

  test('French and English plurals', () {
    expect(lookupAppLocalizations(const Locale('fr')).movesCount(1), '1 coup');
    expect(
      lookupAppLocalizations(const Locale('fr')).movesCount(12),
      '12 coups',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).piecesCount(1),
      '1 piece',
    );
  });

  test('Hassaniya falls back to Arabic', () {
    final hassaniya = lookupAppLocalizations(const Locale('ar', 'MR'));
    final arabic = lookupAppLocalizations(const Locale('ar'));
    expect(hassaniya.homeNewGame, arabic.homeNewGame);
    expect(hassaniya.tutorialSultanTitle, 'الظايم (السلطان)');
    expect(hassaniya.localeName, 'ar_MR');
  });

  testWidgets('Hassaniya interface is right to left', (tester) async {
    await pumpApp(tester, preferences: {'settings.language': 'ar_MR'});
    await skipSplash(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    final label = find.text('لعبة جديدة');
    expect(label, findsOneWidget);
    expect(Directionality.of(tester.element(label)), TextDirection.rtl);
    expect(AppLocalizations.of(tester.element(label)).localeName, 'ar_MR');
  });
}
