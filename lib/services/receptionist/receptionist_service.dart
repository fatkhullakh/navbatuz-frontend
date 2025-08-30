import 'package:dio/dio.dart';
import '../../core/dio_client.dart';

class ReceptionistService {
  final Dio _dio = DioClient.build();

  Future<void> create({
    required String providerId,
    required String userId,
    DateTime? hireDate, // optional
  }) async {
    await _dio.post(
      '/providers/$providerId/receptionists',
      data: {
        'userId': userId,
        if (hireDate != null)
          'hireDate': hireDate.toIso8601String().split('T').first,
      },
    );
  }

  // optional helpers if you need them later
  Future<List<Map<String, dynamic>>> list(String providerId) async {
    final res = await _dio.get('/providers/$providerId/receptionists');
    final data = res.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return const [];
  }
}
