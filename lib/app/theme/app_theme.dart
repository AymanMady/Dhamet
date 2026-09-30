import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Colours of the board, which are not part of Material's colour scheme.
@immutable
class BoardPalette extends ThemeExtension<BoardPalette> {
  const BoardPalette({
    required this.surface,
    required this.surfaceEdge,
    required this.line,
    required this.faintLine,
    required this.highlight,
    required this.capture,
    required this.lastMove,
    required this.coordinates,
  });

  static const light = BoardPalette(
    surface: AppColors.sand200,
    surfaceEdge: AppColors.sand400,
    line: AppColors.earth700,
    faintLine: Color(0x995E432A),
    highlight: AppColors.indigo,
    capture: AppColors.terracotta,
    lastMove: AppColors.gold,
    coordinates: AppColors.earth700,
  );

  static const dark = BoardPalette(
    surface: AppColors.nightSand,
    surfaceEdge: AppColors.sand400,
    line: AppColors.earth900,
    faintLine: Color(0x9933251A),
    highlight: AppColors.indigo,
    capture: AppColors.terracotta,
    lastMove: AppColors.gold,
    coordinates: AppColors.sand200,
  );

  final Color surface;
  final Color surfaceEdge;
  final Color line;

  /// Lines that are traditionally not traced in the sand (rows 2, 4, 6, 8
  /// and columns b, d, f, h), drawn lighter.
  final Color faintLine;
  final Color highlight;
  final Color capture;
  final Color lastMove;
  final Color coordinates;

  @override
  BoardPalette copyWith({Color? surface, Color? line}) => BoardPalette(
    surface: surface ?? this.surface,
    surfaceEdge: surfaceEdge,
    line: line ?? this.line,
    faintLine: faintLine,
    highlight: highlight,
    capture: capture,
    lastMove: lastMove,
    coordinates: coordinates,
  );

  @override
  BoardPalette lerp(BoardPalette? other, double t) {
    if (other == null) return this;
    return BoardPalette(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceEdge: Color.lerp(surfaceEdge, other.surfaceEdge, t)!,
      line: Color.lerp(line, other.line, t)!,
      faintLine: Color.lerp(faintLine, other.faintLine, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      capture: Color.lerp(capture, other.capture, t)!,
      lastMove: Color.lerp(lastMove, other.lastMove, t)!,
      coordinates: Color.lerp(coordinates, other.coordinates, t)!,
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
    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      textTheme: AppTypography.textTheme(base.textTheme),
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
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, AppSpacing.minTouchTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
