import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/common.dart';
import '../multiplayer/data/api_client.dart';
import '../multiplayer/data/online_models.dart';
import '../multiplayer/presentation/online_controller.dart';
import '../multiplayer/presentation/online_messages.dart';

final tournamentsProvider = FutureProvider.autoDispose<List<Tournament>>((ref) {
  final token = ref.watch(onlineControllerProvider.select((s) => s.token));
  return ref.watch(apiClientProvider).withToken(token).tournaments();
});

final tournamentProvider = FutureProvider.autoDispose
    .family<Tournament, String>((ref, id) {
      final token = ref.watch(onlineControllerProvider.select((s) => s.token));
      return ref.watch(apiClientProvider).withToken(token).tournament(id);
    });

String tournamentStatusText(AppLocalizations l10n, TournamentStatus status) =>
    switch (status) {
      TournamentStatus.registering => l10n.tournamentStatusRegistering,
      TournamentStatus.running => l10n.tournamentStatusRunning,
      TournamentStatus.finished => l10n.tournamentStatusFinished,
    };

String _errorText(AppLocalizations l10n, Object error) =>
    error is ApiException && error.isNetwork
    ? l10n.onlineErrorNetwork
    : onlineErrorText(l10n, 'HTTP', '$error');

/// Tournaments list and creation.
class TournamentsScreen extends ConsumerWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tournaments = ref.watch(tournamentsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tournamentsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.tournamentCreate),
        onPressed: () => _create(context, ref),
      ),
      body: ScreenFrame(
        child: tournaments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(_errorText(l10n, error))),
          data: (tournaments) => tournaments.isEmpty
              ? Center(child: Text(l10n.tournamentsEmpty))
              : ListView(
                  padding: AppSpacing.screen,
                  children: [
                    for (final tournament in tournaments)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.emoji_events_outlined),
                          title: Text(tournament.name),
                          subtitle: Text(
                            '${tournamentStatusText(l10n, tournament.status)} · '
                            '${l10n.tournamentPlayers(tournament.players.length)}',
                          ),
                          onTap: () =>
                              context.push(AppRoutes.tournament(tournament.id)),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = TextEditingController();
    var maxPlayers = 4;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.tournamentCreate),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: l10n.tournamentName),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.tournamentMaxPlayers),
              Slider(
                value: maxPlayers.toDouble(),
                min: 2,
                max: 16,
                divisions: 14,
                label: '$maxPlayers',
                onChanged: (value) =>
                    setState(() => maxPlayers = value.round()),
              ),
              Text(l10n.tournamentRoundRobin),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
    final text = name.text.trim();
    name.dispose();
    if (confirmed != true || text.isEmpty) return;
    final token = ref.read(onlineControllerProvider).token;
    try {
      final tournament = await ref
          .read(apiClientProvider)
          .withToken(token)
          .createTournament(name: text, maxPlayers: maxPlayers);
      ref.invalidate(tournamentsProvider);
      if (context.mounted) context.push(AppRoutes.tournament(tournament.id));
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorText(l10n, error))));
      }
    }
  }
}

/// Registration, rounds and standings of one tournament.
class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final online = ref.watch(onlineControllerProvider);
    final tournament = ref.watch(tournamentProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tournamentsTitle)),
      body: ScreenFrame(
        maxWidth: 640,
        child: tournament.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(_errorText(l10n, error))),
          data: (tournament) {
            final me = online.user?.id;
            final registered = tournament.players.any((p) => p.user.id == me);
            final isCreator = tournament.createdBy.id == me;
            Future<void> act(
              Future<Tournament> Function(ApiClient api) action,
            ) async {
              try {
                await action(
                  ref.read(apiClientProvider).withToken(online.token),
                );
                ref.invalidate(tournamentProvider(id));
              } on ApiException catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_errorText(l10n, error))),
                  );
                }
              }
            }

            return ListView(
              padding: AppSpacing.screen,
              children: [
                Text(tournament.name, style: theme.textTheme.headlineSmall),
                Text(
                  '${tournamentStatusText(l10n, tournament.status)} · '
                  '${l10n.tournamentPlayers(tournament.players.length)} / '
                  '${tournament.maxPlayers}',
                ),
                const SizedBox(height: AppSpacing.md),
                if (tournament.status == TournamentStatus.registering) ...[
                  if (!registered)
                    FilledButton(
                      onPressed: () => act((api) => api.joinTournament(id)),
                      child: Text(l10n.tournamentJoin),
                    ),
                  if (isCreator && tournament.players.length >= 2)
                    OutlinedButton(
                      onPressed: () => act((api) => api.startTournament(id)),
                      child: Text(l10n.tournamentStart),
                    ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.tournamentStandings,
                  style: theme.textTheme.titleLarge,
                ),
                for (final (index, player) in tournament.standings.indexed)
                  ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(player.user.username),
                    trailing: Text(
                      l10n.tournamentPoints(
                        player.score == player.score.roundToDouble()
                            ? '${player.score.toInt()}'
                            : player.score.toStringAsFixed(1),
                      ),
                    ),
                  ),
                for (final round in tournament.rounds) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.tournamentRound(round.number),
                    style: theme.textTheme.titleMedium,
                  ),
                  for (final match in round.matches)
                    Card(
                      child: ListTile(
                        title: Text(
                          '${match.white.username} — ${match.black.username}',
                        ),
                        subtitle: match.result == null
                            ? null
                            : Text(
                                match.result!.isDraw
                                    ? l10n.resultDraw
                                    : l10n.resultWinner(
                                        l10n.playerName(match.result!.winner!),
                                      ),
                              ),
                        trailing:
                            match.result == null &&
                                match.roomCode != null &&
                                (match.white.id == me || match.black.id == me)
                            ? FilledButton(
                                onPressed: () async {
                                  final controller = ref.read(
                                    onlineControllerProvider.notifier,
                                  );
                                  await controller.connect();
                                  controller.joinRoom(match.roomCode!);
                                  if (context.mounted) {
                                    context.push(AppRoutes.onlineRoom);
                                  }
                                },
                                child: Text(l10n.tournamentPlayMatch),
                              )
                            : null,
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
