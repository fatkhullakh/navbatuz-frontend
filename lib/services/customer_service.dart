// lib/services/customer_service.dart
import 'package:dio/dio.dart';
import '../core/dio_client.dart';

class CustomerService {
  final Dio _dio = DioClient.build();

  Future<String> myId() async {
    final res = await _dio.get('/customers/me');
    return res.data['id'] as String; // adjust if your field differs
  }
}
