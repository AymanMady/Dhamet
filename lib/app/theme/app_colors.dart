import 'package:flutter/material.dart';

/// Colour palette inspired by Mauritania: sand and earth for the board, the
/// indigo of the melhfa for actions, gold for the Sultan.
abstract final class AppColors {
  // Sand and earth.
  static const sand50 = Color(0xFFFBF7EF);
  static const sand100 = Color(0xFFF4EBDA);
  static const sand200 = Color(0xFFE9DCC3);
  static const sand300 = Color(0xFFD9C49E);
  static const sand400 = Color(0xFFC4A878);
  static const earth500 = Color(0xFF8A6A45);
  static const earth700 = Color(0xFF5E432A);
  static const earth900 = Color(0xFF33251A);

  // Accents.
  static const indigo = Color(0xFF1F3A5F);
  static const indigoLight = Color(0xFF4A6A93);
  static const gold = Color(0xFFC9962B);
  static const goldLight = Color(0xFFE8C36A);
  static const terracotta = Color(0xFFB5552B);
  static const green = Color(0xFF1E6B4F);

  // Night theme.
  static const night900 = Color(0xFF12141A);
  static const night800 = Color(0xFF1B1F29);
  static const night700 = Color(0xFF262B38);
  static const nightSand = Color(0xFFCDB892);

  // Pieces, as played on the sand: planted sticks (العيدان) for the light
  // side, dark pebbles for the other (the reference art shows pebbles where
  // tradition uses camel-dung pellets, البعر).
  static const woodLight = Color(0xFFE8CFA0);
  static const wood = Color(0xFFB98B56);
  static const woodDark = Color(0xFF6E4B2A);
  static const woodCut = Color(0xFFF0DEB8);
  static const woodGrain = Color(0xFF5A3C22);
  static const stoneLight = Color(0xFF928A80);
  static const stone = Color(0xFF615951);
  static const stoneDark = Color(0xFF302A26);

  /// The second, lighter pebble stacked on a pebble Sultan.
  static const quartzLight = Color(0xFFF4EDE2);
  static const quartz = Color(0xFFD3C7B5);
  static const quartzDark = Color(0xFF9B8E7C);

  // Weathered planks of the buttons.
  static const plankLight = Color(0xFFC9B08A);
  static const plank = Color(0xFF9E8462);
  static const plankDark = Color(0xFF6B5741);
  static const plankInk = Color(0xFF34261A);
}
