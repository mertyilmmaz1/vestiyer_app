import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Zara editorial tipografi - kontrollü lüks + sistematik.
/// Serif: brand/section title. Sans-serif: Inter, 300-400 weight.
/// For RTL/locale: use [getTextTheme] with [Locale]; prefer EdgeInsetsDirectional and start/end in layouts.
abstract class AppTypography {
  /// Returns a TextTheme for the given [locale]. Use for locale-aware font selection (e.g. Arabic: Cairo, CJK: Noto Sans JP).
  static TextTheme getTextTheme(Locale locale) {
    final lang = locale.languageCode.toLowerCase();
    if (lang == 'ar') {
      return TextTheme(
        displayLarge: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        displayMedium: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        displaySmall: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        titleLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        titleSmall: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w300, color: AppColors.textPrimary),
        bodySmall: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w300, color: AppColors.textPrimary),
        labelLarge: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        labelMedium: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        labelSmall: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      );
    }
    if (lang == 'ja' || lang == 'zh' || lang == 'ko') {
      return TextTheme(
        displayLarge: GoogleFonts.notoSansJp(fontSize: 32, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        displayMedium: GoogleFonts.notoSansJp(fontSize: 24, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        displaySmall: GoogleFonts.notoSansJp(fontSize: 20, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.notoSansJp(fontSize: 20, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.notoSansJp(fontSize: 18, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.notoSansJp(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        titleLarge: GoogleFonts.notoSansJp(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.notoSansJp(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        titleSmall: GoogleFonts.notoSansJp(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.notoSansJp(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.notoSansJp(fontSize: 14, fontWeight: FontWeight.w300, color: AppColors.textPrimary),
        bodySmall: GoogleFonts.notoSansJp(fontSize: 12, fontWeight: FontWeight.w300, color: AppColors.textPrimary),
        labelLarge: GoogleFonts.notoSansJp(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        labelMedium: GoogleFonts.notoSansJp(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        labelSmall: GoogleFonts.notoSansJp(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      );
    }
    return textTheme;
  }

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
