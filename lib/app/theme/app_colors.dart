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

  // Pieces: light "sticks" (العيدان) and dark "pellets" (البعر).
  static const lightPiece = Color(0xFFF3E6C8);
  static const lightPieceEdge = Color(0xFF8A6A45);
  static const darkPiece = Color(0xFF4A3426);
  static const darkPieceEdge = Color(0xFF22170F);
}
