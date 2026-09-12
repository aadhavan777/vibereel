import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../services/storage_service.dart';

class DioClient {
  late final Dio _dio;
  final StorageService _storageService;

  DioClient(this._storageService) {
    final baseUrl = Platform.isAndroid ? ApiEndpoints.baseUrl : ApiEndpoints.iosBaseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final requestOptions = error.requestOptions;
            if (!requestOptions.path.contains('/auth/login') &&
                !requestOptions.path.contains('/auth/refresh') &&
                !requestOptions.path.contains('/auth/register')) {
              final refreshed = await _tryRefreshToken();
              if (refreshed) {
                final newToken = await _storageService.getToken();
                if (newToken != null) {
                  requestOptions.headers['Authorization'] = 'Bearer $newToken';
                  try {
                    final response = await _dio.fetch(requestOptions);
                    return handler.resolve(response);
                  } catch (e) {
                    if (e is DioException) {
                      return handler.next(e);
                    }
                  }
                }
              } else {
                await _storageService.clearAll();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final baseUrl = Platform.isAndroid ? ApiEndpoints.baseUrl : ApiEndpoints.iosBaseUrl;
      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccessToken = response.data['access_token'] as String?;
        final newRefreshToken = response.data['refresh_token'] as String?;

        if (newAccessToken != null) {
          await _storageService.saveToken(newAccessToken);
        }
        if (newRefreshToken != null) {
          await _storageService.saveRefreshToken(newRefreshToken);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Dio get dio => _dio;
}
