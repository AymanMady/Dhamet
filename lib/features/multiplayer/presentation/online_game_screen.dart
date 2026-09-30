import 'dart:async';

import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/sand/sand_background.dart';
import '../../../core/widgets/sand/sand_plate.dart';
import '../../../core/widgets/wood_button.dart';
import '../../game/presentation/board/dhamet_board.dart';
import '../../game/presentation/hud/game_panels.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/realtime_client.dart';
import 'online_controller.dart';
import 'online_messages.dart';

/// An online game. No undo: the server decides.
class OnlineGameScreen extends ConsumerStatefulWidget {
  const OnlineGameScreen({super.key});

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  Timer? _ticker;
  Move? _focusedChoice;

  @override
  void initState() {
    super.initState();
    // Clocks and the reconnection countdown tick every second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final online = ref.read(onlineControllerProvider);
      if (mounted &&
          (online.clocks != null || online.opponentAwayUntil != null)) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final online = ref.watch(onlineControllerProvider);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(onlineControllerProvider.notifier);
    final game = online.game;
    final room = online.room;
    if (game == null || room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.online),
            child: Text(l10n.onlineBackToLobby),
          ),
        ),
      );
    }

    final state = game.state;
    final palette = context.boardPalette;
    final me = online.myColor ?? Player.white;
    final now = DateTime.now();
    final result = online.result ?? game.result;
    final mustCapture = online.isMyTurn && state.mustCapture;

    String nameOf(Player player) {
      for (final roomPlayer in room.players) {
        if (roomPlayer.color == player) {
          return '${roomPlayer.user.username} · ${roomPlayer.user.rating}';
        }
      }
      return l10n.playerName(player);
    }

    Widget panel(Player player) {
      final remaining = online.remainingMs(player, now);
      return PlayerPanel(
        player: player,
        name: nameOf(player),
        board: state.board,
        active: result == null && state.currentPlayer == player,
        trailing: remaining == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
                child: Text(
                  formatClock(remaining),
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
      );
    }

    final String status;
    if (result != null) {
      status = result.isDraw
          ? l10n.resultDraw
          : '${result.winner == me ? l10n.resultVictory : l10n.resultDefeat} — '
                '${l10n.reasonText(result.reason)}';
    } else if (online.connection != ConnectionStatus.connected) {
      status = connectionText(l10n, online.connection);
    } else if (online.awaitingServer) {
      status = l10n.onlineSending;
    } else if (online.opponentAwayUntil != null) {
      final seconds = online.opponentAwayUntil!.difference(now).inSeconds;
      status = l10n.onlineOpponentAway(seconds < 0 ? 0 : seconds);
    } else if (mustCapture) {
      status = l10n.mustCapture;
    } else {
      status = online.isMyTurn ? l10n.yourTurn : l10n.onlineOpponentTurn;
    }

    final delta = online.user == null
        ? null
        : online.ratingChanges[online.user!.id];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.ink,
        title: Text(l10n.onlineRoomTitle(room.code)),
      ),
      body: SandBackground(
        child: ScreenFrame(
          maxWidth: 640,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: panel(me.opponent),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: online.pendingChoices.isNotEmpty
                    ? CaptureChoicePanel(
                        choices: online.pendingChoices,
                        focused: _focusedChoice,
                        onFocus: (move) =>
                            setState(() => _focusedChoice = move),
                        onConfirm: () {
                          final move = _focusedChoice;
                          setState(() => _focusedChoice = null);
                          if (move != null) controller.choose(move);
                        },
                        onCancel: controller.cancelChoice,
                      )
                    : Semantics(
                        liveRegion: true,
                        child: SandPlate(
                          tint: mustCapture ? palette.capture : null,
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: palette.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: DhametBoard(
                        state: state,
                        selected: online.selected,
                        targets: online.selectedMoves,
                        mustCaptureFrom: mustCapture
                            ? {for (final m in state.legalMoves) m.from}
                            : const {},
                        focusedMove: _focusedChoice,
                        onTap: controller.tap,
                        flipped: me == Player.black,
                        showCoordinates: settings.showCoordinates,
                        showHints: settings.showMoveHints,
                        animate:
                            settings.animationsEnabled &&
                            !MediaQuery.of(context).disableAnimations,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: panel(me),
              ),
              Padding(
                padding: AppSpacing.screen,
                child: result == null
                    ? WoodButton(
                        icon: Icons.flag_outlined,
                        onPressed: () => _confirmResign(controller),
                        label: l10n.resign,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (delta != null)
                            Center(
                              child: SandPlate(
                                child: Text(
                                  l10n.onlineRatingChange(
                                    delta >= 0 ? '+$delta' : '$delta',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          WoodButton(
                            label: l10n.onlineBackToLobby,
                            emphasis: true,
                            onPressed: () {
                              controller.leaveRoom();
                              context.go(AppRoutes.online);
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          WoodButton(
                            label: l10n.viewGame,
                            onPressed: () =>
                                context.push(AppRoutes.replay, extra: game),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmResign(OnlineController controller) async {
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
}
