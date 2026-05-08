/// Base URL of the BAP Pulse API.
///
/// Override at build time with `--dart-define=API_BASE_URL=https://...`.
/// The default points to the local docker compose stack.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
