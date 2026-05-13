import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/shared/models/notification.dart';

/// HTTP wrapper around the `/notifications` and `/users/me/fcm-tokens` API
/// routes. Mirrors the pattern of NewsRepository — one private singleton, one
/// method per endpoint, no caching (the BLoC owns state).
class NotificationsRepository {
  NotificationsRepository._();
  static final NotificationsRepository instance = NotificationsRepository._();

  Future<List<AppNotification>> list({int limit = 30, int offset = 0}) async {
    final res = await ApiClient.instance.dio.get<List<dynamic>>(
      '/notifications',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final list = res.data ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(growable: false);
  }

  Future<int> unreadCount() async {
    final res = await ApiClient.instance.dio.get<Map<String, dynamic>>(
      '/notifications/unread-count',
    );
    final data = res.data;
    final raw = data?['count'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  Future<void> markRead(String id) async {
    await ApiClient.instance.dio.post<Map<String, dynamic>>(
      '/notifications/$id/read',
    );
  }

  Future<void> markAllRead() async {
    await ApiClient.instance.dio.post('/notifications/read-all');
  }

  Future<void> registerFcmToken({
    required String token,
    required String platform, // 'ios' | 'android' | 'web'
  }) async {
    await ApiClient.instance.dio.post(
      '/users/me/fcm-tokens',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregisterFcmToken(String token) async {
    try {
      await ApiClient.instance.dio
          .delete('/users/me/fcm-tokens/$token');
    } on Exception {
      // Logout cleanup is best-effort. If the network is down or the token
      // already expired server-side, swallow it — leaking a token here is
      // cheaper than blocking the sign-out flow.
    }
  }
}
