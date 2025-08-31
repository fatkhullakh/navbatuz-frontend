import 'package:dio/dio.dart';
import '../api_service.dart';
import 'package:intl/intl.dart';

class WorkerDetails {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final String? email;

  /// New fields for UI
  final String? status; // e.g. AVAILABLE / UNAVAILABLE / ON_BREAK / ON_LEAVE
  final double? avgRating; // 0..5
  final int? reviewsCount; // total reviews

  WorkerDetails({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.phone,
    this.email,
    this.status,
    this.avgRating,
    this.reviewsCount,
  });

  static String? _asString(dynamic v) {
    if (v == null) return null;
    return v.toString();
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory WorkerDetails.fromJson(Map<String, dynamic> j) {
    // Try common keys; fall back to nested "user": {}
    final user =
        (j['user'] is Map) ? Map<String, dynamic>.from(j['user']) : null;

    // Build display name robustly (name, fullName, user.name + user.surname)
    String buildName() {
      final fullName = _asString(j['fullName']) ?? _asString(j['displayName']);
      if (fullName != null && fullName.trim().isNotEmpty) {
        return fullName.trim();
      }

      final nameTop = _asString(j['name']);
      final surnameTop = _asString(j['surname']);
      if ((nameTop ?? '').isNotEmpty || (surnameTop ?? '').isNotEmpty) {
        return [nameTop, surnameTop]
            .where((s) => (s ?? '').isNotEmpty)
            .join(' ')
            .trim();
      }

      final userName = _asString(user?['name']);
      final userSurname = _asString(user?['surname']);
      if ((userName ?? '').isNotEmpty || (userSurname ?? '').isNotEmpty) {
        return [userName, userSurname]
            .where((s) => (s ?? '').isNotEmpty)
            .join(' ')
            .trim();
      }

      return _asString(j['name'])?.trim() ?? 'Worker';
    }

    // Status: accept multiple key variants
    final status = _asString(
      j['status'] ??
          j['workerStatus'] ??
          j['availabilityStatus'] ??
          j['availability'],
    )?.trim();

    // Rating & reviews: accept multiple key variants
    final avgRating =
        _asDouble(j['avgRating'] ?? j['averageRating'] ?? j['rating']);
    final reviewsCount =
        _asInt(j['reviewsCount'] ?? j['reviewCount'] ?? j['reviews']);

    // Contacts: top-level or nested user
    final phone = _asString(j['phone'] ??
        j['phoneNumber'] ??
        user?['phone'] ??
        user?['phoneNumber']);
    final email = _asString(j['email'] ?? user?['email']);

    // Avatar: top-level or nested user; normalize url
    final rawAvatar = _asString(j['avatarUrl'] ?? user?['avatarUrl']);
    final normalizedAvatar = ApiService.normalizeMediaUrl(rawAvatar);

    return WorkerDetails(
      id: _asString(j['id']) ?? '',
      name: buildName(),
      avatarUrl: normalizedAvatar,
      phone: phone,
      email: email,
      status: status,
      avgRating: avgRating,
      reviewsCount: reviewsCount,
    );
  }
}

class WorkerService {
  final Dio _dio = ApiService.client;

  Future<WorkerDetails> details(String workerId) async {
    // Try common public/private endpoints
    for (final path in [
      '/workers/public/$workerId/details',
    ]) {
      try {
        final r = await _dio.get(path);
        if (r.data is Map) {
          return WorkerDetails.fromJson(
              Map<String, dynamic>.from(r.data as Map));
        }
      } catch (_) {
        // try next path
      }
    }
    // Fallback minimal
    return WorkerDetails(id: workerId, name: 'Worker');
  }

  Future<List<String>> freeSlots({
    required String workerId,
    required DateTime date,
    required int serviceDurationMinutes,
  }) async {
    final df = DateFormat('yyyy-MM-dd');
    final r = await _dio.get(
      '/workers/free-slots/$workerId',
      queryParameters: {
        'date': df.format(date),
        'serviceDurationMinutes': serviceDurationMinutes,
      },
    );
    // API returns ["HH:mm:ss", ...]
    return (r.data as List).map((e) => e.toString()).toList();
  }
}
