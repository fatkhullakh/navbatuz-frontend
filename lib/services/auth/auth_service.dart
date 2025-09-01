// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:frontend/services/auth/auth_manager.dart';
import '../../core/dio_client.dart';
import '../api_service.dart';

class AuthService {
  final Dio _dio = DioClient.build();

  Future<String?> currentToken() async {
    return ApiService.getToken();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = Map<String, dynamic>.from(res.data as Map);

    final token = (data['token'] ?? data['accessToken'] ?? '').toString();
    if (token.isNotEmpty) {
      await ApiService.setToken(token);
    }

    final role = (data['role'] ?? data['roles'])?.toString();
    if (role != null && role.isNotEmpty) {
      await AuthManager.instance.setRole(role);
    }

    final userId = (data['userId'] ?? data['id'] ?? '').toString();
    if (userId.isNotEmpty) {
      await ApiService.setUserId(userId);
    } else {
      await ApiService.resolveMyUserId();
    }

    return data;
  }

  Future<void> register(Map<String, dynamic> payload) async {
    await _dio.post('/auth/register', data: payload);
  }

  /// 1) register the user  2) login and persist JWT/ids
  Future<String> registerThenLogin({
    required String name,
    required String surname,
    required String email,
    required String phoneNumber,
    required String password,
    String? language, // 'en' | 'ru' | 'uz'
    String? countryIso2, // 'UZ' etc.
    String? role, // <-- 'OWNER' | 'CUSTOMER' | 'WORKER' ...
  }) async {
    if (name.trim().isEmpty ||
        surname.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().length < 6) {
      throw StateError(
          'Missing or invalid owner fields: name/surname/email/password');
    }

    final lang = _normEnum(language); // RU/EN/UZ
    final country = _normIso2(countryIso2);
    final phone = _normE164(phoneNumber);
    final roleUpper = (role ?? '').trim().toUpperCase(); // pass as-is to BE

    await register({
      'name': name.trim(),
      'surname': surname.trim(),
      'email': email.trim(),
      'phoneNumber': phone,
      'password': password,
      if (lang != null) 'language': lang,
      if (country != null) 'country': country,
      if (roleUpper.isNotEmpty) 'role': roleUpper, // <-- IMPORTANT
    });

    final loginRes = await login(email, password);
    final token =
        (loginRes['token'] ?? loginRes['accessToken'] ?? '').toString();
    if (token.isEmpty) {
      throw StateError('Registration succeeded but login returned no token');
    }
    return token;
  }

  /* ---------------- helpers ---------------- */

  String? _normEnum(String? v) {
    final s = (v ?? '').trim().toUpperCase();
    if (s.isEmpty) return null;
    const allowed = {'RU', 'EN', 'UZ'};
    return allowed.contains(s) ? s : null;
  }

  String? _normIso2(String? v) {
    final s = (v ?? '').trim().toUpperCase();
    return s.isEmpty ? null : s;
  }

  /// Keep '+' and digits only. If no '+', prefix one.
  String _normE164(String v) {
    var s = v.trim();
    if (s.isEmpty) return s;
    if (!s.startsWith('+')) s = '+$s';
    return '+' + s.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
  }
}
