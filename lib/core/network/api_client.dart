import 'package:dio/dio.dart';

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
}
