import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/common.dart';
import '../../data/game_archive.dart';
import '../../data/saved_game.dart';
import '../controllers/game_controller.dart';

/// The unfinished game saved on the device, if any.
final currentSavedGameProvider = FutureProvider.autoDispose<SavedGame?>(
  (ref) => ref.watch(gameArchiveProvider).loadCurrent(),
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final session = ref.watch(gameControllerProvider);
    final saved = ref.watch(currentSavedGameProvider).value;
    final controller = ref.read(gameControllerProvider.notifier);

    // A game in memory takes precedence over the saved copy.
    final resumable = session != null
        ? (session.isOver ? null : SavedGame.fromSession(session))
        : saved;

    return Scaffold(
      body: ScreenFrame(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'ظامت',
                textDirection: TextDirection.rtl,
                style: AppTypography.logo.copyWith(
                  fontSize: 56,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Center(
              child: Text(
                'DHAMET',
                style: theme.textTheme.titleMedium?.copyWith(
                  letterSpacing: 8,
                  fontFamily: AppTypography.displayFamily,
                ),
              ),
            ),
            Center(
              child: Text(
                l10n.appTagline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (resumable != null) ...[
              MenuButton(
                icon: Icons.play_circle_outline,
                label: l10n.homeResume,
                description: l10n.homeResumeDetails(
                  l10n.modeName(resumable.mode),
                  resumable.game.state.plyCount ~/ 2 + 1,
                ),
                onPressed: () {
                  if (session == null) controller.resume(resumable);
                  context.go(AppRoutes.game);
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            MenuButton(
              primary: true,
              icon: Icons.add_circle_outline,
              label: l10n.homeNewGame,
              onPressed: () => context.push(AppRoutes.newGame),
            ),
            const SizedBox(height: AppSpacing.sm),
            MenuButton(
              icon: Icons.smart_toy_outlined,
              label: l10n.homePlayAi,
              onPressed: () => context.push(AppRoutes.aiSetup),
            ),
            const SizedBox(height: AppSpacing.sm),
            MenuButton(
              icon: Icons.people_outline,
              label: l10n.homePlayFriend,
              onPressed: () {
                controller.startLocal();
                context.go(AppRoutes.game);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            MenuButton(
              icon: Icons.public,
              label: l10n.homePlayOnline,
              // Enabled with the multiplayer client (phase 9).
              onPressed: null,
            ),
            const SizedBox(height: AppSpacing.sm),
            MenuButton(
              icon: Icons.school_outlined,
              label: l10n.homeHowToPlay,
              onPressed: () => context.push(AppRoutes.tutorial),
            ),
            const SizedBox(height: AppSpacing.sm),
            MenuButton(
              icon: Icons.history,
              label: l10n.homeHistory,
              onPressed: () => context.push(AppRoutes.history),
            ),
            const SizedBox(height: AppSpacing.sm),
            MenuButton(
              icon: Icons.settings_outlined,
              label: l10n.homeSettings,
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }
}
