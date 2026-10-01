import 'package:flutter/material.dart';

import '../../app/brand.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

/// Centres content with a comfortable maximum width (tablets, landscape).
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.child, this.maxWidth = 520});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    ),
  );
}

/// A large, clearly labelled menu entry.
class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.description,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String? description;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = primary ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: primary ? scheme.primary : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.button,
        side: primary
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              children: [
                Icon(icon, color: primary ? foreground : scheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (description != null)
                        Text(
                          description!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: foreground.withValues(alpha: 0.75),
                              ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: foreground.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small alquerque pattern, the motif the Dhamet board is made of.
class AlquerqueMotif extends StatelessWidget {
  const AlquerqueMotif({super.key, this.size = 64, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _AlquerquePainter(color ?? AppColors.gold),
    ),
  );
}

class _AlquerquePainter extends CustomPainter {
  _AlquerquePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / 4;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i <= 4; i++) {
      canvas
        ..drawLine(Offset(i * step, 0), Offset(i * step, size.height), paint)
        ..drawLine(Offset(0, i * step), Offset(size.width, i * step), paint);
    }
    canvas
      ..drawLine(Offset.zero, Offset(size.width, size.height), paint)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
    final mid = size.width / 2;
    final diamond = Path()
      ..moveTo(mid, 0)
      ..lineTo(size.width, mid)
      ..lineTo(mid, size.height)
      ..lineTo(0, mid)
      ..close();
    canvas.drawPath(diamond, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_AlquerquePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The app's logo: a Sultan planted in a board drawn in the sand.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      Brand.logoAsset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => SizedBox.square(
        dimension: size,
        child: Center(child: AlquerqueMotif(size: size * 0.7)),
      ),
    ),
  );
}

/// Asks for confirmation; resolves to `true` when confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
