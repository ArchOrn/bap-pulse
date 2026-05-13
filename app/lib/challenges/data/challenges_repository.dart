import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/shared/models/challenge.dart';

/// HTTP wrapper for `/challenges`. v1 only supports SINGLES challenges, which
/// the API enforces; the client doesn't need to expose a match_type knob.
class ChallengesRepository {
  ChallengesRepository._();
  static final ChallengesRepository instance = ChallengesRepository._();

  Future<Challenge> create({
    required String toUserId,
    DateTime? proposedAt,
    String? court,
    String? note,
  }) async {
    final res = await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/challenges',
      data: {
        'to_user_id': toUserId,
        if (proposedAt != null) 'proposed_at': proposedAt.toUtc().toIso8601String(),
        if (court != null && court.isNotEmpty) 'court': court,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return Challenge.fromJson(res.data!);
  }

  Future<Challenge> accept(String id) => _respond(id, 'accept');
  Future<Challenge> decline(String id) => _respond(id, 'decline');
  Future<Challenge> cancel(String id) => _respond(id, 'cancel');

  Future<Challenge> _respond(String id, String action) async {
    final res = await ApiClient.instance.dio
        .post<Map<String, dynamic>>('/challenges/$id/$action');
    return Challenge.fromJson(res.data!);
  }
}
