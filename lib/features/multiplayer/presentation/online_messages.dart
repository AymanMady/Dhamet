import '../../../core/localization/l10n.dart';
import '../data/realtime_client.dart';

/// User-facing text for server error codes (docs/multiplayer.md).
String onlineErrorText(AppLocalizations l10n, String code, String? message) =>
    switch (code) {
      'NETWORK' => l10n.onlineErrorNetwork,
      'CREDENTIALS' => l10n.onlineErrorCredentials,
      'TAKEN' => l10n.onlineErrorTaken,
      'ROOM_NOT_FOUND' => l10n.onlineErrorRoomNotFound,
      'ROOM_FULL' => l10n.onlineErrorRoomFull,
      'ILLEGAL_MOVE' ||
      'STALE_PLY' ||
      'NOT_YOUR_TURN' ||
      'GAME_OVER' => l10n.onlineErrorMove,
      _ => l10n.onlineErrorGeneric(message ?? code),
    };

String connectionText(AppLocalizations l10n, ConnectionStatus status) =>
    switch (status) {
      ConnectionStatus.connected => l10n.onlineConnected,
      ConnectionStatus.connecting => l10n.onlineConnecting,
      ConnectionStatus.reconnecting => l10n.onlineReconnecting,
      ConnectionStatus.disconnected => l10n.onlineDisconnected,
    };

/// `m:ss` clock display.
String formatClock(int milliseconds) {
  final seconds = (milliseconds / 1000).ceil();
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
