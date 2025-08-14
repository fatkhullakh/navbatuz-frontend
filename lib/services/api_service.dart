import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _getBaseUrl(),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Dio get client => _dio;

  static String _getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080/api'; // ✅ for Web browser
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api'; // ✅ for Android emulator
    } else {
      return 'http://localhost:8080/api'; // ✅ for real iOS, macOS, Windows
    }
  }

  static Future<Response> login(String email, String password) async {
    return _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  static Future<Response> register({
    required String name,
    required String surname,
    required String phoneNumber,
    required String email,
    required String password,
    required String role,
    String? gender,
    String? language,
    String? dateOfBirth, // in ISO format like "2000-01-01"
  }) async {
    return await _dio.post(
      '/auth/register',
      data: {
        "name": name,
        "surname": surname,
        "phoneNumber": phoneNumber,
        "email": email,
        "password": password,
        "role": role,
        if (gender != null) "gender": gender,
        if (language != null) "language": language,
        if (dateOfBirth != null) "dateOfBirth": dateOfBirth,
      },
    );
  }

  static Future<Response> forgotPassword(String email) {
    return _dio.post('/auth/forgot-password', data: {'email': email});
  }

  static Future<Response> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _dio.post('/auth/reset-password', data: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }
}
