import 'package:bap_pulse/shared/models/jersey.dart';
import 'package:bap_pulse/shared/models/player.dart';

/// One row of `GET /members`. Mirrors `services.MemberSummary` on the Go side
/// — identity + ELO + monthly performance (score, rank, 7-day gain) + monthly
/// W/L/M + currently held jerseys.
class MemberSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String? gender; // MALE | FEMALE | null
  final int elo;
  final int perfScore;
  final int perfRank;
  final int perfGain7d;
  final int matchesMonth;
  final int winsMonth;
  final int lossesMonth;
  final List<JerseyKind> jerseys;

  const MemberSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.elo,
    required this.perfScore,
    required this.perfRank,
    required this.perfGain7d,
    required this.matchesMonth,
    required this.winsMonth,
    required this.lossesMonth,
    required this.jerseys,
  });

  String get name => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return (f + l).toUpperCase();
  }

  PlayerCategory get category => PlayerCategoryX.fromGender(gender);

  factory MemberSummary.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final perf = json['performance'] as Map<String, dynamic>;
    final stats = json['stats_month'] as Map<String, dynamic>;
    final rawJerseys =
        (json['jerseys'] as List?)?.cast<String>() ?? const <String>[];
    return MemberSummary(
      id: user['id'] as String,
      firstName: user['first_name'] as String,
      lastName: user['last_name'] as String,
      gender: user['gender'] as String?,
      elo: (json['elo'] as num).toInt(),
      perfScore: (perf['score'] as num).toInt(),
      perfRank: (perf['rank'] as num).toInt(),
      perfGain7d: (perf['gain_7d'] as num).toInt(),
      matchesMonth: (stats['matches'] as num).toInt(),
      winsMonth: (stats['wins'] as num).toInt(),
      lossesMonth: (stats['losses'] as num).toInt(),
      jerseys: rawJerseys
          .map(JerseyKindX.fromSlug)
          .whereType<JerseyKind>()
          .toList(growable: false),
    );
  }
}
