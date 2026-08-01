import 'package:dio/dio.dart';
import 'api_client.dart';

class UploadService {
  final Dio _dio = ApiClient().dio;

  Future<String> uploadImage(List<int> bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final res = await _dio.post('/upload', data: formData);
    return res.data['url'] as String;
  }
}
