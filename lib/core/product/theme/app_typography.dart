import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Zara editorial tipografi - kontrollü lüks + sistematik.
/// Serif: brand/section title. Sans-serif: Inter, 300-400 weight.
abstract class AppTypography {
  // Serif - Playfair Display (editorial, Didot alternatifi)
  static TextStyle _serif({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double letterSpacing = 1.0,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: AppColors.textPrimary,
      );

  // Sans-serif - Inter (rehber: body 300-400, menu 300 + letterSpacing)
  static TextStyle _sans({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double letterSpacing = 0.3,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: AppColors.textPrimary,
      );

  /// Logo / editorial section title - serif, 32px
  static TextStyle get display => _serif(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
      );

  /// Section başlıkları - serif
  static TextStyle get headline => _serif(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
      );

  /// Menü / navigasyon - Inter 300 + letterSpacing
  static TextStyle get title => _sans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
      );

  /// Body - Inter 300-400
  static TextStyle get body => _sans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
      );

  /// Buton / label - Inter 400, uppercase
  static TextStyle get label => _sans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.1,
      );

  /// Caption
  static TextStyle get caption => _sans(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.3,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: _serif(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.2,
        ),
        displayMedium: _serif(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
        displaySmall: _serif(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
        headlineLarge: _sans(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
        headlineMedium: _sans(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
        headlineSmall: _sans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.8,
        ),
        titleLarge: _sans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
        titleMedium: _sans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.8,
        ),
        titleSmall: _sans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.6,
        ),
        bodyLarge: _sans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
        bodyMedium: _sans(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.3,
        ),
        bodySmall: _sans(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.3,
        ),
        labelLarge: _sans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.1,
        ),
        labelMedium: _sans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
        labelSmall: _sans(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.8,
        ),
      );
}
