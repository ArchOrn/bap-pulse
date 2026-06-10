import 'package:flutter/material.dart';
import 'package:bap_pulse/core/theme/accent.dart';

/// Design tokens for BAP Pulse.
///
/// Mirrors the palette extracted from the Claude Design mockups
/// (see `data.jsx` / `home.jsx` — variant B "race board" style).
///
/// To switch the brand accent (the primary green CTA color), change the
/// `Accent...` reference on the four `Brand` lines below. Available palettes
/// in `accent.dart`: AccentSage (default), AccentPulse, AccentBlue,
/// AccentSunset, AccentTeal, AccentRose.
class AppColors {
  AppColors._();

  // Brand — swap `AccentSage` for any palette in `accent.dart` to retheme.
  static const Color primary = AccentSage.primary;
  static const Color primaryDeep = AccentSage.primaryDeep;
  static const Color primarySoft = AccentSage.primarySoft;
  static const Color onPrimary = AccentSage.onPrimary;

  // Accents
  static const Color accentOrange = Color(
    0xFFFF7A59,
  ); // streak / "Saisir un score"
  static const Color accentRed = Color(0xFFE63946); // defeat / contest / error
  static const Color accentGreen = Color(0xFF2FB974); // win / validate
  static const Color accentYellow = Color(0xFFFFD60A); // maillot jaune
  static const Color accentAmber = Color(0xFFFF9F0A); // pending state
  static const Color trendUp = Color(0xFF2FFFA0); // bright green for "+34"

  // Surfaces
  static const Color bgScaffold = Color(0xFF0B0F14);
  static const Color bgCard = Color(0xFF14181F);
  static const Color bgCardElevated = Color(0xFF1B2028);
  static const Color bgInput = Color(0xFF15231C);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0x8CFFFFFF); // 55%
  static const Color textFaint = Color(0x4DFFFFFF); // 30%

  // Lines
  static const Color divider = Color(0x0FFFFFFF); // ~6%
  static const Color dividerStrong = Color(0x1AFFFFFF); // ~10%
  static const Color outline = Color(0xFF24372F);

  // Semantic helpers
  static Color overlayOnDark(double opacity) =>
      Colors.white.withValues(alpha: opacity);

  // Player default colors (deterministic by index — used as fallback when a
  // player has no `color` field)
  static const List<Color> playerPalette = [
    Color(0xFFFF7A59),
    Color(0xFF5E60CE),
    Color(0xFF0A84FF),
    Color(0xFF2FB974),
    Color(0xFFE63946),
    Color(0xFFFFB703),
    Color(0xFF8338EC),
    Color(0xFFFB5607),
    Color(0xFF3A86FF),
    Color(0xFFF72585),
    Color(0xFF0077B6),
    Color(0xFF06A77D),
  ];
}
