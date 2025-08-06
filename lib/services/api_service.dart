//Dio client, headers, login, register etc.
import 'package:dio/dio.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8080/api',
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Future<Response> login(String email, String password) async {
    return await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
