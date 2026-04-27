import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bap_pulse/core/theme/colors.dart';

/// Typography for BAP Pulse.
///
/// Space Grotesk for display, headings and any tabular numerics
/// (ELO scores, set counts, ranks). Inter for body and labels.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayHuge = GoogleFonts.spaceGrotesk(
    fontSize: 110,
    fontWeight: FontWeight.w700,
    height: 0.8,
    letterSpacing: -6,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle displayLarge = GoogleFonts.spaceGrotesk(
    fontSize: 54,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: -2,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle displayMedium = GoogleFonts.spaceGrotesk(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle h1 = GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: AppColors.textPrimary,
    height: 1.05,
  );

  static TextStyle h2 = GoogleFonts.spaceGrotesk(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  static TextStyle h3 = GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle h4 = GoogleFonts.spaceGrotesk(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.textMuted,
  );

  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  /// Tabular numerics — for ELO scores, set scores, ranks. Always Space
  /// Grotesk so all digits are the same width.
  static TextStyle numeric({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double letterSpacing = -0.3,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
