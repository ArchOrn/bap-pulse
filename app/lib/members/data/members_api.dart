import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/members/data/member_summary.dart';

/// Calls `GET /members` on the API. Tableau is locked to SINGLES for now —
/// the Membres screen only exposes singles categories (SH / SD).
class MembersApi {
  MembersApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<MemberSummary>> fetch({String? period}) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/members',
      queryParameters: {
        'tableau': 'SINGLES',
        if (period != null) 'period': period,
      },
    );
    final data = response.data ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(MemberSummary.fromJson)
        .toList(growable: false);
  }
}
