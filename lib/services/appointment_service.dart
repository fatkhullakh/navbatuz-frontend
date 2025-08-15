import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/appointment.dart';
import '../models/appointment_detail.dart';

class AppointmentService {
  final Dio _dio = DioClient.build();

  // Uses /api/appointments/me (recommended)
  Future<List<AppointmentItem>> listMine() async {
    final res = await _dio.get('/appointments/me');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map((e) => AppointmentItem.fromJson(e)).toList();
  }

  // If you still need by ID:
  Future<List<AppointmentItem>> listForCustomer(String customerId) async {
    final res = await _dio.get('/appointments/customer/$customerId');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map((e) => AppointmentItem.fromJson(e)).toList();
  }

  Future<void> cancel(String id) async {
    final res = await _dio.put('/appointments/$id/cancel');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: 'Cancel failed (${res.statusCode})',
        type: DioExceptionType.badResponse,
      );
    }
  }

  /// Fetch the next upcoming appointment.
  /// Tries `/appointments/me?onlyNext=true`; if not available, derives from `listMine()`.
  Future<AppointmentItem?> nextUpcoming() async {
    try {
      final res = await _dio
          .get('/appointments/me', queryParameters: {'onlyNext': true});
      final d = res.data;
      if (d == null || d == '') return null;
      if (d is Map) return AppointmentItem.fromJson(d.cast<String, dynamic>());
      if (d is List && d.isNotEmpty) {
        // If backend returns a list, take earliest future BOOKED/CONFIRMED
        final all = d
            .cast<Map<String, dynamic>>()
            .map(AppointmentItem.fromJson)
            .toList();
        final now = DateTime.now();
        final future = all.where((a) {
          final s = a.status.toUpperCase();
          return (s == 'BOOKED' || s == 'CONFIRMED') && a.start.isAfter(now);
        }).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
        return future.isNotEmpty ? future.first : null;
      }
    } catch (_) {
      // fall back to derive from listMine
    }
    // Fallback
    final all = await listMine();
    final now = DateTime.now();
    final future = all.where((a) {
      final s = a.status.toUpperCase();
      return (s == 'BOOKED' || s == 'CONFIRMED') && a.start.isAfter(now);
    }).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return future.isNotEmpty ? future.first : null;
  }

  Future<AppointmentDetail> getDetails(String id) async {
    final r = await _dio.get('/appointments/$id');
    final map = (r.data as Map).cast<String, dynamic>();
    return AppointmentDetail.fromJson(map);
  }
}
