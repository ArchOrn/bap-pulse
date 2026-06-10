import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum JerseyKind {
  yellow, // maillot jaune — leader ELO
  polka, // maillot à pois — tueur de géants
  green, // maillot vert — finisseur du mois
  fight, // maillot du combatif — infatigable
}

extension JerseyKindX on JerseyKind {
  /// Short label suitable for chip-sized UI (under the jersey badge). The full
  /// name lives in `MockRepository.jersey(kind).name` for the mock mode.
  String get shortLabel => switch (this) {
    JerseyKind.yellow => 'Jaune',
    JerseyKind.polka => 'à Pois',
    JerseyKind.green => 'Vert',
    JerseyKind.fight => 'du Combatif',
  };

  /// Maps the slug returned by the API (`yellow`, `polka`, `fight`, `green`)
  /// back to a [JerseyKind]. Returns null for unknown slugs.
  static JerseyKind? fromSlug(String value) => switch (value) {
    'yellow' => JerseyKind.yellow,
    'polka' => JerseyKind.polka,
    'green' => JerseyKind.green,
    'fight' => JerseyKind.fight,
    _ => null,
  };
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
  List<Object?> get props => [
    kind,
    name,
    tagline,
    color,
    accent,
    textColor,
    criterion,
    holderId,
    unit,
    value,
  ];
}
