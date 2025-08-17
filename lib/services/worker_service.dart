import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class WorkerService {
  final _dio = ApiService.client;

  Future<List<String>> freeSlots({
    required String workerId,
    required DateTime date,
    required int serviceDurationMinutes,
  }) async {
    final df = DateFormat('yyyy-MM-dd');
    final r = await _dio.get(
      '/workers/free-slots/$workerId',
      queryParameters: {
        'date': df.format(date),
        'serviceDurationMinutes': serviceDurationMinutes,
      },
    );
    // API returns ["HH:mm:ss", ...]
    return (r.data as List).map((e) => e.toString()).toList();
  }
}
