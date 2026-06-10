import 'package:flutter/material.dart';

/// Brand accent palettes.
///
/// To switch the entire app to a different accent, change the single line in
/// `colors.dart`:
///
///   static const Color primary = AccentSage.primary;
///
/// → replace `AccentSage` with one of the palettes below.
///
/// Each palette defines four colors:
///   • primary      — main CTA / focus / brand surface
///   • primaryDeep  — gradient counterpart, hover/pressed states
///   • primarySoft  — light fills, watermarks, decorative tints
///   • onPrimary    — text/icon color rendered on top of primary
///
/// Semantic colors (red for defeat, orange for streak, yellow for the leader
/// jersey, etc.) live in `AppColors` and are NOT part of the accent — they
/// stay constant when you swap palettes.

class AccentSage {
  static const Color primary = Color(0xFF8AC0A0); // vert sauge
  static const Color primaryDeep = Color(0xFF6FA88A);
  static const Color primarySoft = Color(0xFFC8E2D2);
  static const Color onPrimary = Color(0xFF0E1F18);
}

class AccentPulse {
  static const Color primary = Color(0xFF28F39B); // vert pulse (néon)
  static const Color primaryDeep = Color(0xFF1AD07B);
  static const Color primarySoft = Color(0xFF7DEFC1);
  static const Color onPrimary = Color(0xFF052216);
}

class AccentBlue {
  static const Color primary = Color(0xFF0A84FF); // bleu iOS
  static const Color primaryDeep = Color(0xFF0066CC);
  static const Color primarySoft = Color(0xFF7CC4FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
}

class AccentSunset {
  static const Color primary = Color(0xFFFF7A59); // orange brûlé
  static const Color primaryDeep = Color(0xFFE65A39);
  static const Color primarySoft = Color(0xFFFFB59E);
  static const Color onPrimary = Color(0xFF2D1006);
}

class AccentTeal {
  static const Color primary = Color(0xFF1FB8B3); // turquoise profond
  static const Color primaryDeep = Color(0xFF0E9E99);
  static const Color primarySoft = Color(0xFF7DD8D5);
  static const Color onPrimary = Color(0xFF0B2628);
}

class AccentRose {
  static const Color primary = Color(0xFFE76F8E); // rose poudré
  static const Color primaryDeep = Color(0xFFC7556F);
  static const Color primarySoft = Color(0xFFF5BCC8);
  static const Color onPrimary = Color(0xFF3A1320);
}
