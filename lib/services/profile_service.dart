import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/dio_client.dart';

class Me {
  final String name; // first name
  final String surname; // last name
  final String phone; // phoneNumber
  final String email;
  final DateTime? dateOfBirth;
  final String? gender; // MALE / FEMALE / OTHER (string from API)
  final String? language; // EN / UZ / RU ...
  final String? country; // optional

  const Me({
    required this.name,
    required this.surname,
    required this.phone,
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
        name: (j['name'] ?? '').toString(),
        surname: (j['surname'] ?? '').toString(),
        phone: (j['phoneNumber'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        dateOfBirth:
            j['dateOfBirth'] != null && j['dateOfBirth'].toString().isNotEmpty
                ? DateTime.tryParse(j['dateOfBirth'])
                : null,
        gender: (j['gender'] as String?)?.toString(),
        language: (j['language'] as String?)?.toString(),
        country: (j['country'] as String?)?.toString(),
      );
}

class ProfileService {
  final Dio _dio = DioClient.build();
  static final _storage = FlutterSecureStorage();

  Future<Me> getMe() async {
    final r = await _dio.get('/users/me'); // baseUrl has /api
    return Me.fromJson((r.data as Map).cast<String, dynamic>());
  }

  /// Update personal section.
  Future<Me> updatePersonal({
    required String name,
    required String surname,
    required String phone,
    required String email,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    final r = await _dio.put('/users/me', data: {
      'name': name,
      'surname': surname,
      'phoneNumber': phone,
      'email': email,
      if (dateOfBirth != null)
        'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
    });
    return Me.fromJson((r.data as Map).cast<String, dynamic>());
  }

  /// Update account settings section.
  Future<Me> updateSettings({
    String? language,
    String? country,
  }) async {
    final r = await _dio.put('/users/me', data: {
      if (language != null && language.isNotEmpty) 'language': language,
      if (country != null && country.isNotEmpty) 'country': country,
    });
    return Me.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
  }
}
