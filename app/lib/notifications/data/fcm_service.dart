import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:bap_pulse/notifications/data/notifications_repository.dart';

/// Wraps Firebase Cloud Messaging for the BAP Pulse app.
///
/// Responsibilities:
///   - request notification permission (iOS / Web / Android 13+)
///   - register & refresh the device's FCM token with the API
///   - listen for foreground messages and surface them via flutter_local_notifications
///   - expose two streams the [NotificationsBloc] subscribes to:
///       [onForegroundMessage]   — refresh the notification center + bump unread
///       [onMessageOpenedApp]    — deep-link routing on notification tap
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _foregroundCtrl = StreamController<RemoteMessage>.broadcast();
  final _openedCtrl = StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onForegroundMessage => _foregroundCtrl.stream;
  Stream<RemoteMessage> get onMessageOpenedApp => _openedCtrl.stream;

  static const String defaultChannelId = 'bap_pulse_default';
  static const String defaultChannelName = 'BAP Pulse';
  static const String defaultChannelDescription =
      'Défis, demandes de validation, mises à jour de match';

  final _localNotifs = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentToken;

  /// Wires the cross-cutting handlers. Idempotent. Safe to call before the
  /// user is authenticated — the actual API registration only happens once
  /// [registerCurrentToken] is invoked (typically on auth state change).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // iOS / Web require explicit permission; Android is opt-in past 13.
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground iOS presentation — show the system banner like Android does.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!kIsWeb) {
      // Local notifications channel on Android. iOS gets nothing here — the
      // notification payload is rendered by the system banner directly.
      await _localNotifs.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      final androidImpl =
          _localNotifs.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          defaultChannelId,
          defaultChannelName,
          description: defaultChannelDescription,
          importance: Importance.high,
        ),
      );
    }

    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_openedCtrl.add);
    FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);

    // Cold-start from a notification tap.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _openedCtrl.add(initial);
  }

  /// Fetches the device token and persists it server-side. Should be called
  /// once the user is authenticated. Safe to call multiple times.
  Future<void> registerCurrentToken() async {
    await init();
    final token = await _resolveToken();
    if (token == null || token.isEmpty) return;
    _currentToken = token;
    try {
      await NotificationsRepository.instance.registerFcmToken(
        token: token,
        platform: _platform(),
      );
    } on Exception {
      // Don't block sign-in if the API rejects the token (network down, etc.).
      // We'll retry on the next onTokenRefresh or next app launch.
    }
  }

  /// Called from the auth bloc on sign-out: remove the token from the API,
  /// then ask FCM to delete the local one so the OS stops receiving push for
  /// the previous account.
  Future<void> unregisterCurrentToken() async {
    final token = _currentToken;
    _currentToken = null;
    if (token != null) {
      await NotificationsRepository.instance.unregisterFcmToken(token);
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } on Exception {/* best-effort */}
  }

  Future<String?> _resolveToken() async {
    if (kIsWeb) {
      // The web SDK needs a VAPID key for browser push. When not set, it
      // returns null and silently skips registration — push notifications
      // simply won't fire on web in dev. Set NUXT_FCM_VAPID via the build to
      // enable them. For now we register without one so token() returns the
      // dev FID; it's not actionable for push but keeps the API path warm.
      return FirebaseMessaging.instance.getToken();
    }
    return FirebaseMessaging.instance.getToken();
  }

  Future<void> _handleTokenRefresh(String token) async {
    _currentToken = token;
    try {
      await NotificationsRepository.instance.registerFcmToken(
        token: token,
        platform: _platform(),
      );
    } on Exception {/* swallow — retried on next refresh */}
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    _foregroundCtrl.add(message);

    // On iOS the system shows a banner via setForegroundNotificationPresentationOptions.
    // On Android, foreground notifications never appear by default — we surface
    // them ourselves with flutter_local_notifications. Web gets nothing extra
    // (the SW handles backgrounded tabs).
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;
    final notif = message.notification;
    if (notif == null) return;
    await _localNotifs.show(
      id: message.hashCode,
      title: notif.title,
      body: notif.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          defaultChannelId,
          defaultChannelName,
          channelDescription: defaultChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['type']?.toString(),
    );
  }

  String _platform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}
