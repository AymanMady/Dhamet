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
    expect(ar.piecesCount('white', 0), 'لا عود');
    expect(ar.piecesCount('white', 1), 'عود واحد');
    expect(ar.piecesCount('white', 2), 'عودان');
    expect(ar.piecesCount('white', 3), '3 عودان');
    expect(ar.piecesCount('white', 11), '11 عودًا');
    expect(ar.piecesCount('white', 100), '100 عود');
    expect(ar.piecesCount('black', 0), 'لا بعرة');
    expect(ar.piecesCount('black', 1), 'بعرة واحدة');
    expect(ar.piecesCount('black', 2), 'بعرتان');
    expect(ar.piecesCount('black', 3), '3 بعرات');
    expect(ar.piecesCount('black', 40), '40 بعرة');
    expect(ar.sultansCount(2), 'ظايمتان');
  });

  test('the sides and pieces keep their traditional names', () {
    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(ar.playerWhite, 'العودان');
    expect(ar.playerBlack, 'لبعر');
    expect(ar.pieceWhitePawn, 'عود');
    expect(ar.pieceBlackPawn, 'بعرة');
    expect(ar.pieceWhiteSultan, 'ظايمة العودان');
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(fr.playerWhite, 'Laoudane');
    expect(fr.playerBlack, 'Lebaar');
    expect(fr.pieceBlackSultan, 'Dhayma de Lebaar');
    const banned = [
      'Blanc', 'Noir', 'pièce', 'pion', 'Sultan', 'soldat', //
      'White', 'Black', 'piece', 'pawn', //
      'أبيض', 'أسود', 'قطعة', 'القطع', 'جندي', 'سلطان',
    ];
    for (final file in ['app_fr.arb', 'app_en.arb', 'app_ar.arb']) {
      final json = jsonDecode(
        File('lib/l10n/$file').readAsStringSync(),
      ) as Map<String, Object?>;
      for (final MapEntry(:key, :value) in json.entries) {
        if (key.startsWith('@')) continue;
        // Placeholders such as {piece} are names in the code, not words.
        final text = (value! as String).replaceAll(RegExp(r'\{\w+\}'), '');
        for (final word in banned) {
          expect(
            text.contains(word),
            isFalse,
            reason: '$file: $key still says "$word"',
          );
        }
      }
    }
  });

  test('French and English plurals', () {
    expect(lookupAppLocalizations(const Locale('fr')).movesCount(1), '1 coup');
    expect(
      lookupAppLocalizations(const Locale('fr')).movesCount(12),
      '12 coups',
    );
    expect(
      lookupAppLocalizations(const Locale('en')).piecesCount('white', 1),
      '1 aoud',
    );
    expect(
      lookupAppLocalizations(const Locale('fr')).piecesCount('black', 12),
      '12 baaras',
    );
  });

  test('Hassaniya falls back to Arabic', () {
    final hassaniya = lookupAppLocalizations(const Locale('ar', 'MR'));
    final arabic = lookupAppLocalizations(const Locale('ar'));
    expect(hassaniya.homeNewGame, arabic.homeNewGame);
    expect(hassaniya.tutorialSultanTitle, 'الظايمة');
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
