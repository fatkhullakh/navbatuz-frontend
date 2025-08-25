import 'package:dio/dio.dart';
import '../api_service.dart';
import '../../models/appointment.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_detail.dart';
import '../../models/appointment_models.dart';
import '../../models/appointment_detail_staff.dart';

class SlotUnavailableException implements Exception {}

class CustomerMissingException implements Exception {}

class NotAuthorizedException implements Exception {}

class LateCancellationException implements Exception {
  final int? minutes;
  LateCancellationException([this.minutes]);
}

class AppointmentService {
  final _dio = ApiService.client;

  Future<List<Appointment>> getWorkerDay(String workerId, DateTime day) async {
    final d = day.toIso8601String().split('T').first;
    final r = await _dio.get(
      '/appointments/worker/$workerId/day/staff',
      queryParameters: {'date': d},
    );
    final List data = r.data as List;
    return data
        .map((m) => Appointment.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<Appointment> book(NewAppointmentCmd cmd) async {
    final r = await _dio.post('/appointments', data: cmd.toJson());
    return Appointment.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<void> complete(String appointmentId) async {
    await _dio.put('/appointments/$appointmentId/complete');
  }

  Future<Appointment> reschedule({
    required String appointmentId,
    required DateTime newDate,
    required String newStartTime,
  }) async {
    final body = {
      'newDate': newDate.toIso8601String().split('T').first,
      'newStartTime': newStartTime,
    };
    final r =
        await _dio.put('/appointments/$appointmentId/reschedule', data: body);
    return Appointment.fromJson(Map<String, dynamic>.from(r.data));
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

  /// Mark as No-show (server route exists). If not yet deployed, you can keep a 404 fallback.
  Future<void> noShow(String id) async {
    await _dio.put('/appointments/$id/no-show');
  }

  Future<AppointmentDetailsStaff> getStaffDetails(String id) async {
    final resp = await _dio.get('/appointments/$id/staff');
    return AppointmentDetailsStaff.fromJson(
        Map<String, dynamic>.from(resp.data as Map));
  }

  /// Ask backend for free slots for the worker, given the service duration.
  Future<List<String>> getFreeSlots({
    required String workerId,
    required DateTime date,
    required int serviceDurationMinutes,
  }) async {
    final r = await _dio.get(
      '/workers/free-slots/$workerId',
      queryParameters: {
        'date': date.toIso8601String().split('T').first,
        'serviceDurationMinutes': serviceDurationMinutes,
      },
    );
    return (r.data as List).map((e) => e.toString()).toList();
  }

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

  // Future<void> cancel(String id) async {
  //   try {
  //     await _dio.put('/appointments/$id/cancel');
  //   } on DioException catch (e) {
  //     if (e.response?.statusCode == 409) {
  //       final m = e.response?.data;
  //       final mins = (m is Map && m['minutes'] is num)
  //           ? (m['minutes'] as num).toInt()
  //           : null;
  //       throw LateCancellationException(mins);
  //     }
  //     rethrow;
  //   }
  // }

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
