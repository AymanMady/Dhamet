import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/common.dart';
import '../controllers/game_controller.dart';

/// Player vs player, or player vs AI.
class NewGameScreen extends ConsumerWidget {
  const NewGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.modeTitle)),
      body: ScreenFrame(
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            MenuButton(
              icon: Icons.people_outline,
              label: l10n.modeLocal,
              description: l10n.modeLocalDescription,
              onPressed: () {
                ref.read(gameControllerProvider.notifier).startLocal();
                context.go(AppRoutes.game);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            MenuButton(
              icon: Icons.smart_toy_outlined,
              label: l10n.modeAi,
              description: l10n.modeAiDescription,
              onPressed: () => context.push(AppRoutes.aiSetup),
            ),
          ],
        ),
      ),
    );
  }
}
