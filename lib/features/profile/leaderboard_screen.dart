import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/common.dart';
import '../multiplayer/data/api_client.dart';
import '../multiplayer/data/online_models.dart';
import '../multiplayer/presentation/online_controller.dart';
import '../multiplayer/presentation/online_messages.dart';

final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>(
  (ref) => ref.watch(apiClientProvider).leaderboard(),
);

/// Best players by Elo rating.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(onlineControllerProvider.select((s) => s.user?.id));
    final entries = ref.watch(leaderboardProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.leaderboardTitle)),
      body: ScreenFrame(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(leaderboardProvider.future),
          child: entries.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ListView(
              children: [
                Padding(
                  padding: AppSpacing.screen,
                  child: Text(
                    error is ApiException && error.isNetwork
                        ? l10n.onlineErrorNetwork
                        : onlineErrorText(l10n, 'HTTP', '$error'),
                  ),
                ),
              ],
            ),
            data: (entries) => entries.isEmpty
                ? ListView(
                    children: [
                      Padding(
                        padding: AppSpacing.screen,
                        child: Text(l10n.leaderboardEmpty),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: AppSpacing.screen,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final user = entry.user;
                      return Card(
                        color: user.id == me
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${entry.rank}')),
                          title: Text(user.username),
                          subtitle: Text(
                            l10n.leaderboardRecord(
                              user.wins,
                              user.losses,
                              user.draws,
                            ),
                          ),
                          trailing: Text(
                            '${user.rating}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
