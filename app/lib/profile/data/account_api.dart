import 'package:firebase_auth/firebase_auth.dart';

import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/profile/data/account.dart';

/// Wraps `GET /users/:id` and `PUT /users/:id` for the currently authenticated
/// user. Nickname is the only mobile-editable field today — name / gender /
/// FFBAD rank are admin-managed via the BO, so the PUT call echoes their
/// current values back to leave them untouched.
class AccountApi {
  AccountApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw ApiException(401, 'Non authentifié.');
    }
    return uid;
  }

  Future<Account> fetchMe() async {
    final res = await _client.dio.get<Map<String, dynamic>>('/users/$_uid');
    return Account.fromJson(res.data!);
  }

  Future<Account> updateNickname(Account current, String? nickname) async {
    final body = {
      'first_name': current.firstName,
      'last_name': current.lastName,
      'email': current.email,
      'gender': current.gender ?? '',
      'ffbad_rank': current.ffbadRank ?? '',
      'nickname': nickname ?? '',
    };
    final res = await _client.dio.put<Map<String, dynamic>>(
      '/users/${current.id}',
      data: body,
    );
    return Account.fromJson(res.data!);
  }

  Future<void> deleteMe() async {
    await _client.dio.delete<void>('/users/$_uid');
  }
}
