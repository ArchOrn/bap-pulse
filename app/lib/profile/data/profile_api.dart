import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/profile/data/profile_models.dart';

/// Calls `GET /users/:id/profile`. Auth + base URL come from [ApiClient].
class ProfileApi {
  ProfileApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<UserProfile> fetch(String userId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/users/$userId/profile',
    );
    final data = response.data;
    if (data == null) {
      throw ApiException(response.statusCode, 'Empty profile response');
    }
    return UserProfile.fromJson(data);
  }
}
