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
import '../data/realtime_client.dart';
import 'online_controller.dart';
import 'online_messages.dart';

/// Sign in, then create or join a private room.
class OnlineScreen extends ConsumerStatefulWidget {
  const OnlineScreen({super.key});

  @override
  ConsumerState<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends ConsumerState<OnlineScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  Player? _color;
  bool _rated = false;
  TimeControl? _clock;

  static const _clocks = [
    null,
    TimeControl(initialSeconds: 300),
    TimeControl(initialSeconds: 600, incrementSeconds: 5),
    TimeControl(initialSeconds: 900, incrementSeconds: 10),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectIfSignedIn());
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _connectIfSignedIn() async {
    final controller = ref.read(onlineControllerProvider.notifier);
    if (!ref.read(onlineControllerProvider).signedIn) return;
    await controller.connect();
    await controller.refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final online = ref.watch(onlineControllerProvider);
    final controller = ref.read(onlineControllerProvider.notifier);
    ref.listen(onlineControllerProvider.select((s) => s.signedIn), (
      _,
      signedIn,
    ) {
      if (signedIn) _connectIfSignedIn();
    });
    ref.listen(onlineControllerProvider.select((s) => s.room?.code), (
      previous,
      code,
    ) {
      if (code != null && code != previous) context.push(AppRoutes.onlineRoom);
    });

    final error = online.errorCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onlineTitle)),
      body: ScreenFrame(
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: MaterialBanner(
                  content: Text(
                    onlineErrorText(l10n, error, online.errorMessage),
                  ),
                  actions: [
                    TextButton(
                      onPressed: controller.clearError,
                      child: Text(
                        MaterialLocalizations.of(context).closeButtonLabel,
                      ),
                    ),
                  ],
                ),
              ),
            if (!online.signedIn)
              ..._signIn(context, online, controller)
            else
              ..._lobby(context, online, controller),
          ],
        ),
      ),
    );
  }

  List<Widget> _signIn(
    BuildContext context,
    OnlineState online,
    OnlineController controller,
  ) {
    final l10n = context.l10n;
    return [
      Text(
        l10n.onlineSignInTitle,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _username,
        textDirection: TextDirection.ltr,
        autofillHints: const [AutofillHints.username],
        decoration: InputDecoration(
          labelText: l10n.onlineUsername,
          helperText: l10n.onlineUsernameRule,
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _password,
        obscureText: true,
        textDirection: TextDirection.ltr,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(
          labelText: l10n.onlinePassword,
          helperText: l10n.onlinePasswordRule,
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      FilledButton(
        onPressed: online.busy
            ? null
            : () => controller.signIn(_username.text.trim(), _password.text),
        child: Text(l10n.onlineSignIn),
      ),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton(
        onPressed: online.busy
            ? null
            : () => controller.register(_username.text.trim(), _password.text),
        child: Text(l10n.onlineRegister),
      ),
      const SizedBox(height: AppSpacing.lg),
      const Divider(),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton.icon(
        icon: const Icon(Icons.person_outline),
        onPressed: online.busy ? null : controller.signInAsGuest,
        label: Text(l10n.onlineGuest),
      ),
      if (online.busy)
        const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
    ];
  }

  List<Widget> _lobby(
    BuildContext context,
    OnlineState online,
    OnlineController controller,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = online.user!;
    final connected = online.connection == ConnectionStatus.connected;
    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.account_circle, size: 40),
          title: Text(
            user.isGuest
                ? '${user.username} · ${l10n.onlineGuestBadge}'
                : user.username,
          ),
          subtitle: Text(
            '${l10n.onlineRating(user.rating)}\n'
            '${l10n.leaderboardRecord(user.wins, user.losses, user.draws)}',
          ),
          isThreeLine: true,
          trailing: Chip(
            avatar: Icon(
              connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              size: 18,
            ),
            label: Text(connectionText(l10n, online.connection)),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(l10n.onlineCreateRoom, style: theme.textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      SegmentedButton<Player?>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: Player.white,
            icon: const PieceIcon(Piece.whitePawn, size: 22),
            label: Text(l10n.playerWhite),
          ),
          ButtonSegment(
            value: Player.black,
            icon: const PieceIcon(Piece.blackPawn, size: 22),
            label: Text(l10n.playerBlack),
          ),
          ButtonSegment(
            value: null,
            icon: const Icon(Icons.shuffle),
            label: Text(l10n.sideRandom),
          ),
        ],
        selected: {_color},
        onSelectionChanged: (selection) =>
            setState(() => _color = selection.single),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.onlineRated),
        subtitle: user.isGuest ? Text(l10n.onlineRatedGuestNote) : null,
        value: _rated && !user.isGuest,
        onChanged: user.isGuest
            ? null
            : (value) => setState(() => _rated = value),
      ),
      DropdownButtonFormField<TimeControl?>(
        initialValue: _clock,
        decoration: InputDecoration(
          labelText: l10n.onlineTimeControl,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final clock in _clocks)
            DropdownMenuItem(
              value: clock,
              child: Text(
                clock == null
                    ? l10n.onlineNoClock
                    : l10n.onlineClock(
                        clock.initialSeconds ~/ 60,
                        clock.incrementSeconds,
                      ),
              ),
            ),
        ],
        onChanged: (value) => setState(() => _clock = value),
      ),
      const SizedBox(height: AppSpacing.sm),
      FilledButton.icon(
        icon: const Icon(Icons.add),
        onPressed: connected
            ? () => controller.createRoom(
                color: _color,
                rated: _rated && !user.isGuest,
                timeControl: _clock,
              )
            : null,
        label: Text(l10n.onlineCreateRoom),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(l10n.onlineJoinRoom, style: theme.textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _code,
              textDirection: TextDirection.ltr,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.onlineRoomCode,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: connected ? () => controller.joinRoom(_code.text) : null,
            child: Text(l10n.onlineJoin),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      MenuButton(
        icon: Icons.leaderboard_outlined,
        label: l10n.onlineLeaderboard,
        onPressed: () => context.push(AppRoutes.leaderboard),
      ),
      const SizedBox(height: AppSpacing.sm),
      MenuButton(
        icon: Icons.emoji_events_outlined,
        label: l10n.onlineTournaments,
        onPressed: () => context.push(AppRoutes.tournaments),
      ),
      const SizedBox(height: AppSpacing.lg),
      TextButton.icon(
        icon: const Icon(Icons.logout),
        onPressed: controller.signOut,
        label: Text(l10n.onlineSignOut),
      ),
      TextButton.icon(
        icon: const Icon(Icons.delete_forever_outlined),
        style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
        onPressed: online.busy ? null : () => _deleteAccount(controller),
        label: Text(l10n.onlineDeleteAccount),
      ),
    ];
  }

  Future<void> _deleteAccount(OnlineController controller) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.onlineDeleteAccountTitle,
      body: l10n.onlineDeleteAccountBody,
      confirmLabel: l10n.onlineDeleteAccountConfirm,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed) return;
    final deleted = await controller.deleteAccount();
    if (deleted && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.onlineAccountDeleted)));
    }
  }
}
