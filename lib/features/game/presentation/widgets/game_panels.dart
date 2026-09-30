import 'dart:convert';

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/l10n.dart';
import 'piece_painter.dart';

/// One side: name, remaining pieces and Sultans, and whether it is to move.
class PlayerPanel extends StatelessWidget {
  const PlayerPanel({
    super.key,
    required this.player,
    required this.name,
    required this.board,
    required this.active,
    this.trailing,
  });

  final Player player;
  final String name;
  final Board board;
  final bool active;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pieces = board.count(player);
    final sultans = board.count(player, type: PieceType.sultan);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: active ? scheme.primaryContainer : scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: active ? scheme.primary : scheme.outlineVariant,
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          PieceIcon(Piece.of(player, PieceType.pawn), size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${l10n.piecesCount(pieces)} · ${l10n.sultansCount(sultans)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (active)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: AppRadius.button,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 16, color: scheme.onPrimary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.toMove,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Lets the player pick one of several capture sequences ending on the same
/// intersection, previewing the chosen one on the board.
class CaptureChoicePanel extends StatelessWidget {
  const CaptureChoicePanel({
    super.key,
    required this.choices,
    required this.focused,
    required this.onFocus,
    required this.onConfirm,
    required this.onCancel,
  });

  final List<Move> choices;
  final Move? focused;
  final ValueChanged<Move> onFocus;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.chooseCapture,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final move in choices)
                  ChoiceChip(
                    label: Text(
                      l10n.captureOption(move.notation, move.captureCount),
                      textDirection: TextDirection.ltr,
                    ),
                    selected: move == focused,
                    onSelected: (_) => onFocus(move),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onCancel, child: Text(l10n.cancel)),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: focused == null ? null : onConfirm,
                  child: Text(l10n.confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Developer information: plies, AI timing, legal moves and the state JSON.
class DeveloperPanel extends StatelessWidget {
  const DeveloperPanel({super.key, required this.state, this.aiDuration});

  final GameState state;
  final Duration? aiDuration;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mono = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontFamily: 'monospace');
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(l10n.devPanelTitle),
        childrenPadding: const EdgeInsets.all(AppSpacing.sm),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.devPly(state.plyCount)),
          if (aiDuration != null)
            Text(l10n.devAiTime(aiDuration!.inMilliseconds)),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.devLegalMoves(state.legalMoves.length)),
          SelectableText(
            state.legalMoves.map((m) => m.toString()).join('  '),
            style: mono,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.devState),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: SingleChildScrollView(
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(state.toJson()),
                style: mono,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
