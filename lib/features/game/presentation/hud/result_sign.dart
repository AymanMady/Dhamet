import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/art/game_art.dart';
import '../../../../core/widgets/wood_button.dart';

/// A plank sign dropped on the board when the game ends.
class ResultSign extends StatelessWidget {
  const ResultSign({
    super.key,
    required this.title,
    this.emblem,
    this.animate = true,
  });

  final String title;
  final Widget? emblem;
  final bool animate;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: animate ? 0 : 1, end: 1),
    duration: const Duration(milliseconds: 650),
    curve: Curves.easeOutBack,
    builder: (context, t, child) => Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, -40 * (1 - t)),
        child: Transform.rotate(angle: -0.03 - 0.1 * (1 - t), child: child),
      ),
    ),
    child: CustomPaint(
      painter: WoodPlankPainter(
        seed: 99,
        emphasis: true,
        photo: GameArtScope.of(context)?.plank,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emblem != null) ...[emblem!, const SizedBox(width: 10)],
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.plankInk,
                  shadows: [
                    Shadow(color: Color(0xB3E9D6B4), offset: Offset(0, 1.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
