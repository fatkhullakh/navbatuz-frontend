import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/dio_client.dart';

class Me {
  final String id; // now required
  final String name;
  final String surname;
  final String phoneNumber;
  final String email;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? language;
  final String? country;

  const Me({
    required this.id,
    required this.name,
    required this.surname,
    required this.phoneNumber,
    required this.email,
    this.dateOfBirth,
    this.gender,
    this.language,
    this.country,
  });

  String get fullName {
    final n = name.trim(), s = surname.trim();
    if (n.isEmpty) return s;
    if (s.isEmpty) return n;
    return '$n $s';
  }

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        surname: (j['surname'] ?? '').toString(),
        phoneNumber: (j['phoneNumber'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        dateOfBirth:
            (j['dateOfBirth'] == null || j['dateOfBirth'].toString().isEmpty)
                ? null
                : DateTime.tryParse(j['dateOfBirth'].toString()),
        gender: (j['gender'] as String?)?.toString(),
        language: (j['language'] as String?)?.toString(),
        country: (j['country'] as String?)?.toString(),
      );
}

class ProfileService {
  final Dio _dio = DioClient.build();
  static final _storage = FlutterSecureStorage();

  Future<Me> getMe({bool force = false}) async {
    final r = await _dio.get(
      '/users/me',
      queryParameters:
          force ? {'_': DateTime.now().millisecondsSinceEpoch} : null,
      options: Options(headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      }),
    );
    return Me.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<Me> updatePersonal({
    required String id,
    required String name,
    required String surname,
    required String phoneNumber,
    required String email,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    final r = await _dio.put('/users/$id', data: {
      'name': name,
      'surname': surname,
      'dateOfBirth': dateOfBirth != null
          ? dateOfBirth.toIso8601String().split('T').first
          : null,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'email': email,
    });
    return Me.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<Me> updateSettings({
    required String id,
    String? language,
    String? country,
  }) async {
    final r = await _dio.put('/users/$id/settings', data: {
      if (language != null) 'language': language,
      if (country != null) 'country': country,
    });
    return Me.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<void> changePassword({
    required String id,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.put('/users/$id/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> deactivate({required String id}) async {
    await _dio.delete('/users/$id');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
  }
}
