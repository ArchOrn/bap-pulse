import 'package:equatable/equatable.dart';

import 'package:bap_pulse/shared/models/jersey.dart';
import 'package:bap_pulse/shared/models/player.dart';

/// One classement = one jersey. Mirrors the four ranking endpoints exposed by
/// the API (`/rankings/performance|league|matches-played|giant-killer`).
enum LeaderboardCriterion { performance, ligue, combatif, upsets }

extension LeaderboardCriterionX on LeaderboardCriterion {
  /// Path of the API endpoint backing this criterion.
  String get endpoint => switch (this) {
    LeaderboardCriterion.performance => '/rankings/performance',
    LeaderboardCriterion.ligue => '/rankings/league',
    LeaderboardCriterion.combatif => '/rankings/matches-played',
    LeaderboardCriterion.upsets => '/rankings/giant-killer',
  };

  /// JSON field carrying the metric value in the API response.
  String get metricField => switch (this) {
    LeaderboardCriterion.performance => 'points',
    LeaderboardCriterion.ligue => 'wins',
    LeaderboardCriterion.combatif => 'matches_played',
    LeaderboardCriterion.upsets => 'upset_wins',
  };

  /// Jersey awarded to the leader of this classement.
  JerseyKind get jersey => switch (this) {
    LeaderboardCriterion.performance => JerseyKind.yellow,
    LeaderboardCriterion.ligue => JerseyKind.green,
    LeaderboardCriterion.combatif => JerseyKind.fight,
    LeaderboardCriterion.upsets => JerseyKind.polka,
  };
}

/// One row of any of the four classements. The metric varies by criterion;
/// it's exposed as a single `value` so the screen can sort/render uniformly.
class LeaderboardEntry extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? gender; // MALE | FEMALE | null
  final int elo;
  final int rank;
  final int value;

  const LeaderboardEntry({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.elo,
    required this.rank,
    required this.value,
  });

  @override
  List<Object?> get props => [id, firstName, lastName, gender, elo, rank, value];

  String get name => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return (f + l).toUpperCase();
  }

  PlayerCategory get category => PlayerCategoryX.fromGender(gender);

  factory LeaderboardEntry.fromJson(
    Map<String, dynamic> json,
    LeaderboardCriterion criterion,
  ) {
    final user = json['user'] as Map<String, dynamic>;
    return LeaderboardEntry(
      id: user['id'] as String,
      firstName: user['first_name'] as String,
      lastName: user['last_name'] as String,
      gender: user['gender'] as String?,
      // Tableau is hardcoded to SINGLES for now — see leaderboard_api.dart.
      elo: (user['elo_singles'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
      value: (json[criterion.metricField] as num).toInt(),
    );
  }
}
