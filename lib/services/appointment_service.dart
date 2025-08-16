import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/appointment.dart';

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
    Response r;
    try {
      // Most common
      r = await _dio.put('/appointments/$id/cancel');
    } on DioException catch (e) {
      // Fallback variants your backend might use
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        r = await _dio.put('/appointments/$id/cancel');
      } else {
        rethrow;
      }
    }
    final ok = {200, 202, 204}.contains(r.statusCode);
    if (!ok) {
      throw DioException(
        requestOptions: r.requestOptions,
        response: r,
        error: 'Unexpected status ${r.statusCode}',
        type: DioExceptionType.badResponse,
      );
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
