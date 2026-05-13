import 'package:equatable/equatable.dart';

/// Mirrors `challenge_status` in the API.
enum ChallengeStatus { pending, accepted, declined, expired, cancelled, unknown }

ChallengeStatus _parseStatus(String raw) => switch (raw) {
      'PENDING' => ChallengeStatus.pending,
      'ACCEPTED' => ChallengeStatus.accepted,
      'DECLINED' => ChallengeStatus.declined,
      'EXPIRED' => ChallengeStatus.expired,
      'CANCELLED' => ChallengeStatus.cancelled,
      _ => ChallengeStatus.unknown,
    };

class Challenge extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String matchType; // SINGLES | DOUBLES | MIXED — v1 always SINGLES
  final DateTime? proposedAt;
  final String? court;
  final String? note;
  final ChallengeStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const Challenge({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.matchType,
    this.proposedAt,
    this.court,
    this.note,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      matchType: json['match_type'] as String,
      proposedAt: _parseTs(json['proposed_at']),
      court: json['court'] as String?,
      note: json['note'] as String?,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      respondedAt: _parseTs(json['responded_at']),
    );
  }

  @override
  List<Object?> get props => [id, fromUserId, toUserId, status];
}

DateTime? _parseTs(dynamic raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
