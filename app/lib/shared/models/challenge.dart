import 'package:equatable/equatable.dart';

enum ChallengeStatus { incoming, pending, accepted, refused }

class Challenge extends Equatable {
  final String id;
  final String fromId;
  final String toId;
  final String when;
  final String court;
  final ChallengeStatus status;
  final String note;

  const Challenge({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.when,
    required this.court,
    required this.status,
    required this.note,
  });

  @override
  List<Object?> get props => [id, fromId, toId, when, court, status, note];
}
