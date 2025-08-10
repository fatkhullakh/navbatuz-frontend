import 'package:dio/dio.dart';
import '../core/dio_client.dart';

class AuthService {
  final Dio _dio = DioClient.build();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> register(Map<String, dynamic> payload) async {
    await _dio.post('/auth/register', data: payload);
  }
}
