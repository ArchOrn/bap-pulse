import 'package:bap_pulse/core/api/api_client.dart';
import 'package:bap_pulse/news/data/news.dart';

/// HTTP-backed read API for news.
///
/// All endpoints behind `/news` require auth (handled by [ApiClient]'s
/// interceptor). Mutations (create/update/delete) live in the BO admin and
/// are deliberately not exposed here.
class NewsRepository {
  NewsRepository._();
  static final NewsRepository instance = NewsRepository._();

  Future<List<News>> latest({int limit = 5}) => _list(limit: limit);

  Future<List<News>> all({int limit = 100, int offset = 0}) =>
      _list(limit: limit, offset: offset);

  Future<News?> byId(String id) async {
    try {
      final res = await ApiClient.instance.dio.get<Map<String, dynamic>>(
        '/news/$id',
      );
      final data = res.data;
      if (data == null) return null;
      return News.fromJson(data);
    } on Exception catch (e) {
      // Surface 404 as null; rethrow anything else so screens can show errors.
      final inner = e is ApiException ? e : null;
      if (inner?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<News>> _list({int limit = 20, int offset = 0}) async {
    final res = await ApiClient.instance.dio.get<List<dynamic>>(
      '/news',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final list = res.data ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(News.fromJson)
        .toList(growable: false);
  }
}
