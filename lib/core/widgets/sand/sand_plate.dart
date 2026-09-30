import 'package:flutter/material.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';

/// A discreet panel laid on the sand for the game's information, so that
/// text stays legible without hiding the scene. With [highlighted], it is
/// raised and outlined, e.g. for the side to move.
class SandPlate extends StatelessWidget {
  const SandPlate({
    super.key,
    required this.child,
    this.highlighted = false,
    this.tint,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
  });

  final Widget child;
  final bool highlighted;

  /// Colours the plate, e.g. red ochre for a warning.
  final Color? tint;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.boardPalette;
    final base = palette.inkGlow;
    final color = tint == null ? base : Color.lerp(base, tint, 0.22)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlighted ? 0.9 : 0.74),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: highlighted
              ? palette.highlight
              : (tint ?? palette.ink).withValues(
                  alpha: tint == null ? 0.18 : 0.6,
                ),
          width: highlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: highlighted ? 0.3 : 0.14),
            blurRadius: highlighted ? 14 : 6,
            offset: Offset(2, highlighted ? 5 : 2),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: palette.ink),
        child: IconTheme.merge(
          data: IconThemeData(color: palette.ink),
          child: child,
        ),
      ),
    );
  }
}
