import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/art/game_art.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/sand/sand_texture.dart';
import '../../../../core/widgets/wood_button.dart';
import '../board/sand_marks.dart';

/// What the player chose in the pause menu; closing it resumes the game.
enum PauseAction { restart, settings, leave }

Future<PauseAction?> showPauseMenu(BuildContext context) =>
    showDialog<PauseAction>(
      context: context,
      builder: (context) => const PauseMenu(),
    );

/// The pause menu: a patch of sand framed with wood, with a plank for each
/// choice.
class PauseMenu extends StatelessWidget {
  const PauseMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.boardPalette;
    final art = GameArtScope.of(context);
    const radius = BorderRadius.all(Radius.circular(18));
    void choose(PauseAction? action) => Navigator.of(context).pop(action);
    const gap = SizedBox(height: AppSpacing.sm);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.plankDark, width: 5),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: CustomPaint(
              painter: art == null
                  ? SandPainter(palette: palette, seed: 21, ripples: 0.4)
                  : SandImagePainter(image: art.sand, palette: palette),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg - 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.pause,
                        textAlign: TextAlign.center,
                        style: engravedStyle(palette, 30),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    WoodButton(
                      label: l10n.homeResume,
                      icon: Icons.play_arrow,
                      emphasis: true,
                      onPressed: () => choose(null),
                    ),
                    gap,
                    WoodButton(
                      label: l10n.restart,
                      icon: Icons.restart_alt,
                      onPressed: () => choose(PauseAction.restart),
                    ),
                    gap,
                    WoodButton(
                      label: l10n.homeSettings,
                      icon: Icons.settings_outlined,
                      onPressed: () => choose(PauseAction.settings),
                    ),
                    gap,
                    WoodButton(
                      label: l10n.backHome,
                      icon: Icons.home_outlined,
                      onPressed: () => choose(PauseAction.leave),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
