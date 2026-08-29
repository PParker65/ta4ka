import 'package:dio/dio.dart';

/// HTTP client for a future VPS backend. Local SQLite remains the source of truth
/// until the API base URL is configured in production.
class ApiClient {
  ApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'https://api.autoservice.local',
            ),
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            headers: const {'Accept': 'application/json'},
          ),
        );

  final Dio _dio;

  Dio get raw => _dio;

  bool get isConfigured {
    final url = _dio.options.baseUrl;
    return url.isNotEmpty && !url.contains('autoservice.local');
  }
}
