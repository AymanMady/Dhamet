import 'package:flutter/widgets.dart';

/// Corner radii.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 22;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius board = BorderRadius.all(Radius.circular(lg));
}
