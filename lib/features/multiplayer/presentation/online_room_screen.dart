import 'package:dhamet_engine/dhamet_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/common.dart';
import '../../game/presentation/pieces/piece_icon.dart';
import '../data/online_models.dart';
import 'online_controller.dart';

/// The waiting room: share the code, get ready.
class OnlineRoomScreen extends ConsumerWidget {
  const OnlineRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final online = ref.watch(onlineControllerProvider);
    final controller = ref.read(onlineControllerProvider.notifier);
    ref.listen(onlineControllerProvider.select((s) => s.gameId), (
      previous,
      id,
    ) {
      if (id != null && id != previous) {
        context.pushReplacement(AppRoutes.onlineGame);
      }
    });

    final room = online.room;
    if (room == null) {
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
    final me = online.user == null ? null : room.playerOf(online.user!.id);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onlineRoomTitle(room.code))),
      body: ScreenFrame(
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            Text(l10n.onlineShareCode, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: SelectableText(
                room.code,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.displaySmall?.copyWith(
                  letterSpacing: 8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(l10n.onlineCopy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: room.code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.onlineCopied)));
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final player in room.players)
              Card(
                child: ListTile(
                  leading: player.color == null
                      ? const Icon(Icons.person)
                      : PieceIcon(Piece.of(player.color!, PieceType.pawn)),
                  title: Text(
                    player.user.id == room.hostId
                        ? '${player.user.username} · ${l10n.onlineHost}'
                        : player.user.username,
                  ),
                  subtitle: Text(l10n.onlineRating(player.user.rating)),
                  trailing: _PlayerStatus(player),
                ),
              ),
            if (room.players.length < 2)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: AppSpacing.sm),
                    Text(l10n.onlineWaitingOpponent),
                  ],
                ),
              ),
            if (room.rated)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(l10n.onlineRated),
              ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              icon: Icon(me?.ready == true ? Icons.check_circle : Icons.check),
              onPressed: me == null
                  ? null
                  : () => controller.setReady(!me.ready),
              label: Text(
                me?.ready == true ? l10n.onlinePlayerReady : l10n.onlineReady,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              onPressed: () {
                controller.leaveRoom();
                context.go(AppRoutes.online);
              },
              label: Text(l10n.onlineLeave),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerStatus extends StatelessWidget {
  const _PlayerStatus(this.player);

  final RoomPlayer player;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, label) = !player.connected
        ? (Icons.cloud_off_outlined, l10n.onlinePlayerAway)
        : player.ready
        ? (Icons.check_circle, l10n.onlinePlayerReady)
        : (Icons.hourglass_empty, l10n.onlinePlayerNotReady);
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}
