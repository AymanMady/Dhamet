import 'dart:math';

final Random _random = Random.secure();

/// A short unique identifier: timestamp plus random suffix.
String newId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final suffix = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
  return '$time-$suffix';
}
