import 'package:dio/dio.dart';
import 'api_client.dart';

class UserService {
  final Dio _dio = ApiClient().dio;

  // Saved Sunnahs
  Future<List<dynamic>> getSavedSunnahs() async {
    final res = await _dio.get('/user/saved-sunnahs');
    return res.data as List<dynamic>;
  }

  Future<void> saveSunnah(int sunnahId) async {
    await _dio.post('/user/saved-sunnahs/$sunnahId');
  }

  Future<void> removeSunnah(int sunnahId) async {
    await _dio.delete('/user/saved-sunnahs/$sunnahId');
  }

  // Tasbih Logs
  Future<List<dynamic>> getTasbihLogs() async {
    final res = await _dio.get('/user/tasbih-logs');
    return res.data as List<dynamic>;
  }

  Future<void> createTasbihLog(Map<String, dynamic> data) async {
    await _dio.post('/user/tasbih-logs', data: data);
  }

  // Custom Adhkars
  Future<List<dynamic>> getAdhkars() async {
    final res = await _dio.get('/user/adhkars');
    return res.data as List<dynamic>;
  }

  Future<void> createAdhkar(Map<String, dynamic> data) async {
    await _dio.post('/user/adhkars', data: data);
  }

  Future<void> deleteAdhkar(int id) async {
    await _dio.delete('/user/adhkars/$id');
  }

  // Quran Reading Progress
  Future<Map<String, dynamic>> getReadingProgress() async {
    final res = await _dio.get('/user/reading-progress');
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateReadingProgress(Map<String, dynamic> data) async {
    await _dio.put('/user/reading-progress', data: data);
  }

  // Zakat
  Future<Map<String, dynamic>> calculateZakat(Map<String, dynamic> data) async {
    final res = await _dio.post('/user/zakat/calculate', data: data);
    return res.data as Map<String, dynamic>;
  }

  // Masjid
  Future<List<dynamic>> getUserMasjids() async {
    final res = await _dio.get('/user/masjids');
    return res.data as List<dynamic>;
  }

  Future<void> setCurrentMasjid(int masjidId) async {
    await _dio.post('/user/masjid', data: {'masjidId': masjidId});
  }
}
