import 'package:dio/dio.dart';
import '../api_service.dart';

class UploadsService {
  final Dio _dio = ApiService.client;

  /// Upload a user avatar. Returns the **normalized** public URL.
  Future<String> uploadUserAvatar({
    required String userId,
    required String filePath,
  }) async {
    final fileName = filePath.split('/').last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final res = await _dio.post(
      '/uploads',
      queryParameters: {'scope': 'user', 'ownerId': userId},
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    final url = (res.data['url'] ?? res.data['path'])?.toString();
    return ApiService.normalizeMediaUrl(url) ?? url!;
  }
}
