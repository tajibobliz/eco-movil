import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';

import '../config/api_config.dart';
import '../config/app_routes.dart';
import '../config/nav_key.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final requestOptions = error.requestOptions;
          final alreadyRetried = requestOptions.extra['retried'] == true;

          if (error.response?.statusCode == 401 && !alreadyRetried) {
            final refreshed = await _refreshAccessToken();
            if (refreshed != null) {
              requestOptions.extra['retried'] = true;
              requestOptions.headers['Authorization'] = 'Bearer $refreshed';

              try {
                final response = await _dio.fetch<dynamic>(requestOptions);
                handler.resolve(response);
                return;
              } on DioException catch (retryError) {
                handler.next(retryError);
                return;
              }
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  final TokenStorage _tokenStorage = TokenStorage();
  late final Dio _dio;

  Dio get dio => _dio;

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ).post<Map<String, dynamic>>(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      final access = response.data?['access'] as String?;
      if (access == null || access.isEmpty) return null;

      await _tokenStorage.saveTokens(access: access, refresh: refreshToken);
      return access;
    } on DioException {
      await _tokenStorage.clear();
      _scheduleLogout();
      return null;
    }
  }

  // Flag para evitar multiples redirects simultaneos si varias peticiones
  // fallan al mismo tiempo con refresh expirado.
  static bool _loggingOut = false;

  static void _scheduleLogout() {
    if (_loggingOut) return;
    _loggingOut = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.home,
        (_) => false,
      );
      _loggingOut = false;
    });
  }
}
