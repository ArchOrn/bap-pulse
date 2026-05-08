import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/leaderboard/data/leaderboard_models.dart';

/// Calls `GET /rankings/{criterion}` on the API. Tableau is locked to SINGLES
/// for this first pass — DOUBLES/MIXED will be added when the UI exposes a
/// tableau selector.
class LeaderboardApi {
  LeaderboardApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<LeaderboardEntry>> fetch(
    LeaderboardCriterion criterion, {
    String? period,
  }) async {
    final response = await _client.dio.get<List<dynamic>>(
      criterion.endpoint,
      queryParameters: {
        'tableau': 'SINGLES',
        if (period != null) 'period': period,
      },
    );
    final data = response.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map((row) => LeaderboardEntry.fromJson(row, criterion))
        .toList(growable: false);
  }
}
