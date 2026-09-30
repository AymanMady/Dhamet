import 'package:flutter/widgets.dart';

/// Spacing scale (multiples of 4 logical pixels).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Minimum size of any touch target (larger than Material's 48 for older
  /// players).
  static const double minTouchTarget = 56;

  static const EdgeInsets screen = EdgeInsets.all(md);
}
