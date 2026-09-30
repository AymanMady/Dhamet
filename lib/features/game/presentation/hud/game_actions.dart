import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/wood_button.dart';

/// The planks under the board: undo, redo, and resign (or, once the game
/// is over, the result).
class GameActions extends StatelessWidget {
  const GameActions({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.isOver,
    required this.onUndo,
    required this.onRedo,
    required this.onResign,
    required this.onShowResult,
  });

  final bool canUndo;
  final bool canRedo;
  final bool isOver;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onResign;
  final VoidCallback onShowResult;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: WoodButton(
            label: l10n.undo,
            icon: Icons.undo,
            onPressed: canUndo ? onUndo : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: WoodButton(
            label: l10n.redo,
            icon: Icons.redo,
            onPressed: canRedo ? onRedo : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: isOver
              ? WoodButton(
                  label: l10n.showResult,
                  icon: Icons.emoji_events_outlined,
                  emphasis: true,
                  onPressed: onShowResult,
                )
              : WoodButton(
                  label: l10n.resign,
                  icon: Icons.flag_outlined,
                  onPressed: onResign,
                ),
        ),
      ],
    );
  }
}
