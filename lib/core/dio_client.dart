import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  static const _storage = FlutterSecureStorage();

  static Dio build() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl(),
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          await _storage.delete(key: 'jwt_token');
          // TODO: broadcast logout (we’ll wire this later)
        }
        handler.next(err);
      },
    ));

    return dio;
  }

  static String _baseUrl() {
    if (kIsWeb) return 'http://localhost:8080/api'; // WEB
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api'; // EMULATOR
    return 'http://localhost:8080/api'; // DESKTOP/iOS
  }
}
