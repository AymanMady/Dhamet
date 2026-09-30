import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../art/game_art.dart';

/// A button made of a weathered plank, its label carved in the wood, like
/// the "new game" planks of the reference art. It sinks into the sand when
/// pressed.
class WoodButton extends StatefulWidget {
  const WoodButton({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.emphasis = false,
  }) : tooltip = null;

  /// A square plank bearing only [icon]; [tooltip] names it.
  const WoodButton.icon({
    super.key,
    required IconData this.icon,
    required String this.tooltip,
    required this.onPressed,
  }) : label = null,
       emphasis = false;

  final String? label;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  /// A richer, warmer wood for the main action.
  final bool emphasis;

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final label = widget.label;
    const carved = [Shadow(color: Color(0xB3E9D6B4), offset: Offset(0, 1))];
    final content = label == null
        ? Icon(widget.icon, color: AppColors.plankInk, shadows: carved)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 20,
                  color: AppColors.plankInk,
                  shadows: carved,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.plankInk,
                      shadows: carved,
                    ),
                  ),
                ),
              ),
            ],
          );
    Widget button = Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.5,
        duration: const Duration(milliseconds: 150),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            focusColor: AppColors.goldLight.withValues(alpha: 0.35),
            hoverColor: AppColors.plankLight.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: CustomPaint(
              painter: WoodPlankPainter(
                seed: (label ?? widget.tooltip ?? '').codeUnits.fold(
                  7,
                  (hash, unit) => (hash * 31 + unit) & 0xFFFFF,
                ),
                pressed: _pressed,
                emphasis: widget.emphasis,
                nails: label != null,
                photo: GameArtScope.of(context)?.plank,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget,
                  minWidth: label == null ? AppSpacing.minTouchTarget : 64,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    label == null ? 8 : 16,
                    8,
                    label == null ? 8 : 16,
                    12,
                  ),
                  child: Center(widthFactor: 1, child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final tooltip = widget.tooltip;
    if (tooltip != null) button = Tooltip(message: tooltip, child: button);
    return button;
  }
}

/// Paints a weathered plank lying on the sand: grain, a knot, a lit top
/// edge, two nails and its shadow. The plank fills the size minus a margin
/// below for the shadow.
class WoodPlankPainter extends CustomPainter {
  const WoodPlankPainter({
    required this.seed,
    this.pressed = false,
    this.emphasis = false,
    this.nails = true,
    this.photo,
  });

  final int seed;
  final bool pressed;
  final bool emphasis;
  final bool nails;

  /// The plank cut out of the reference art; without it, the plank is
  /// drawn.
  final ui.Image? photo;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final sink = pressed ? 2.0 : 0.0;
    final rect = Rect.fromLTWH(1, 1 + sink, size.width - 2, size.height - 6);
    Radius corner() => Radius.circular(3 + random.nextDouble() * 6);
    final plank = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: corner(),
          topRight: corner(),
          bottomLeft: corner(),
          bottomRight: corner(),
        ),
      );

    canvas.drawPath(
      plank.shift(Offset(1.5, pressed ? 1.5 : 4)),
      Paint()
        ..color = const Color(0x70301E0E)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, pressed ? 1.5 : 3.5),
    );
    final photo = this.photo;
    if (photo != null) {
      _paintPhoto(canvas, rect, photo);
      return;
    }
    final colors = emphasis
        ? const [Color(0xFFD9B884), Color(0xFFAA814F), Color(0xFF74532F)]
        : const [AppColors.plankLight, AppColors.plank, AppColors.plankDark];
    canvas.drawPath(
      plank,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          colors,
          const [0, 0.55, 1],
        ),
    );

    canvas
      ..save()
      ..clipPath(plank);
    // Grain running along the plank.
    for (var i = 0; i < 8; i++) {
      final y =
          rect.top +
          rect.height * (0.08 + 0.84 * i / 7) +
          (random.nextDouble() - 0.5) * 3;
      final wavelength = 40 + random.nextDouble() * 60;
      final phase = random.nextDouble() * math.pi * 2;
      final grain = Path();
      for (var x = rect.left; x <= rect.right; x += 4) {
        final dy =
            1.3 * math.sin((x - rect.left) / wavelength * math.pi * 2 + phase);
        if (x == rect.left) {
          grain.moveTo(x, y + dy);
        } else {
          grain.lineTo(x, y + dy);
        }
      }
      canvas.drawPath(
        grain,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i.isEven ? 0.9 : 0.6
          ..color = (i.isEven ? AppColors.plankDark : AppColors.plankLight)
              .withValues(alpha: i.isEven ? 0.45 : 0.4),
      );
    }
    if (random.nextDouble() < 0.75) {
      final knot = Offset(
        rect.left + rect.width * (0.15 + random.nextDouble() * 0.7),
        rect.top + rect.height * (0.3 + random.nextDouble() * 0.4),
      );
      for (var ring = 0; ring < 3; ring++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: knot,
            width: 5.0 + ring * 4,
            height: 2.5 + ring * 2,
          ),
          Paint()
            ..style = ring == 0 ? PaintingStyle.fill : PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = AppColors.plankDark.withValues(alpha: 0.5 - ring * 0.1),
        );
      }
    }
    canvas
      ..drawLine(
        rect.topLeft + const Offset(4, 1.5),
        rect.topRight + const Offset(-4, 1.5),
        Paint()
          ..strokeWidth = 1.2
          ..color = const Color(0x59FFFFFF),
      )
      ..restore()
      ..drawPath(
        plank,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.plankInk.withValues(alpha: 0.6),
      );

    if (nails && rect.width > 90) {
      for (final x in [rect.left + 7, rect.right - 7]) {
        final nail = Offset(x, rect.center.dy);
        canvas
          ..drawCircle(nail, 1.8, Paint()..color = const Color(0xFF3B2D22))
          ..drawCircle(
            nail - const Offset(0.5, 0.5),
            0.7,
            Paint()..color = const Color(0x99FFFFFF),
          );
      }
    }
  }

  /// Stretches the photographed plank: its ends keep their proportions and
  /// the middle stretches along the grain.
  void _paintPhoto(Canvas canvas, Rect rect, ui.Image photo) {
    final width = photo.width.toDouble();
    final height = photo.height.toDouble();
    final scale = rect.height / height;
    final slice = Rect.fromLTRB(
      width * 0.18,
      height * 0.3,
      width * 0.82,
      height * 0.7,
    );
    canvas
      ..save()
      ..translate(rect.left, rect.top)
      ..scale(scale)
      ..drawImageNine(
        photo,
        slice,
        Rect.fromLTWH(0, 0, math.max(rect.width / scale, width * 0.37), height),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = emphasis
              ? _warm
              : pressed
              ? _shaded
              : null,
      )
      ..restore();
  }

  static const _warm = ColorFilter.matrix(<double>[
    1.12, 0, 0, 0, 10, //
    0, 1.02, 0, 0, 2, //
    0, 0, 0.82, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  static const _shaded = ColorFilter.matrix(<double>[
    0.88, 0, 0, 0, 0, //
    0, 0.88, 0, 0, 0, //
    0, 0, 0.88, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  bool shouldRepaint(WoodPlankPainter oldDelegate) =>
      oldDelegate.seed != seed ||
      oldDelegate.pressed != pressed ||
      oldDelegate.emphasis != emphasis ||
      oldDelegate.nails != nails ||
      oldDelegate.photo != photo;
}
