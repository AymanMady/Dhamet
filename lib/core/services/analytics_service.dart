import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/settings_controller.dart';

/// Anonymous usage events. No personal data, no identifiers.
enum AnalyticsEvent { gameStarted, gameFinished }

/// Where analytics events go. Nothing is sent anywhere yet: a real sink
/// (e.g. a privacy-friendly endpoint) can be plugged in later.
abstract interface class AnalyticsSink {
  void record(AnalyticsEvent event, Map<String, Object> properties);
}

/// Keeps events in memory only; useful for tests.
class InMemoryAnalyticsSink implements AnalyticsSink {
  final List<(AnalyticsEvent, Map<String, Object>)> events = [];

  @override
  void record(AnalyticsEvent event, Map<String, Object> properties) {
    events.add((event, Map.unmodifiable(properties)));
    if (kDebugMode) debugPrint('analytics: ${event.name} $properties');
  }
}

/// Forwards events to the sink only when the user has consented.
class AnalyticsService {
  const AnalyticsService({required this.consent, required this.sink});

  final bool consent;
  final AnalyticsSink sink;

  void gameStarted({required String mode, String? difficulty}) {
    _record(AnalyticsEvent.gameStarted, {
      'game_mode': mode,
      'difficulty': ?difficulty,
    });
  }

  void gameFinished({
    required String mode,
    required Duration duration,
    required String result,
    String? difficulty,
  }) {
    _record(AnalyticsEvent.gameFinished, {
      'game_mode': mode,
      'game_duration': duration.inSeconds,
      'result': result,
      'difficulty': ?difficulty,
    });
  }

  void _record(AnalyticsEvent event, Map<String, Object> properties) {
    if (consent) sink.record(event, properties);
  }
}

final analyticsSinkProvider = Provider<AnalyticsSink>(
  (ref) => InMemoryAnalyticsSink(),
);

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(
    consent: ref.watch(settingsProvider.select((s) => s.analyticsConsent)),
    sink: ref.watch(analyticsSinkProvider),
  ),
);
