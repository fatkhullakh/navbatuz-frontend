import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/appointment.dart';
import 'package:intl/intl.dart';

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

  Future<AppointmentItem> getById(String id) async {
    final r = await _dio.get('/appointments/$id');
    return AppointmentItem.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> cancel(String id) async {
    try {
      final r = await _dio.put('/appointments/$id/cancel');
      final ok = {200, 202, 204}.contains(r.statusCode);
      if (!ok) {
        throw DioException(
          requestOptions: r.requestOptions,
          response: r,
          error: 'Unexpected status ${r.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      // If backend blocks last-minute cancel it returns 403 with a message like:
      // "Too late to cancel (120 min window)"
      if (e.response?.statusCode == 403) {
        final text = (e.response?.data ?? '').toString();
        final match = RegExp(r'(\d+)\s*min').firstMatch(text);
        final minutes = match != null ? int.tryParse(match.group(1)!) : null;
        throw LateCancellationException(minutes);
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
      throw e;
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
