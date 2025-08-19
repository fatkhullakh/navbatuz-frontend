import 'package:dio/dio.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

class WorkerDetails {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final String? email;

  WorkerDetails({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.phone,
    this.email,
  });

  factory WorkerDetails.fromJson(Map<String, dynamic> j) {
    return WorkerDetails(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      avatarUrl: ApiService.normalizeMediaUrl(j['avatarUrl']?.toString()),
      phone: j['phone']?.toString(),
      email: j['email']?.toString(),
    );
  }
}

class WorkerService {
  final Dio _dio = ApiService.client;

  Future<WorkerDetails> details(String workerId) async {
    // Try common public endpoints
    for (final path in [
      '/workers/public/$workerId/details',
      '/workers/public/$workerId',
      '/workers/$workerId',
    ]) {
      try {
        final r = await _dio.get(path);
        if (r.data is Map) {
          return WorkerDetails.fromJson(
              Map<String, dynamic>.from(r.data as Map));
        }
      } catch (_) {}
    }
    // Fallback minimal
    return WorkerDetails(id: workerId, name: 'Worker');
  }

  /// already had: freeSlots(...)
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
