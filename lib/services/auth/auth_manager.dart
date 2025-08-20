import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthManager {
  AuthManager._();
  static final instance = AuthManager._();
  static const _storage = FlutterSecureStorage();

  Future<void> setAccessToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getAccessToken() => _storage.read(key: 'jwt_token');

  Future<void> setRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  Future<String?> getRole() => _storage.read(key: 'user_role');

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
  }
}
