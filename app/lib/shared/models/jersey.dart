import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum JerseyKind {
  yellow, // maillot jaune — leader ELO
  polka,  // maillot à pois — tueur de géants
  green,  // maillot vert — finisseur du mois
  fight,  // maillot du combatif — infatigable
}

class Jersey extends Equatable {
  final JerseyKind kind;
  final String name;
  final String tagline;
  final String description;
  final Color color;
  final Color? accent;
  final Color textColor;
  final String criterion;
  final String holderId;
  final String unit;
  final num value;

  const Jersey({
    required this.kind,
    required this.name,
    required this.tagline,
    required this.description,
    required this.color,
    this.accent,
    required this.textColor,
    required this.criterion,
    required this.holderId,
    required this.unit,
    required this.value,
  });

  @override
  List<Object?> get props =>
      [kind, name, tagline, color, accent, textColor, criterion, holderId, unit, value];
}
