// lib/services/profile_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class Me {
  final String id;
  final String? name;
  final String? surname;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? email;
  final String? language; // 'EN' | 'RU' | 'UZ'
  final String? country;
  final String? avatarUrl;

  Me({
    required this.id,
    this.name,
    this.surname,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.email,
    this.language,
    this.country,
    this.avatarUrl,
  });

  /// Convenient display name used by Account UI
  String get fullName {
    final parts = <String>[];
    final n = (name ?? '').trim();
    final s = (surname ?? '').trim();
    if (n.isNotEmpty) parts.add(n);
    if (s.isNotEmpty) parts.add(s);
    final joined = parts.join(' ').trim();
    if (joined.isNotEmpty) return joined;
    // fallback
    if ((email ?? '').trim().isNotEmpty) return email!.trim();
    if ((phoneNumber ?? '').trim().isNotEmpty) return phoneNumber!.trim();
    return 'User';
  }

  factory Me.fromJson(Map<String, dynamic> j) {
    DateTime? dob;
    final rawDob = j['dateOfBirth'];
    if (rawDob is String && rawDob.isNotEmpty) {
      dob = DateTime.tryParse(rawDob);
    }
    return Me(
      id: (j['id'] ?? '').toString(),
      name: j['name'] as String?,
      surname: j['surname'] as String?,
      dateOfBirth: dob,
      gender: j['gender'] as String?,
      phoneNumber: j['phoneNumber'] as String?,
      email: j['email'] as String?,
      language: j['language']?.toString(),
      country: j['country']?.toString(),
      avatarUrl: j['avatarUrl']?.toString(),
    );
  }
}

class ProfileService {
  final Dio _dio = ApiService.client;
  final _storage = const FlutterSecureStorage();

  // If your ApiService.baseUrl ALREADY ends with '/api', leave prefix = ''.
  // If not, set prefix to '/api'.
  static const _prefix = '';

  /// GET /api/users/me  (no caching)
  Future<Me> getMe({bool force = false}) async {
    final resp = await _dio.get(
      '$_prefix/users/me',
      options: Options(headers: {'Cache-Control': 'no-cache'}),
      queryParameters:
          force ? {'_': DateTime.now().millisecondsSinceEpoch} : null,
    );
    return Me.fromJson(resp.data as Map<String, dynamic>);
  }

  /// PUT /api/users/{id}
  Future<void> updatePersonal({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put('$_prefix/users/$id', data: body);
  }

  /// PUT /api/users/{id}/settings
  Future<void> updateSettingsById({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put('$_prefix/users/$id/settings', data: body);
  }

  /// PUT /api/users/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.put('$_prefix/users/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
  }
}
