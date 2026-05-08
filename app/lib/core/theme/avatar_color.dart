import 'package:flutter/material.dart';

/// Stable avatar color for a given user id. Same id → same color across the
/// session. Used everywhere we don't have a user-picked color (e.g. profile
/// data coming from the API). Palette mirrors the colors hand-assigned in the
/// mock repository.
const List<Color> _avatarPalette = [
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
];

Color avatarColorFor(String userId) {
  if (userId.isEmpty) return _avatarPalette.first;
  var hash = 0;
  for (final code in userId.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return _avatarPalette[hash % _avatarPalette.length];
}
