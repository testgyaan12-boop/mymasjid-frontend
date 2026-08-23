import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/push_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.uninitialized;
  Map<String, dynamic>? _user;
  String? _token;
  String? _refreshToken;
  String? _error;

  AuthStatus get status => _status;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      _token = token;
      _refreshToken = prefs.getString('refresh_token');
      final masjidId = prefs.getString('current_masjid_id');
      ApiClient.setToken(token);
      if (masjidId != null) ApiClient.setMasjidId(masjidId);

      final profile = await _authService.getProfile();
      _user = profile;
      _status = AuthStatus.authenticated;
    } catch (_) {
      _token = null;
      _refreshToken = null;
      _user = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _error = null;
      final data = await _authService.login(email, password);
      _token = data['accessToken'] as String?;
      _refreshToken = data['refreshToken'] as String?;
      _user = {
        'id': data['userId'],
        'name': data['name'],
        'email': data['email'],
        'systemRole': data['systemRole'] ?? 'USER',
        'currentMasjidId': data['currentMasjidId'],
        'currentMasjidName': data['currentMasjidName'],
      };
      ApiClient.setToken(_token);
      if (data['currentMasjidId'] != null) {
        ApiClient.setMasjidId(data['currentMasjidId'].toString());
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _token!);
      if (_refreshToken != null) await prefs.setString('refresh_token', _refreshToken!);
      if (data['currentMasjidId'] != null) {
        await prefs.setString('current_masjid_id', data['currentMasjidId'].toString());
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['message'] is String && (data['message'] as String).isNotEmpty) {
          return data['message'] as String;
        }
        // Validation map: {field: message}
        if (data.isNotEmpty) {
          final first = data.values.first;
          if (first is String) return first;
        }
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
      if (e.response?.statusCode == 401) return 'Invalid email or password';
      if (e.response?.statusCode == 400) return 'Please check your details';
    }
    final msg = e.toString();
    // Strip DioException prefix for cleaner toaster
    if (msg.contains('DioException')) {
      final m = RegExp(r'message:\s*(.*)').firstMatch(msg);
      if (m != null) return m.group(1)!.trim();
    }
    return msg.replaceAll('Exception:', '').trim();
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      _error = null;
      await _authService.signup(
        name: name, email: email, password: password, phone: phone,
      );
      // Do not auto-login after signup - user must login with credentials.
      // Clear any stale auth state.
      _token = null;
      _refreshToken = null;
      _user = null;
      _status = AuthStatus.unauthenticated;
      ApiClient.setToken(null);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    }
  }

  void refreshProfile(Map<String, dynamic> updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _user = null;
    _error = null;
    _status = AuthStatus.unauthenticated;
    ApiClient.setToken(null);
    ApiClient.setMasjidId(null);

    PushService.instance.unregisterToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('current_masjid_id');
    notifyListeners();
  }
}
