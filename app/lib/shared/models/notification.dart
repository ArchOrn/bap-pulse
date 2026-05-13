import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Mirrors `notification_type` in the API (see migration 015).
enum AppNotificationType {
  challengeReceived,
  challengeAccepted,
  challengeDeclined,
  matchAwaitingConfirmation,
  matchConfirmed,
  matchContested,
  unknown,
}

AppNotificationType _parseType(String raw) => switch (raw) {
      'CHALLENGE_RECEIVED' => AppNotificationType.challengeReceived,
      'CHALLENGE_ACCEPTED' => AppNotificationType.challengeAccepted,
      'CHALLENGE_DECLINED' => AppNotificationType.challengeDeclined,
      'MATCH_AWAITING_CONFIRMATION' =>
        AppNotificationType.matchAwaitingConfirmation,
      'MATCH_CONFIRMED' => AppNotificationType.matchConfirmed,
      'MATCH_CONTESTED' => AppNotificationType.matchContested,
      _ => AppNotificationType.unknown,
    };

/// One row of `GET /notifications`. Used by the in-app notification center to
/// display a backlog of challenge/match events, with inline accept/confirm CTAs
/// when the notification refers to a still-actionable challenge or match.
class AppNotification extends Equatable {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;

  /// Free-form JSON payload from the API. Common keys: `challenge_id`,
  /// `match_id`, `from_user_id`. Use [challengeId] / [matchId] accessors below.
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  String? get challengeId => data['challenge_id'] as String?;
  String? get matchId => data['match_id'] as String?;
  String? get fromUserId => data['from_user_id'] as String?;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // The API re-serializes JSONB as a raw JSON object (see toResponse in
    // handlers/notifications.go) — dio decodes that to a Map directly.
    Map<String, dynamic> payload = const {};
    final raw = json['data'];
    if (raw is Map) {
      payload = raw.cast<String, dynamic>();
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) payload = decoded.cast<String, dynamic>();
      } catch (_) {/* ignore — keep payload empty */}
    }

    final readAtRaw = json['read_at'];
    final readAt =
        readAtRaw is String ? DateTime.tryParse(readAtRaw)?.toLocal() : null;

    return AppNotification(
      id: json['id'] as String,
      type: _parseType(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      data: payload,
      readAt: readAt,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, data, readAt, createdAt];
}
