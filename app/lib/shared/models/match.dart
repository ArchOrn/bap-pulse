import 'package:equatable/equatable.dart';

/// Mirrors `match_status` on the API (see migration 014).
enum MatchStatus { pending, confirmed, contested, cancelled }

MatchStatus parseMatchStatus(String raw) => switch (raw) {
  'PENDING' => MatchStatus.pending,
  'CONFIRMED' => MatchStatus.confirmed,
  'CONTESTED' => MatchStatus.contested,
  'CANCELLED' => MatchStatus.cancelled,
  _ => MatchStatus.confirmed,
};

class GameMatch extends Equatable {
  final String id;
  final String playerAId;
  final String playerBId;
  final List<int> scoreA;
  final List<int> scoreB;
  final String winnerId;
  final String date; // human-readable string from the mockups
  final String time;
  final String court;
  final MatchStatus status;
  final int eloChange; // absolute value (positive)

  const GameMatch({
    required this.id,
    required this.playerAId,
    required this.playerBId,
    required this.scoreA,
    required this.scoreB,
    required this.winnerId,
    required this.date,
    required this.time,
    required this.court,
    required this.status,
    required this.eloChange,
  });

  bool involves(String playerId) =>
      playerAId == playerId || playerBId == playerId;

  String opponentOf(String playerId) =>
      playerAId == playerId ? playerBId : playerAId;

  /// Returns the (mine, opponent) score lists from the perspective of [playerId].
  ({List<int> mine, List<int> opp}) scoresFor(String playerId) {
    if (playerAId == playerId) {
      return (mine: scoreA, opp: scoreB);
    }
    return (mine: scoreB, opp: scoreA);
  }

  bool wonBy(String playerId) => winnerId == playerId;

  @override
  List<Object?> get props => [
    id,
    playerAId,
    playerBId,
    scoreA,
    scoreB,
    winnerId,
    status,
    eloChange,
  ];
}
