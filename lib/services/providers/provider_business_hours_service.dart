import 'package:dio/dio.dart';
import '../api_service.dart';

class BusinessHourDto {
  final String day; // e.g., "MONDAY"
  final String startTime; // "HH:mm:ss"
  final String endTime; // "HH:mm:ss"

  BusinessHourDto({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory BusinessHourDto.fromJson(Map<String, dynamic> j) => BusinessHourDto(
        day: j['day']?.toString() ?? 'MONDAY',
        startTime: _normalizeTime(j['startTime']),
        endTime: _normalizeTime(j['endTime']),
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
      };

  static String _normalizeTime(dynamic v) {
    final raw = (v ?? '').toString();
    // Accept "HH:mm" or "HH:mm:ss" and normalize to "HH:mm:ss"
    final parts = raw.split(':');
    if (parts.length == 2) return '$raw:00';
    return raw;
  }
}

class ProviderBusinessHoursApi {
  final Dio _dio = ApiService.client;

  Future<List<BusinessHourDto>> getHours(String providerId) async {
    final r = await _dio.get('/providers/public/$providerId/business-hours');
    final list = (r.data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((m) => BusinessHourDto.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> saveHours(String providerId, List<BusinessHourDto> hours) async {
    // backend validates & replaces all rows for that provider
    await _dio.put(
      '/providers/$providerId/business-hours',
      data: hours.map((e) => e.toJson()).toList(),
    );
  }
}
