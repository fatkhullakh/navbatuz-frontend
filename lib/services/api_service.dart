import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final _storage = const FlutterSecureStorage();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl(),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Navbatuz-Mobile-App/1.0.0 (Flutter)',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
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
            // Token invalid/expired → clear
            await _storage.delete(key: 'jwt_token');
            await _storage.delete(key: 'user_role');
          }
          handler.next(e);
        },
      ),
      // Only log in debug mode to avoid performance issues in production
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
        ),
    ]);

  static Dio get client => _dio;

  static String _baseUrl() {
    // Production URL for your deployed API
    const String prodUrl = 'https://api.birzum.app/api';

    // Development URLs (only used when local server is running)
    const String devUrlWeb = 'http://localhost:8080/api';
    const String devUrlAndroid = 'http://10.0.2.2:8080/api';
    const String devUrlIOS = 'http://localhost:8080/api';

    // FOR NOW: Always use production URL to test deployment
    // TODO: Change this back to conditional logic when you need local development
    return prodUrl;

    // Uncomment below when you want to use local development again:
    /*
    // Use production URL in release mode
    if (!kDebugMode) {
      return prodUrl;
    }

    // Debug mode - use localhost
    if (kIsWeb) return devUrlWeb;
    if (Platform.isAndroid) return devUrlAndroid;
    return devUrlIOS;
    */
  }

  static String get origin {
    final uri = Uri.parse(_dio.options.baseUrl);
    final port = (uri.hasPort && uri.port != 0) ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  static String? normalizeMediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final isAbs = url.startsWith('http://') || url.startsWith('https://');
    final o = Uri.parse(origin);
    if (isAbs) {
      final u = Uri.parse(url);
      // In production, don't normalize production URLs
      if (!kDebugMode &&
          (u.host == 'api.birzum.app' || u.host == 'birzum.app')) {
        return url;
      }
      // In debug mode, normalize localhost URLs
      if (kDebugMode &&
          (u.host == 'localhost' ||
              u.host == '127.0.0.1' ||
              (!Platform.isAndroid && u.host == '10.0.2.2'))) {
        return Uri(
          scheme: o.scheme,
          host: o.host,
          port: o.hasPort ? o.port : null,
          path: u.path,
          query: u.query.isEmpty ? null : u.query,
          fragment: u.fragment.isEmpty ? null : u.fragment,
        ).toString();
      }
      return url;
    }
    if (url.startsWith('/')) return '$origin$url';
    return '$origin/$url';
  }

  static String fixPublicUrl(String url) => normalizeMediaUrl(url) ?? url;

  // ----- Token -----
  static Future<void> setToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _storage.delete(key: 'jwt_token');
      _dio.options.headers.remove('Authorization');
      return;
    }
    await _storage.write(key: 'jwt_token', value: token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static Future<String?> getToken() async {
    return _storage.read(key: 'jwt_token');
  }

  static Future<void> clearToken() async {
    await setToken(null);
    await _storage.delete(key: 'user_role');
  }

  // ----- User id cache & resolution -----
  static Future<void> setUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  static Future<String?> getUserId() => _storage.read(key: 'user_id');

  /// Tries `/auth/me` (may be 403 for your config), falls back to `/users/me`.
  static Future<String?> resolveMyUserId() async {
    // 1) Cached
    final cached = await getUserId();
    if (cached != null && cached.isNotEmpty) return cached;

    // 2) /auth/me (might be 403 → ignore)
    try {
      final r = await _dio.get('/auth/me');
      final id = _extractUserId(r.data);
      if (id != null) {
        await setUserId(id);
        return id;
      }
    } catch (_) {
      // ignore → try /users/me
    }

    // 3) /users/me
    try {
      final r = await _dio.get('/users/me');
      final id = _extractUserId(r.data);
      if (id != null) {
        await setUserId(id);
        return id;
      }
    } catch (_) {
      // swallow; caller handles null
    }

    return null;
  }

  static String? _extractUserId(dynamic data) {
    if (data is Map) {
      final m = data.cast<String, dynamic>();
      final candidates = [
        m['id'],
        m['userId'],
        m['uid'],
        (m['user'] is Map) ? (m['user'] as Map)['id'] : null,
      ];
      for (final c in candidates) {
        if (c == null) continue;
        final s = c.toString();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  // ----- Environment info (for debugging) -----
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'baseUrl': _dio.options.baseUrl,
      'isDebugMode': kDebugMode,
      'isWeb': kIsWeb,
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'origin': origin,
    };
  }

  // ----- Auth endpoints -----
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
