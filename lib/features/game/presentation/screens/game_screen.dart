import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/common.dart';
import '../../../settings/presentation/settings_controller.dart';
import '../../domain/game_mode.dart';
import '../../domain/game_session.dart';
import '../controllers/game_controller.dart';
import '../widgets/board_view.dart';
import '../widgets/game_panels.dart';

/// A local game: against a friend on the same device or against the AI.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Move? _focusedChoice;
  bool _showDeveloperPanel = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(gameControllerProvider);
    final settings = ref.watch(settingsProvider);
    ref.listen(gameControllerProvider.select((s) => s?.isOver ?? false), (
      previous,
      over,
    ) {
      if (over && previous == false) {
        _showResultSoon(settings.animationsEnabled);
      }
    });
    ref.listen(gameControllerProvider.select((s) => s?.pendingChoices), (_, _) {
      if (_focusedChoice != null) setState(() => _focusedChoice = null);
    });

    if (session == null) {
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

    final controller = ref.read(gameControllerProvider.notifier);
    final state = session.state;
    final flipped = session.humanSide == Player.black;
    final topPlayer = flipped ? Player.white : Player.black;
    final animate =
        settings.animationsEnabled && !MediaQuery.of(context).disableAnimations;
    final mustCapture = session.isHumanTurn && state.mustCapture;

    final board = AspectRatio(
      aspectRatio: 1,
      child: DhametBoard(
        state: state,
        selected: session.selected,
        targets: session.selectedMoves,
        mustCaptureFrom: mustCapture ? session.movablePieces : const {},
        focusedMove: _focusedChoice,
        onTap: controller.tap,
        flipped: flipped,
        showCoordinates: settings.showCoordinates || settings.developerMode,
        showHints: settings.showMoveHints,
        animate: animate,
        intersectionLabel: (position, piece, {required isTarget}) {
          final base = piece == null
              ? l10n.semanticsIntersection(position.notation)
              : l10n.semanticsPiece(position.notation, l10n.pieceName(piece));
          return isTarget ? l10n.semanticsTarget(base) : base;
        },
      ),
    );

    Widget panel(Player player) => PlayerPanel(
      player: player,
      name: _playerLabel(l10n, session, player),
      board: state.board,
      active: !session.isOver && state.currentPlayer == player,
    );

    final status = _StatusArea(
      session: session,
      mustCapture: mustCapture,
      focusedChoice: _focusedChoice,
      onFocusChoice: (move) => setState(() => _focusedChoice = move),
      onConfirmChoice: () {
        final move = _focusedChoice;
        if (move != null) controller.choose(move);
      },
      onCancelChoice: controller.cancelChoice,
    );

    final actions = _ActionBar(
      canUndo: controller.canUndo,
      canRedo: controller.canRedo,
      isOver: session.isOver,
      onUndo: controller.undo,
      onRedo: controller.redo,
      onResign: () => _confirmResign(controller),
      onShowResult: () => context.push(AppRoutes.result),
    );

    final developer = settings.developerMode && _showDeveloperPanel
        ? DeveloperPanel(state: state, aiDuration: session.lastAiDuration)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          PopupMenuButton<_MenuAction>(
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onSelected: (action) => _onMenu(action, controller),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MenuAction.restart,
                child: Text(l10n.restart),
              ),
              PopupMenuItem(
                value: _MenuAction.settings,
                child: Text(l10n.homeSettings),
              ),
              if (settings.developerMode)
                PopupMenuItem(
                  value: _MenuAction.developer,
                  child: Text(l10n.devPanelTitle),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > constraints.maxHeight * 1.15;
            if (wide) {
              return Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: AppSpacing.screen,
                      child: Center(child: board),
                    ),
                  ),
                  SizedBox(
                    width: 360,
                    child: ListView(
                      padding: AppSpacing.screen,
                      children: [
                        panel(topPlayer),
                        const SizedBox(height: AppSpacing.sm),
                        status,
                        const SizedBox(height: AppSpacing.sm),
                        panel(topPlayer.opponent),
                        const SizedBox(height: AppSpacing.md),
                        actions,
                        if (developer != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          developer,
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }
            return ScreenFrame(
              maxWidth: 640,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: panel(topPlayer),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: status,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Center(child: board),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: panel(topPlayer.opponent),
                  ),
                  Padding(padding: AppSpacing.screen, child: actions),
                  if (developer != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: developer,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _playerLabel(
    AppLocalizations l10n,
    GameSession session,
    Player player,
  ) {
    final mode = session.mode;
    return switch (mode) {
      LocalMode() => l10n.playerName(player),
      AiMode(:final humanSide, :final level) =>
        player == humanSide
            ? '${l10n.playerYou} · ${l10n.playerName(player)}'
            : l10n.playerAi(l10n.levelName(level)),
    };
  }

  void _showResultSoon(bool animations) {
    Future<void>.delayed(Duration(milliseconds: animations ? 1200 : 300), () {
      if (mounted) context.push(AppRoutes.result);
    });
  }

  Future<void> _confirmResign(GameController controller) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.resignTitle,
      body: l10n.resignBody,
      confirmLabel: l10n.resign,
      cancelLabel: l10n.cancel,
    );
    if (confirmed) controller.resign();
  }

  Future<void> _onMenu(_MenuAction action, GameController controller) async {
    final l10n = context.l10n;
    switch (action) {
      case _MenuAction.restart:
        final confirmed = await confirmDialog(
          context,
          title: l10n.restartTitle,
          body: l10n.restartBody,
          confirmLabel: l10n.restart,
          cancelLabel: l10n.cancel,
        );
        if (confirmed) controller.restart();
      case _MenuAction.settings:
        await context.push(AppRoutes.settings);
      case _MenuAction.developer:
        setState(() => _showDeveloperPanel = !_showDeveloperPanel);
    }
  }
}

enum _MenuAction { restart, settings, developer }

class _StatusArea extends StatelessWidget {
  const _StatusArea({
    required this.session,
    required this.mustCapture,
    required this.focusedChoice,
    required this.onFocusChoice,
    required this.onConfirmChoice,
    required this.onCancelChoice,
  });

  final GameSession session;
  final bool mustCapture;
  final Move? focusedChoice;
  final ValueChanged<Move> onFocusChoice;
  final VoidCallback onConfirmChoice;
  final VoidCallback onCancelChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (session.pendingChoices.isNotEmpty) {
      return CaptureChoicePanel(
        choices: session.pendingChoices,
        focused: focusedChoice,
        onFocus: onFocusChoice,
        onConfirm: onConfirmChoice,
        onCancel: onCancelChoice,
      );
    }
    final lastMove = session.state.lastMove;
    final Widget headline;
    if (session.aiThinking) {
      headline = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.aiThinking, style: theme.textTheme.titleMedium),
        ],
      );
    } else if (session.isOver) {
      final result = session.result!;
      headline = Text(
        result.isDraw
            ? l10n.resultDraw
            : l10n.resultWinner(l10n.playerName(result.winner!)),
        style: theme.textTheme.titleMedium,
      );
    } else if (mustCapture) {
      headline = Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: AppRadius.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                l10n.mustCapture,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final current = session.state.currentPlayer;
      headline = Text(
        session.humanSide == current
            ? l10n.yourTurn
            : l10n.turnOf(l10n.playerName(current)),
        style: theme.textTheme.titleMedium,
      );
    }
    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          headline,
          if (lastMove != null)
            Text(
              l10n.lastMoveLabel(lastMove.notation),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
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
          child: OutlinedButton.icon(
            onPressed: canUndo ? onUndo : null,
            icon: const Icon(Icons.undo),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.undo)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canRedo ? onRedo : null,
            icon: const Icon(Icons.redo),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.redo)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: isOver
              ? FilledButton.icon(
                  onPressed: onShowResult,
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.showResult),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: onResign,
                  icon: const Icon(Icons.flag_outlined),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.resign),
                  ),
                ),
        ),
      ],
    );
  }
}
