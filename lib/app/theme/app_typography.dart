import 'package:flutter/material.dart';

/// Text styles. Body text uses the platform font, which covers Latin and
/// Arabic scripts; titles use the bundled Kufi display font.
abstract final class AppTypography {
  static const String displayFamily = 'ReemKufi';

  /// The game's name, ظامت, on the splash and home screens.
  static const TextStyle logo = TextStyle(
    fontFamily: displayFamily,
    fontSize: 72,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  static TextTheme textTheme(TextTheme base) => base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontFamily: displayFamily,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontFamily: displayFamily,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontFamily: displayFamily,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
  );
}
