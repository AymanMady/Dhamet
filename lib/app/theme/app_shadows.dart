import 'package:flutter/widgets.dart';

/// Elevation shadows.
abstract final class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x1F33251A), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> board = [
    BoxShadow(color: Color(0x3333251A), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> piece = [
    BoxShadow(color: Color(0x5522170F), blurRadius: 3, offset: Offset(0, 2)),
  ];
}
