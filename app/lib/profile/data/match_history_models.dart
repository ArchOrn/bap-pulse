import 'package:bap_pulse/profile/data/profile_models.dart';

/// Mirror of the API's `services.UserMatchHistoryEntry` payload — see
/// `api/services/match_history.go`. Read-only on the client.
class UserMatchEntry {
  final String id;
  final DateTime playedAt;
  final String tableau;
  final ProfileUser opponent;
  final bool wonByUser;
  final int eloChange;
  final int perfPoints;
  final List<MatchSet> sets;
  final bool validated;

  const UserMatchEntry({
    required this.id,
    required this.playedAt,
    required this.tableau,
    required this.opponent,
    required this.wonByUser,
    required this.eloChange,
    required this.perfPoints,
    required this.sets,
    required this.validated,
  });

  factory UserMatchEntry.fromJson(Map<String, dynamic> json) => UserMatchEntry(
        id: json['id'] as String,
        playedAt: DateTime.parse(json['played_at'] as String),
        tableau: json['tableau'] as String,
        opponent: ProfileUser.fromJson(
            json['opponent'] as Map<String, dynamic>),
        wonByUser: json['won_by_user'] as bool,
        eloChange: (json['elo_change'] as num).toInt(),
        perfPoints: (json['perf_points'] as num).toInt(),
        sets: ((json['sets'] as List?) ?? const [])
            .map((e) => MatchSet.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        validated: json['validated'] as bool,
      );
}

class MatchSet {
  final int mine;
  final int opp;

  const MatchSet({required this.mine, required this.opp});

  factory MatchSet.fromJson(Map<String, dynamic> json) => MatchSet(
        mine: (json['mine'] as num).toInt(),
        opp: (json['opp'] as num).toInt(),
      );
}
