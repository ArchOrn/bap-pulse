import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/auth/data/auth_account.dart';

/// Wraps `POST /auth/sync`. Called after every Firebase authentication:
///   - on registration, with profile fields + FFBAD licence so the API can
///     match the club roster and decide approved-vs-pending;
///   - on sign-in / cold start, with an empty body to refresh the account
///     status (the server returns the existing profile untouched).
class AuthSyncApi {
  AuthSyncApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<AuthSyncResult> sync({
    String? firstName,
    String? lastName,
    String? nickname,
    String? licenseNumber,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null && firstName.isNotEmpty) body['first_name'] = firstName;
    if (lastName != null && lastName.isNotEmpty) body['last_name'] = lastName;
    if (nickname != null && nickname.isNotEmpty) body['nickname'] = nickname;
    if (licenseNumber != null && licenseNumber.isNotEmpty) {
      body['license_number'] = licenseNumber;
    }

    final res = await _client.dio.post<Map<String, dynamic>>(
      '/auth/sync',
      data: body,
    );
    return AuthSyncResult.fromJson(res.data!);
  }
}
