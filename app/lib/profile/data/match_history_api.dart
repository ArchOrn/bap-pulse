import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/profile/data/match_history_models.dart';

/// Calls `GET /users/:id/matches`. Auth + base URL come from [ApiClient].
class MatchHistoryApi {
  MatchHistoryApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<UserMatchEntry>> fetch(String userId) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/users/$userId/matches',
    );
    final data = response.data ?? const [];
    return data
        .map((e) => UserMatchEntry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
