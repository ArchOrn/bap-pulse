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
}

class Player extends Equatable {
  final String id;
  final String name;
  final String initials;
  final int elo;
  final int trend; // signed delta over the current month
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

  double get winRate =>
      matchesMonth == 0 ? 0 : winsMonth / matchesMonth;

  @override
  List<Object?> get props => [
        id,
        name,
        elo,
        trend,
        matchesMonth,
        winsMonth,
        winsVsBetter,
        streak,
        category,
        jerseys,
      ];
}
