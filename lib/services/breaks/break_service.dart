import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../models/break_models.dart';

String _ensureHHmmss(String v) {
  // accepts "HH:mm" or "HH:mm:ss" and returns "HH:mm:ss"
  if (v.isEmpty) return v;
  final parts = v.split(':');
  if (parts.length == 2) {
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
  }
  return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:${parts[2].padLeft(2, '0')}';
}

class BreakService {
  final _dio = ApiService.client;

  Future<List<WorkerBreak>> listBreaks(String workerId, DateTime day) async {
    final d = day.toIso8601String().split('T').first;
    final r = await _dio.get(
      '/workers/public/availability/break/$workerId',
      queryParameters: {'from': d, 'to': d},
    );
    final List data = r.data as List;
    return data
        .map((m) => WorkerBreak.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// BACKEND expects: { date, startTime, endTime }  (LocalTime fields)
  Future<void> createBreak({
    required String workerId,
    required DateTime date,
    required String start, // "HH:mm" or "HH:mm:ss"
    required String end, // "HH:mm" or "HH:mm:ss"
  }) async {
    final body = {
      'date': date.toIso8601String().split('T').first,
      'startTime': _ensureHHmmss(start),
      'endTime': _ensureHHmmss(end),
    };
    await _dio.post('/workers/availability/break/$workerId', data: body);
  }

  Future<void> deleteBreak({
    required String workerId,
    required String breakId,
  }) async {
    await _dio.delete('/workers/availability/break/$workerId/$breakId');
  }
}
