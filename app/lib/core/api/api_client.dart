import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bap_pulse/core/api/api_config.dart';

/// Thrown for any non-2xx response. Wraps a [DioException] so callers can
/// surface the status + the API's `{"error": "..."}` message without having
/// to know dio's error model.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Configured [Dio] instance for the BAP Pulse API.
///
/// Adds two cross-cutting behaviours via interceptors:
///   - **Auth**: every request gets a fresh Firebase ID token in the
///     `Authorization` header. Firebase's SDK handles refresh transparently.
///   - **Error mapping**: non-2xx responses surface as [ApiException] with
///     the API's `{"error": "..."}` body, so screens never see raw dio types.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final token = await user.getIdToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
          } catch (_) {
            // A failure fetching the token must NOT swallow the request:
            // without this catch, handler.next() would never run and the
            // request would hang forever with no error surfaced.
          }
          handler.next(options);
        },
        onError: (e, handler) {
          final status = e.response?.statusCode;
          String message = e.message ?? 'Network error';
          final data = e.response?.data;
          if (data is Map && data['error'] is String) {
            message = data['error'] as String;
          }
          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: ApiException(status, message),
              message: message,
            ),
          );
        },
      ),
    );
  }

  late final Dio _dio;

  static final ApiClient instance = ApiClient._();

  Dio get dio => _dio;
}
