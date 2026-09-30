import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/sand/sand_background.dart';
import '../../../../core/widgets/sand/sand_plate.dart';
import '../../../../core/widgets/wood_button.dart';
import '../../../settings/presentation/settings_controller.dart';
import '../controllers/game_controller.dart';
import '../pieces/piece_icon.dart';

/// Victory, defeat or draw, with the way to go on.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final session = ref.watch(gameControllerProvider);
    final result = session?.result;
    if (session == null || result == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text(l10n.backHome),
          ),
        ),
      );
    }
    final human = session.humanSide;
    final title = result.isDraw
        ? l10n.resultDraw
        : human != null && result.loser == human
        ? l10n.resultDefeat
        : l10n.resultVictory;
    final subtitle = result.isDraw
        ? l10n.reasonText(result.reason)
        : '${l10n.resultWinner(l10n.playerName(result.winner!))} — '
              '${l10n.reasonText(result.reason)}';
    final animate =
        ref.watch(settingsProvider).animationsEnabled &&
        !MediaQuery.of(context).disableAnimations;
    final emblem = result.isDraw
        ? const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PieceIcon(Piece.whiteSultan, size: 72),
              PieceIcon(Piece.blackSultan, size: 72),
            ],
          )
        : PieceIcon(Piece.of(result.winner!, PieceType.sultan), size: 110);

    final palette = context.boardPalette;
    return Scaffold(
      body: SandBackground(
        child: ScreenFrame(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xxl * 2,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: [
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: animate ? 0 : 1, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: 0.4 + 0.6 * value, child: child),
                  child: emblem,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SandPlate(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontFamily: AppTypography.displayFamily,
                          color: palette.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.movesCount(session.state.plyCount),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.ink.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              WoodButton(
                icon: Icons.replay,
                label: l10n.playAgain,
                emphasis: true,
                onPressed: () {
                  ref.read(gameControllerProvider.notifier).restart();
                  context.go(AppRoutes.game);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              WoodButton(
                icon: Icons.slideshow_outlined,
                label: l10n.viewGame,
                onPressed: () =>
                    context.push(AppRoutes.replay, extra: session.game),
              ),
              const SizedBox(height: AppSpacing.sm),
              WoodButton(
                icon: Icons.home_outlined,
                label: l10n.backHome,
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
