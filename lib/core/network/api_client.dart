import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token');
            final hasAuthHeader = options.headers.containsKey('Authorization') ||
                options.headers.containsKey('authorization');
            if (!hasAuthHeader && token != null && token.isNotEmpty) {
              final trimmed = token.trim();
              final bearerPattern = RegExp(r'^Bearer\s+', caseSensitive: false);
              options.headers['Authorization'] =
                  bearerPattern.hasMatch(trimmed) ? trimmed : 'Bearer $trimmed';
            }
          } catch (_) {
            // Ignore auth header errors to avoid blocking requests.
          }
          handler.next(options);
        },
      ),
    );
  }

  static const String _baseUrl = 'https://ai.xcbm.cc/api';
  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<ResponseBody>> postStream(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    final requestOptions = (options ?? Options()).copyWith(
      responseType: ResponseType.stream,
    );
    return _dio.post<ResponseBody>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: requestOptions,
      cancelToken: cancelToken,
    );
  }
}
