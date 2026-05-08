enum NewsSource { manual, autoMatch }

NewsSource _parseSource(String? raw) {
  switch (raw) {
    case 'AUTO_MATCH':
      return NewsSource.autoMatch;
    case 'MANUAL':
    default:
      return NewsSource.manual;
  }
}

class News {
  final String id;
  final String emoji;
  final String title; // Markdown
  final String? body; // Markdown (optional)
  final NewsSource source;
  final String? matchId;
  final String? createdBy;
  final DateTime createdAt;

  const News({
    required this.id,
    required this.emoji,
    required this.title,
    this.body,
    required this.source,
    this.matchId,
    this.createdBy,
    required this.createdAt,
  });

  /// Parses a JSON object as returned by `GET /news[/:id]`.
  ///
  /// API quirks: the body is `null` when absent (sqlc emits `pgtype.Text`
  /// serialized as `null`), and `match_id` / `created_by` follow the same
  /// convention. `created_at` is RFC3339 with timezone.
  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      source: _parseSource(json['source'] as String?),
      matchId: json['match_id'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
