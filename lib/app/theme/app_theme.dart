import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Colours of the sand scene and the board, which are not part of
/// Material's colour scheme. The light theme is the midday sand of the
/// reference art; the dark theme is the same sand at dusk.
@immutable
class BoardPalette extends ThemeExtension<BoardPalette> {
  const BoardPalette({
    required this.sand,
    required this.sandLight,
    required this.sandShade,
    required this.grain,
    required this.groove,
    required this.shadow,
    required this.ink,
    required this.inkGlow,
    required this.highlight,
    required this.capture,
    required this.lastMove,
    required this.sky,
    required this.haze,
    required this.wall,
    required this.dusk,
  });

  static const light = BoardPalette(
    sand: Color(0xFFD7B17B),
    sandLight: Color(0xFFF0D8AA),
    sandShade: Color(0xFFB48750),
    grain: Color(0xFF7E5B34),
    groove: Color(0xFF8E6A40),
    shadow: Color(0xFF3F2814),
    ink: Color(0xFF3A2716),
    inkGlow: Color(0xFFF7E8C8),
    highlight: AppColors.indigo,
    capture: Color(0xFFA8401C),
    lastMove: AppColors.gold,
    sky: Color(0xFFC9DCE6),
    haze: Color(0xFFF1E3C9),
    wall: Color(0xFFBC9165),
    dusk: Color(0x00000000),
  );

  static const dark = BoardPalette(
    sand: Color(0xFF9C8160),
    sandLight: Color(0xFFC2A67E),
    sandShade: Color(0xFF6C553B),
    grain: Color(0xFF45331F),
    groove: Color(0xFF4F3B26),
    shadow: Color(0xFF140D07),
    ink: Color(0xFFF6ECD9),
    inkGlow: Color(0xFF241810),
    highlight: Color(0xFF9DBBE3),
    capture: Color(0xFFE8825A),
    lastMove: AppColors.goldLight,
    sky: Color(0xFF1D2542),
    haze: Color(0xFFC98A5D),
    wall: Color(0xFF4C3A29),
    dusk: Color(0x991A1830),
  );

  /// The sand itself, in full sun.
  final Color sand;
  final Color sandLight;
  final Color sandShade;

  /// Dark grains scattered in the sand.
  final Color grain;

  /// Bottom of the lines traced in the sand.
  final Color groove;

  /// Shadows cast by the pieces (used with transparency).
  final Color shadow;

  /// Text written on the sand, and the edge that makes it look engraved.
  final Color ink;
  final Color inkGlow;

  /// Selection and possible destinations (the indigo of the melhfa).
  final Color highlight;

  /// Captures (red ochre).
  final Color capture;
  final Color lastMove;

  /// The blurred horizon behind the board: sky, haze and mud-brick walls.
  final Color sky;
  final Color haze;
  final Color wall;

  /// Laid over the daylight photos of the reference art (scene, sand) to
  /// match the theme: transparent at midday, blue-grey at dusk.
  final Color dusk;

  @override
  BoardPalette copyWith({Color? sand, Color? groove}) => BoardPalette(
    sand: sand ?? this.sand,
    sandLight: sandLight,
    sandShade: sandShade,
    grain: grain,
    groove: groove ?? this.groove,
    shadow: shadow,
    ink: ink,
    inkGlow: inkGlow,
    highlight: highlight,
    capture: capture,
    lastMove: lastMove,
    sky: sky,
    haze: haze,
    wall: wall,
    dusk: dusk,
  );

  @override
  BoardPalette lerp(BoardPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return BoardPalette(
      sand: mix(sand, other.sand),
      sandLight: mix(sandLight, other.sandLight),
      sandShade: mix(sandShade, other.sandShade),
      grain: mix(grain, other.grain),
      groove: mix(groove, other.groove),
      shadow: mix(shadow, other.shadow),
      ink: mix(ink, other.ink),
      inkGlow: mix(inkGlow, other.inkGlow),
      highlight: mix(highlight, other.highlight),
      capture: mix(capture, other.capture),
      lastMove: mix(lastMove, other.lastMove),
      sky: mix(sky, other.sky),
      haze: mix(haze, other.haze),
      wall: mix(wall, other.wall),
      dusk: mix(dusk, other.dusk),
    );
  }
}

abstract final class AppTheme {
  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      primary: AppColors.indigo,
      secondary: AppColors.gold,
      tertiary: AppColors.green,
      error: AppColors.terracotta,
      surface: AppColors.sand50,
    ),
    AppColors.sand100,
    BoardPalette.light,
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      brightness: Brightness.dark,
      primary: AppColors.goldLight,
      secondary: AppColors.gold,
      tertiary: AppColors.green,
      error: AppColors.terracotta,
      surface: AppColors.night800,
    ),
    AppColors.night900,
    BoardPalette.dark,
  );

  static ThemeData _build(
    ColorScheme scheme,
    Color scaffold,
    BoardPalette board,
  ) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final textTheme = AppTypography.textTheme(base.textTheme);
    // Button labels derive from the theme so they share its font.
    final buttonText = textTheme.labelLarge?.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w600,
    );
    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      extensions: [board],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.textTheme(base.textTheme).headlineSmall
            ?.copyWith(color: scheme.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          side: BorderSide(color: scheme.outline),
          textStyle: buttonText,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: AppSpacing.sm,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}

extension BoardPaletteContext on BuildContext {
  BoardPalette get boardPalette =>
      Theme.of(this).extension<BoardPalette>() ?? BoardPalette.light;
}
