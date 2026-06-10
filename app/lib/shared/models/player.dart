import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:bap_pulse/shared/models/jersey.dart';

enum PlayerCategory {
  sh, // simple homme
  sd, // simple dame
}

extension PlayerCategoryX on PlayerCategory {
  String get short => switch (this) {
    PlayerCategory.sh => 'SH',
    PlayerCategory.sd => 'SD',
  };

  String get long => switch (this) {
    PlayerCategory.sh => 'Simple homme',
    PlayerCategory.sd => 'Simple dame',
  };

  /// Maps the API's nullable gender ("MALE" / "FEMALE" / null) to a singles
  /// category. Defaults to SH when unknown — matches the mock fallback.
  static PlayerCategory fromGender(String? gender) =>
      gender == 'FEMALE' ? PlayerCategory.sd : PlayerCategory.sh;
}

class Player extends Equatable {
  final String id;
  final String name;
  final String initials;

  // ── Hidden — internal algo only, never displayed in the UI ───────────
  final int elo;
  final int trend; // signed ELO delta this month — hidden

  // ── Surface stats — what users actually see ──────────────────────────
  /// Score de performance (current period). Can only go up within the
  /// period; resets monthly.
  final int performance;

  /// Performance gain over the last 7 days (always ≥ 0).
  final int perfGain;

  final int matchesMonth;
  final int winsMonth;
  final int winsVsBetter;
  final int streak;
  final PlayerCategory category;
  final String club;
  final String joined;
  final Color color;
  final List<JerseyKind> jerseys;

  const Player({
    required this.id,
    required this.name,
    required this.initials,
    required this.elo,
    required this.trend,
    required this.performance,
    required this.perfGain,
    required this.matchesMonth,
    required this.winsMonth,
    required this.winsVsBetter,
    required this.streak,
    required this.category,
    required this.club,
    required this.joined,
    required this.color,
    this.jerseys = const [],
  });

  String get firstName => name.split(' ').first;

  int get lossesMonth => matchesMonth - winsMonth;

  double get winRate => matchesMonth == 0 ? 0 : winsMonth / matchesMonth;

  @override
  List<Object?> get props => [
    id,
    name,
    elo,
    trend,
    performance,
    perfGain,
    matchesMonth,
    winsMonth,
    winsVsBetter,
    streak,
    category,
    jerseys,
  ];
}
