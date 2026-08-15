import 'package:dio/dio.dart';
import 'api_client.dart';

class CmsService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getBranding() async {
    final res = await _dio.get('/cms/branding');
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateBranding(Map<String, dynamic> data) async {
    await _dio.put('/cms/branding', data: data);
  }

  Future<Map<String, dynamic>> getHomeAnnouncement() async {
    final res = await _dio.get('/cms/home-announcement');
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateHomeAnnouncement(Map<String, dynamic> data) async {
    await _dio.put('/cms/home-announcement', data: data);
  }

  Future<List<dynamic>> getPrayerTimes() async {
    final res = await _dio.get('/cms/prayer-times');
    return res.data as List<dynamic>;
  }

  Future<void> updatePrayerTimes(List<Map<String, dynamic>> data) async {
    await _dio.put('/cms/prayer-times', data: data);
  }

  Future<Map<String, dynamic>> getJumuah() async {
    final res = await _dio.get('/cms/jumuah');
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateJumuah(Map<String, dynamic> data) async {
    await _dio.put('/cms/jumuah', data: data);
  }

  Future<Map<String, dynamic>> getRamadan() async {
    final res = await _dio.get('/cms/ramadan');
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateRamadan(Map<String, dynamic> data) async {
    await _dio.put('/cms/ramadan', data: data);
  }

  Future<List<dynamic>> getRamadanDays() async {
    final res = await _dio.get('/cms/ramadan/days');
    return res.data as List<dynamic>;
  }

  Future<void> updateRamadanDays(List<Map<String, dynamic>> data) async {
    await _dio.put('/cms/ramadan/days', data: data);
  }

  Future<List<dynamic>> getJanazahs() async {
    final res = await _dio.get('/cms/janazahs');
    return res.data as List<dynamic>;
  }

  Future<void> createJanazah(Map<String, dynamic> data) async {
    await _dio.post('/cms/janazahs', data: data);
  }

  Future<void> deleteJanazah(int id) async {
    await _dio.delete('/cms/janazahs/$id');
  }

  Future<bool> toggleJanazahActive(int id) async {
    final res = await _dio.put('/cms/janazahs/$id/toggle');
    return (res.data as Map<String, dynamic>)['active'] == true;
  }

  Future<List<dynamic>> getGumshudas() async {
    final res = await _dio.get('/cms/gumshudas');
    return res.data as List<dynamic>;
  }

  Future<void> createGumshuda(Map<String, dynamic> data) async {
    await _dio.post('/cms/gumshudas', data: data);
  }

  Future<void> deleteGumshuda(int id) async {
    await _dio.delete('/cms/gumshudas/$id');
  }

  Future<bool> toggleGumshudaActive(int id) async {
    final res = await _dio.put('/cms/gumshudas/$id/toggle');
    return (res.data as Map<String, dynamic>)['active'] == true;
  }

  Future<List<dynamic>> getAnnouncements() async {
    final res = await _dio.get('/cms/announcements');
    return res.data as List<dynamic>;
  }

  Future<void> createAnnouncement(Map<String, dynamic> data) async {
    await _dio.post('/cms/announcements', data: data);
  }

  Future<void> deleteAnnouncement(int id) async {
    await _dio.delete('/cms/announcements/$id');
  }

  Future<bool> toggleAnnouncementActive(int id) async {
    final res = await _dio.put('/cms/announcements/$id/toggle');
    return (res.data as Map<String, dynamic>)['active'] == true;
  }

  Future<List<dynamic>> getDonationCauses() async {
    final res = await _dio.get('/cms/donation-causes');
    return res.data as List<dynamic>;
  }

  Future<void> createDonationCause(Map<String, dynamic> data) async {
    await _dio.post('/cms/donation-causes', data: data);
  }

  Future<void> deleteDonationCause(int id) async {
    await _dio.delete('/cms/donation-causes/$id');
  }

  Future<List<dynamic>> getMonthlyDonations() async {
    final res = await _dio.get('/cms/monthly-donations');
    return res.data as List<dynamic>;
  }

  Future<void> createMonthlyDonation(Map<String, dynamic> data) async {
    await _dio.post('/cms/monthly-donations', data: data);
  }

  Future<void> deleteMonthlyDonation(int id) async {
    await _dio.delete('/cms/monthly-donations/$id');
  }

  Future<List<dynamic>> getExpenses() async {
    final res = await _dio.get('/cms/expenses');
    return res.data as List<dynamic>;
  }

  Future<void> createExpense(Map<String, dynamic> data) async {
    await _dio.post('/cms/expenses', data: data);
  }

  Future<void> deleteExpense(int id) async {
    await _dio.delete('/cms/expenses/$id');
  }

  Future<List<dynamic>> getServices() async {
    final res = await _dio.get('/cms/services');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getTeamMembers() async {
    final res = await _dio.get('/cms/team-members');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getSunnahs() async {
    final res = await _dio.get('/cms/sunnahs');
    return res.data as List<dynamic>;
  }

  Future<void> createSunnah(Map<String, dynamic> data) async {
    await _dio.post('/cms/sunnahs', data: data);
  }

  Future<void> deleteSunnah(int id) async {
    await _dio.delete('/cms/sunnahs/$id');
  }

  Future<Map<String, dynamic>> getSunnahBroadcast() async {
    final res = await _dio.get('/cms/sunnah-broadcast');
    return res.data as Map<String, dynamic>;
  }

  Future<void> setSunnahBroadcast(int sunnahId) async {
    await _dio.post('/cms/sunnah-broadcast', data: {'sunnahId': sunnahId});
  }

  Future<List<dynamic>> getNotifications({required int masjidId}) async {
    final res = await _dio.get('/notifications', queryParameters: {'masjidId': masjidId});
    return res.data as List<dynamic>;
  }

  Future<int> getUnreadNotificationCount({required int masjidId}) async {
    try {
      final res = await _dio.get('/notifications/unread-count', queryParameters: {'masjidId': masjidId});
      final count = (res.data as Map<String, dynamic>)['count'];
      return count is int ? count : int.tryParse(count.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAllNotificationsRead({required int masjidId}) async {
    try {
      await _dio.post('/notifications/read-all', queryParameters: {'masjidId': masjidId});
    } catch (_) {}
  }
}
