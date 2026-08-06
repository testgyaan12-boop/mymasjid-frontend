import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cms_service.dart';
import '../services/api_client.dart';
import '../services/push_service.dart';

class MasjidProvider extends ChangeNotifier {
  final CmsService _cmsService = CmsService();

  Map<String, dynamic>? _currentMasjid;
  Map<String, dynamic> _allCmsData = {};
  bool _isLoading = false;
  List<Map<String, dynamic>> _masjidSearchResults = [];
  List<Map<String, dynamic>> _joinedMasjids = [];
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  Map<String, dynamic>? get currentMasjid => _currentMasjid;
  Map<String, dynamic> get allCmsData => _allCmsData;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get masjidSearchResults => _masjidSearchResults;
  List<Map<String, dynamic>> get joinedMasjids => _joinedMasjids;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications() async {
    final id = _currentMasjid?['id'];
    if (id is! int) return;
    try {
      final res = await _cmsService.getNotifications(masjidId: id);
      _notifications = res.cast<Map<String, dynamic>>();
    } catch (_) {
      _notifications = [];
    }
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    final id = _currentMasjid?['id'];
    if (id is! int) return;
    try {
      _unreadCount = await _cmsService.getUnreadNotificationCount(masjidId: id);
    } catch (_) {
      _unreadCount = 0;
    }
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    final id = _currentMasjid?['id'];
    if (id is! int) return;
    try {
      await _cmsService.markAllNotificationsRead(masjidId: id);
      for (final n in _notifications) {
        n['isRead'] = true;
      }
      _unreadCount = 0;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchCmsData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _cmsService.getBranding().catchError((_) => <String, dynamic>{}),
        _cmsService.getHomeAnnouncement().catchError((_) => <String, dynamic>{}),
        _cmsService.getPrayerTimes().catchError((_) => []),
        _cmsService.getJumuah().catchError((_) => <String, dynamic>{}),
        _cmsService.getRamadan().catchError((_) => <String, dynamic>{}),
        _cmsService.getJanazahs().catchError((_) => []),
        _cmsService.getGumshudas().catchError((_) => []),
        _cmsService.getAnnouncements().catchError((_) => []),
        _cmsService.getDonationCauses().catchError((_) => []),
        _cmsService.getMonthlyDonations().catchError((_) => []),
        _cmsService.getExpenses().catchError((_) => []),
        _cmsService.getServices().catchError((_) => []),
        _cmsService.getTeamMembers().catchError((_) => []),
        _cmsService.getSunnahs().catchError((_) => []),
      ]);

      _allCmsData = {
        'branding': results[0],
        'homeAnnouncement': results[1],
        'prayerTimes': results[2],
        'jumuah': results[3],
        'ramadan': results[4],
        'janazahs': results[5],
        'gumshudas': results[6],
        'announcements': results[7],
        'donationCauses': results[8],
        'monthlyDonations': results[9],
        'expenses': results[10],
        'services': results[11],
        'teamMembers': results[12],
        'sunnahs': results[13],
      };
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
    refreshUnreadCount();
  }

  Future<void> searchMasjids(String query) async {
    try {
      final dio = ApiClient().dio;
      final res = await dio.get('/masjids', queryParameters: {'q': query.trim()});
      _masjidSearchResults = (res.data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      _masjidSearchResults = [];
    }
    notifyListeners();
  }

  Future<void> loadJoinedMasjids() async {
    try {
      final dio = ApiClient().dio;
      final res = await dio.get('/user/masjids');
      _joinedMasjids = (res.data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      _joinedMasjids = [];
    }
    notifyListeners();
  }

  Future<void> selectMasjid(int id, String name) async {
    _currentMasjid = {'id': id, 'name': name};
    ApiClient.setMasjidId(id.toString());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_masjid_id', id.toString());
    notifyListeners();
    await fetchCmsData();
    PushService.instance.registerToken(id);
  }

  Future<void> joinMasjid(int id) async {
    try {
      final dio = ApiClient().dio;
      await dio.post('/masjids/$id/join');
      await loadJoinedMasjids();
    } catch (_) {}
  }

  Future<String?> changeMasjid(int id, String name) async {
    try {
      final dio = ApiClient().dio;
      try {
        await dio.post('/masjids/$id/join');
      } catch (e) {
        // ignore "Already a member" — setCurrentMasjid auto-joins as fallback
        if (e is DioException) {
          final msg = e.response?.data is Map
              ? ((e.response?.data as Map)['message'] as String? ?? '')
              : '';
          if (msg.isNotEmpty && !msg.contains('Already a member')) {
            return msg;
          }
        }
      }
      await dio.post('/user/masjid', data: {'masjidId': id});
      await selectMasjid(id, name);
      await loadJoinedMasjids();
      return null;
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data is Map
            ? ((e.response?.data as Map)['message'] as String? ?? '')
            : '';
        if (msg.isNotEmpty) return msg;
      }
      return 'Failed to switch masjid';
    }
  }

  Future<void> loadSavedMasjid() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('current_masjid_id');
    if (id != null) {
      ApiClient.setMasjidId(id);
      try {
        final dio = ApiClient().dio;
        final res = await dio.get('/masjids/$id');
        _currentMasjid = res.data as Map<String, dynamic>;
      } catch (_) {
        _currentMasjid = {'id': int.parse(id), 'name': 'My Masjid'};
      }
      notifyListeners();
      await fetchCmsData();
      PushService.instance.registerToken(int.parse(id));
      return;
    }
    // No saved masjid yet (guest on default). Show default masjid content.
    _currentMasjid = {'id': 1, 'name': 'Noor Al Masjid'};
    notifyListeners();
    await fetchCmsData();
    PushService.instance.registerToken(1);
  }
}
