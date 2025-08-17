import 'package:dio/dio.dart';
import 'api_service.dart';

class WorkerPublicService {
  final _dio = ApiService.client;

  /// Returns a list of "HH:mm:ss" strings.
  Future<List<String>> freeSlots({
    required String workerId,
    required DateTime date,
    required int serviceDurationMinutes,
  }) async {
    try {
      final r = await _dio.get(
        '/workers/free-slots/$workerId',
        queryParameters: {
          'date': '${date.toIso8601String().split('T').first}',
          'serviceDurationMinutes': serviceDurationMinutes,
        },
      );
      final list = (r.data as List?) ?? const [];
      return list.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      // Backend uses 403 to mean "no availability" — treat as empty.
      if (e.response?.statusCode == 403) return <String>[];
      rethrow;
    }
  }
}
