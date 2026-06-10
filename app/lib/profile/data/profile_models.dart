/// Mirror of the API's `services.UserProfile` payload — see
/// `api/services/profile.go`. Read-only on the client.
class UserProfile {
  final ProfileUser user;
  final String tableau;
  final int elo;
  final ProfilePerformance performance;
  final ProfileStatsMonth statsMonth;
  final List<String> jerseys;
  final int yellowJerseyThreshold;
  final List<ProfileHistoryPoint> perfHistory;
  final ProfileHeadToHead headToHead;

  const UserProfile({
    required this.user,
    required this.tableau,
    required this.elo,
    required this.performance,
    required this.statsMonth,
    required this.jerseys,
    required this.yellowJerseyThreshold,
    required this.perfHistory,
    required this.headToHead,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    user: ProfileUser.fromJson(json['user'] as Map<String, dynamic>),
    tableau: json['tableau'] as String,
    elo: (json['elo'] as num).toInt(),
    performance: ProfilePerformance.fromJson(
      json['performance'] as Map<String, dynamic>,
    ),
    statsMonth: ProfileStatsMonth.fromJson(
      json['stats_month'] as Map<String, dynamic>,
    ),
    jerseys: ((json['jerseys'] as List?) ?? const [])
        .map((e) => e as String)
        .toList(growable: false),
    yellowJerseyThreshold: (json['yellow_jersey_threshold'] as num).toInt(),
    perfHistory: ((json['perf_history'] as List?) ?? const [])
        .map((e) => ProfileHistoryPoint.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    headToHead: ProfileHeadToHead.fromJson(
      (json['head_to_head'] as Map<String, dynamic>?) ?? const {},
    ),
  );
}

class ProfileUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? nickname; // optional player-chosen handle
  final String? gender; // MALE | FEMALE | null
  final int joinedYear;

  const ProfileUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.nickname,
    required this.gender,
    required this.joinedYear,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return (f + l).toUpperCase();
  }

  factory ProfileUser.fromJson(Map<String, dynamic> json) => ProfileUser(
    id: json['id'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    nickname: json['nickname'] as String?,
    gender: json['gender'] as String?,
    joinedYear: (json['joined_year'] as num?)?.toInt() ?? 0,
  );
}

class ProfilePerformance {
  final int score;
  final int rank;
  final int gain7d;

  const ProfilePerformance({
    required this.score,
    required this.rank,
    required this.gain7d,
  });

  factory ProfilePerformance.fromJson(Map<String, dynamic> json) =>
      ProfilePerformance(
        score: (json['score'] as num).toInt(),
        rank: (json['rank'] as num).toInt(),
        gain7d: (json['gain_7d'] as num).toInt(),
      );
}

class ProfileStatsMonth {
  final int matches;
  final int wins;
  final int losses;
  final int upsetWins;
  final int streak;

  const ProfileStatsMonth({
    required this.matches,
    required this.wins,
    required this.losses,
    required this.upsetWins,
    required this.streak,
  });

  factory ProfileStatsMonth.fromJson(Map<String, dynamic> json) =>
      ProfileStatsMonth(
        matches: (json['matches'] as num).toInt(),
        wins: (json['wins'] as num).toInt(),
        losses: (json['losses'] as num).toInt(),
        upsetWins: (json['upset_wins'] as num).toInt(),
        streak: (json['streak'] as num).toInt(),
      );
}

class ProfileHistoryPoint {
  final String date; // YYYY-MM-DD
  final int value;

  const ProfileHistoryPoint({required this.date, required this.value});

  factory ProfileHistoryPoint.fromJson(Map<String, dynamic> json) =>
      ProfileHistoryPoint(
        date: json['date'] as String,
        value: (json['value'] as num).toInt(),
      );
}

class ProfileHeadToHead {
  final ProfileOpponent? nemesis;
  final ProfileOpponent? favoriteVictim;

  const ProfileHeadToHead({this.nemesis, this.favoriteVictim});

  factory ProfileHeadToHead.fromJson(Map<String, dynamic> json) =>
      ProfileHeadToHead(
        nemesis: json['nemesis'] is Map<String, dynamic>
            ? ProfileOpponent.fromJson(json['nemesis'] as Map<String, dynamic>)
            : null,
        favoriteVictim: json['favorite_victim'] is Map<String, dynamic>
            ? ProfileOpponent.fromJson(
                json['favorite_victim'] as Map<String, dynamic>,
              )
            : null,
      );
}

class ProfileOpponent {
  final ProfileUser user;
  final int wins;
  final int losses;

  const ProfileOpponent({
    required this.user,
    required this.wins,
    required this.losses,
  });

  factory ProfileOpponent.fromJson(Map<String, dynamic> json) =>
      ProfileOpponent(
        user: ProfileUser.fromJson(json['user'] as Map<String, dynamic>),
        wins: (json['wins'] as num).toInt(),
        losses: (json['losses'] as num).toInt(),
      );
}
