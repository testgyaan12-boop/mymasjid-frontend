import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _releaseUrl = 'https://mymasjid-backend-2.onrender.com/api';
  static const String _debugUrl = 'http://localhost:8080/api';

  static String get baseUrl => kReleaseMode ? _releaseUrl : _debugUrl;
}