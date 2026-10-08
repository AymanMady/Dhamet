import 'dart:math';

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/game_mode.dart';
import '../controllers/game_controller.dart';
import '../pieces/piece_icon.dart';

enum _SideChoice { white, black, random }

/// Difficulty and side before a game against the computer.
class AiSetupScreen extends ConsumerStatefulWidget {
  const AiSetupScreen({super.key});

  @override
  ConsumerState<AiSetupScreen> createState() => _AiSetupScreenState();
}

class _AiSetupScreenState extends ConsumerState<AiSetupScreen> {
  AiLevel _level = AiLevel.medium;
  _SideChoice _side = _SideChoice.white;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiSetupTitle)),
      body: ScreenFrame(
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            Text(l10n.difficultyTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final level in AiLevel.values)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _LevelTile(
                  title: l10n.levelName(level),
                  description: l10n.levelDescription(level),
                  selected: level == _level,
                  onTap: () => setState(() => _level = level),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.sideTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<_SideChoice>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _SideChoice.white,
                  icon: const PieceIcon(Piece.whitePawn, size: 22),
                  label: OneLineLabel(l10n.playerWhite),
                ),
                ButtonSegment(
                  value: _SideChoice.black,
                  icon: const PieceIcon(Piece.blackPawn, size: 22),
                  label: OneLineLabel(l10n.playerBlack),
                ),
                ButtonSegment(
                  value: _SideChoice.random,
                  icon: const Icon(Icons.shuffle),
                  label: OneLineLabel(l10n.sideRandom),
                ),
              ],
              selected: {_side},
              onSelectionChanged: (selection) =>
                  setState(() => _side = selection.single),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.whiteStarts,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.startGame),
              onPressed: _start,
            ),
          ],
        ),
      ),
    );
  }

  void _start() {
    final humanSide = switch (_side) {
      _SideChoice.white => Player.white,
      _SideChoice.black => Player.black,
      _SideChoice.random => Random().nextBool() ? Player.white : Player.black,
    };
    ref
        .read(gameControllerProvider.notifier)
        .startAgainstAi(level: _level, humanSide: humanSide);
    context.go(AppRoutes.game);
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Card(
        color: selected ? scheme.primaryContainer : null,
        margin: EdgeInsets.zero,
        child: ListTile(
          minTileHeight: AppSpacing.minTouchTarget,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(description),
          trailing: Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? scheme.primary : scheme.outline,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
