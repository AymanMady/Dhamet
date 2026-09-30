import 'dart:convert';

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/sand/sand_plate.dart';
import '../../../../core/widgets/wood_button.dart';
import '../pieces/piece_icon.dart';

/// One side: its piece, name, remaining pieces and Sultans, and whether it
/// is to move. Counts are shown as small piles of pieces, as in the corner
/// of the reference art.
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
    final pieces = board.count(player);
    final sultans = board.count(player, type: PieceType.sultan);
    return SandPlate(
      highlighted: active,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.xs + 2,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => _content(
          context,
          pieces: pieces,
          sultans: sultans,
          // Between the back and pause buttons of a small phone.
          narrow: constraints.maxWidth < 250,
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context, {
    required int pieces,
    required int sultans,
    required bool narrow,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.boardPalette;
    final countStyle = theme.textTheme.titleSmall?.copyWith(
      color: palette.ink,
      fontWeight: FontWeight.w800,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget count(PieceType type, int value) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PieceIcon(Piece.of(player, type), size: 20),
        const SizedBox(width: 2),
        Text('$value', style: countStyle),
      ],
    );
    return Row(
      children: [
        PieceIcon(Piece.of(player, PieceType.pawn), size: narrow ? 30 : 36),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Semantics(
                label:
                    '${l10n.piecesCount(pieces)} · ${l10n.sultansCount(sultans)}',
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      count(PieceType.pawn, pieces),
                      const SizedBox(width: AppSpacing.sm + 4),
                      count(PieceType.sultan, sultans),
                    ],
                  ),
                ),
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
              color: palette.highlight,
              borderRadius: AppRadius.button,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: palette.inkGlow,
                  semanticLabel: narrow ? l10n.toMove : null,
                ),
                if (!narrow) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.toMove,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: palette.inkGlow,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ?trailing,
      ],
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
    final palette = context.boardPalette;
    return SandPlate(
      tint: palette.capture,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.chooseCapture,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: palette.ink),
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
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: palette.ink),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: AppSpacing.sm),
              WoodButton(
                label: l10n.confirm,
                emphasis: true,
                onPressed: focused == null ? null : onConfirm,
              ),
            ],
          ),
        ],
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
