import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/settings_controller.dart';

/// Game events that may produce a sound and a vibration.
enum FeedbackEvent { select, move, capture, promotion, victory, defeat }

/// Sound and haptic feedback.
///
/// Sounds use the platform click for now; dedicated sound files can later be
/// played here for each [FeedbackEvent] without touching the game code.
class FeedbackService {
  const FeedbackService({required this.sound, required this.haptics});

  final bool sound;
  final bool haptics;

  Future<void> play(FeedbackEvent event) async {
    if (sound) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (haptics) {
      await switch (event) {
        FeedbackEvent.select => HapticFeedback.selectionClick(),
        FeedbackEvent.move => HapticFeedback.lightImpact(),
        FeedbackEvent.capture => HapticFeedback.mediumImpact(),
        FeedbackEvent.promotion ||
        FeedbackEvent.victory ||
        FeedbackEvent.defeat => HapticFeedback.heavyImpact(),
      };
    }
  }
}

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final settings = ref.watch(settingsProvider);
  return FeedbackService(
    sound: settings.soundEnabled,
    haptics: settings.hapticsEnabled,
  );
});
