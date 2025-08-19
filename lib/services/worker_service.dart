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

  /// already had: freeSlots(...)
  // Future<List<String>> freeSlots({
  //   required String workerId,
  //   required DateTime date,
  //   required int serviceDurationMinutes,
  // }) async {
  //   try {
  //     final r = await _dio.get(
  //       '/workers/public/$workerId/slots',
  //       queryParameters: {
  //         'date': date.toIso8601String().split('T').first,
  //         'durationMin': serviceDurationMinutes,
  //       },
  //     );
  //     final list = (r.data as List?) ?? const [];
  //     return list.map((e) => e.toString()).toList();
  //   } on DioException catch (e) {
  //     // Treat common “no availability / not configured” responses as NO SLOTS
  //     final code = e.response?.statusCode ?? 0;
  //     final body = (e.response?.data ?? '').toString().toLowerCase();
  //     if (code == 400 ||
  //         code == 404 ||
  //         code == 422 ||
  //         body.contains('no availability') ||
  //         body.contains('not available') ||
  //         body.contains('no schedule') ||
  //         body.contains('no working hours')) {
  //       return const <String>[]; // <- fall back to "no slots" UI
  //     }
  //     rethrow;
  //   }
  // }
}
