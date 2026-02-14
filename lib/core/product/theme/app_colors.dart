import 'package:flutter/material.dart';

/// Zara editorial palette - kontrollü lüks, kontrast odaklı.
/// Rehber: "Zara'da renk yoktur. Kontrast vardır."
abstract class AppColors {
  // Primary palette (rehber)
  static const Color background = Color(0xFFFFFFFF);
  static const Color softBackground = Color(0xFFF7F7F7);
  static const Color black = Color(0xFF111111);
  static const Color greyText = Color(0xFF6E6E6E);
  static const Color border = Color(0xFFEAEAEA);

  // Aliases (geriye dönük uyumluluk)
  static const Color primary = black;
  static const Color secondary = black;
  static const Color tertiary = softBackground;
  static const Color textPrimary = black;
  static const Color textSecondary = greyText;
  static const Color divider = border;
  static const Color cardBackground = softBackground;
  static const Color inputBackground = Color(0xFFF9F9F9);

  static const Color error = Color(0xFF80142B);
}
