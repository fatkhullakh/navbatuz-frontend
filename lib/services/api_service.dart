import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final _storage = const FlutterSecureStorage();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl(),
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  )..interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            await _storage.delete(key: 'jwt_token');
            await _storage.delete(key: 'user_role');
          }
          handler.next(e);
        },
      ),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    ]);

  static Dio get client => _dio;

  /// Base URL for API (ensure it ends with `/api`)
  static String _baseUrl() {
    if (kIsWeb) return 'http://localhost:8080/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api';
    return 'http://localhost:8080/api';
  }

  /// API origin, e.g. "http://10.0.2.2:8080" (derived from baseUrl)
  static String get origin {
    final uri = Uri.parse(_dio.options.baseUrl);
    final port = (uri.hasPort && uri.port != 0) ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  /// Normalize media URLs returned by backend so they load correctly on emulator/web:
  /// - Relative path ("/uploads/...") -> prefix with [origin]
  /// - Absolute with localhost/127.0.0.1 -> rewrite host to [origin]'s host/port
  /// - Other absolute URLs -> returned as-is
  static String? normalizeMediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final isAbs = url.startsWith('http://') || url.startsWith('https://');
    if (isAbs) {
      if (url.startsWith('http://localhost') ||
          url.startsWith('https://localhost') ||
          url.startsWith('http://127.0.0.1') ||
          url.startsWith('https://127.0.0.1')) {
        final u = Uri.parse(url);
        final o = Uri.parse(origin);
        final port = (o.hasPort && o.port != 0) ? o.port : null;
        return Uri(
          scheme: o.scheme,
          host: o.host,
          port: port,
          path: u.path,
          query: u.query.isEmpty ? null : u.query,
          fragment: u.fragment.isEmpty ? null : u.fragment,
        ).toString();
      }
      return url;
    }

    // Relative or bare path
    if (url.startsWith('/')) return '$origin$url';
    return '$origin/$url';
  }

  // --- Auth endpoints ---
  static Future<Response> login(String email, String password) =>
      _dio.post('/auth/login', data: {'email': email, 'password': password});

  static Future<Response> register(Map<String, dynamic> body) =>
      _dio.post('/auth/register', data: body);

  static Future<Response> forgotPassword(String email) =>
      _dio.post('/auth/forgot-password', data: {'email': email});

  static Future<Response> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _dio.post(
        '/auth/reset-password',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
}
