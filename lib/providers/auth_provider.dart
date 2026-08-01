import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

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
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      _error = null;
      final data = await _authService.signup(
        name: name, email: email, password: password, phone: phone,
      );
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
      _error = e.toString();
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('current_masjid_id');
    notifyListeners();
  }
}
