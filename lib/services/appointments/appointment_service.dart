import 'package:dio/dio.dart';
import '../api_service.dart';
import '../../models/appointment.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_detail.dart';

class SlotUnavailableException implements Exception {}

class CustomerMissingException implements Exception {}

class NotAuthorizedException implements Exception {}

class LateCancellationException implements Exception {
  final int? minutes; // window in minutes if we can parse it
  LateCancellationException([this.minutes]);
}

class AppointmentService {
  final _dio = ApiService.client;

  Future<List<AppointmentItem>> listMine() async {
    final r = await _dio.get('/appointments/me');
    final list = (r.data as List).cast<Map<String, dynamic>>();
    return list.map(AppointmentItem.fromJson).toList();
  }

  Future<AppointmentDetail> getById(String id) async {
    final resp = await _dio.get('/appointments/$id');
    return AppointmentDetail.fromJson(
        Map<String, dynamic>.from(resp.data as Map));
  }

  Future<void> cancel(String id) async {
    try {
      await _dio.put('/appointments/$id/cancel');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final m = e.response?.data;
        final mins = (m is Map && m['minutes'] is num)
            ? (m['minutes'] as num).toInt()
            : null;
        throw LateCancellationException(mins);
      }
      rethrow;
    }
  }

  Future<AppointmentItem> create({
    required String serviceId,
    required String workerId,
    required DateTime date,
    required String startTimeHHmmss,
    String? customerId,
  }) async {
    final df = DateFormat('yyyy-MM-dd');
    final body = {
      'serviceId': serviceId,
      'workerId': workerId,
      'date': df.format(date),
      'startTime': startTimeHHmmss,
      if (customerId != null) 'customerId': customerId,
    };

    try {
      final r = await _dio.post('/appointments', data: body);
      return AppointmentItem.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = (e.response?.data ?? '').toString().toLowerCase();

      if (code == 409) throw SlotUnavailableException(); // slot taken
      if (code == 403) throw NotAuthorizedException(); // not allowed
      if (msg.contains('customer not found')) throw CustomerMissingException();
      rethrow;
    }
  }

  // Future<void> cancel(String id) async {
  //   // 🔴 adjust if your backend is different:
  //   // e.g. PUT /api/appointments/{id}/cancel  or  POST /api/appointments/{id}/cancel
  //   final r = await _dio.put('/appointments/$id/cancel');
  //   // tolerate 200/202/204
  //   if (r.statusCode != 200 && r.statusCode != 202 && r.statusCode != 204) {
  //     throw DioException(
  //       requestOptions: r.requestOptions,
  //       response: r,
  //       error: 'Unexpected status ${r.statusCode}',
  //       type: DioExceptionType.badResponse,
  //     );
  //   }
  // }
}
