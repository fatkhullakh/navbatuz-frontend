import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/appointment.dart';

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
}
