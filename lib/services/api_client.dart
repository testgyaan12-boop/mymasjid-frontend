import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final masjidId = _getCurrentMasjidId();
        if (masjidId != null) {
          options.headers['X-Masjid-Id'] = masjidId;
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401 && !kIsWeb) {
          _clearTokens();
        }
        handler.next(error);
      },
    ));
  }

  String? _getToken() {
    try {
      // Injected via AuthProvider at startup
      return _token;
    } catch (_) {
      return null;
    }
  }

  String? _getCurrentMasjidId() {
    return _masjidId;
  }

  void _clearTokens() {
    _token = null;
    _masjidId = null;
  }

  static String? _token;
  static String? _masjidId;

  static void setToken(String? token) => _token = token;
  static void setMasjidId(String? id) => _masjidId = id;
  static String? get masjidId => _masjidId;
}
