// lib/services/workers/worker_profile_service.dart
import 'package:dio/dio.dart';
import '../api_service.dart';

/// ----- Status enum + helpers -----
enum WorkerStatus { AVAILABLE, UNAVAILABLE, ON_BREAK, ON_LEAVE }

WorkerStatus _statusFromString(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'AVAILABLE':
      return WorkerStatus.AVAILABLE;
    case 'ON_BREAK':
      return WorkerStatus.ON_BREAK;
    case 'ON_LEAVE':
      return WorkerStatus.ON_LEAVE;
    case 'UNAVAILABLE':
    default:
      return WorkerStatus.UNAVAILABLE;
  }
}

/// Avoid using Enum.name to support older Dart SDKs.
String _statusToString(WorkerStatus s) {
  switch (s) {
    case WorkerStatus.AVAILABLE:
      return 'AVAILABLE';
    case WorkerStatus.UNAVAILABLE:
      return 'UNAVAILABLE';
    case WorkerStatus.ON_BREAK:
      return 'ON_BREAK';
    case WorkerStatus.ON_LEAVE:
      return 'ON_LEAVE';
  }
}

/// ----- DTO (lightweight but rich enough for mini card) -----
class WorkerDetailsLite {
  final String id;

  /// Display name. Sourced from `fullName` or `name`.
  final String name;

  /// Optional full name if backend provides it.
  final String? fullName;

  /// Provider name/id (helpful for showing “works at …”)
  final String? providerName;
  final String? providerId;

  /// Raw worker type string (e.g., BARBER, STYLIST)
  final String? workerType;

  final WorkerStatus status;
  final bool isActive;

  /// Public avatar URL (already normalized if possible)
  final String? avatarUrl;

  /// Average rating if available
  final double? avgRating;

  WorkerDetailsLite({
    required this.id,
    required this.name,
    required this.fullName,
    required this.providerName,
    required this.providerId,
    required this.workerType,
    required this.status,
    required this.isActive,
    required this.avatarUrl,
    required this.avgRating,
  });

  factory WorkerDetailsLite.fromJson(Map<String, dynamic> j) {
    // Names
    final String full = (j['fullName'] ?? j['name'] ?? '').toString().trim();
    final String displayName = full.isNotEmpty ? full : 'Worker';

    // Provider fallbacks (either flattened or nested under "provider")
    String? provName = j['providerName']?.toString();
    String? provId = j['providerId']?.toString();
    final provMap = j['provider'];
    if (provName == null && provMap is Map) {
      provName = provMap['name']?.toString();
    }
    if (provId == null && provMap is Map) {
      provId = provMap['id']?.toString();
    }

    // Active flag can come as "isActive" or "active"
    final dynamic activeDyn = j['isActive'] ?? j['active'];
    final bool active =
        activeDyn == true || activeDyn?.toString().toLowerCase() == 'true';

    // Avatar normalization if your ApiService supports it
    final rawAvatar = (j['avatarUrl'] ?? '').toString();
    final normalizedAvatar =
        ApiService.normalizeMediaUrl(rawAvatar) ?? rawAvatar;

    // Avg rating (number or string)
    double? avg;
    final ar = j['avgRating'];
    if (ar is num) {
      avg = ar.toDouble();
    } else if (ar != null) {
      avg = double.tryParse(ar.toString());
    }

    return WorkerDetailsLite(
      id: (j['id'] ?? '').toString(),
      name: displayName,
      fullName: full.isEmpty ? null : full,
      providerName: provName,
      providerId: provId,
      workerType: j['workerType']?.toString(),
      status: _statusFromString(j['status']?.toString()),
      isActive: active,
      avatarUrl: normalizedAvatar.isEmpty ? null : normalizedAvatar,
      avgRating: avg,
    );
  }
}

/// ----- Service -----
class WorkerProfileService {
  final Dio _dio = ApiService.client;

  /// Current logged-in worker
  /// GET /workers/me
  Future<WorkerDetailsLite> getMe() async {
    final r = await _dio.get('/workers/me');
    return WorkerDetailsLite.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// Any worker by id (tries secure endpoint first; falls back to public)
  /// GET /workers/{id}  → if forbidden/not found, tries
  /// GET /workers/public/{id}/details
  Future<WorkerDetailsLite> getById(String workerId) async {
    try {
      final r = await _dio.get('/workers/$workerId');
      return WorkerDetailsLite.fromJson(
          Map<String, dynamic>.from(r.data as Map));
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      if (code == 403 || code == 404) {
        final r = await _dio.get('/workers/public/$workerId/details');
        return WorkerDetailsLite.fromJson(
            Map<String, dynamic>.from(r.data as Map));
      }
      rethrow;
    }
  }

  /// Partial update: only status (server accepts partial UpdateWorkerRequest)
  /// PUT /workers/{id} { "status": "AVAILABLE" }
  Future<WorkerDetailsLite> updateStatus(
      String workerId, WorkerStatus status) async {
    final r = await _dio.put('/workers/$workerId', data: {
      'status': _statusToString(status),
    });
    return WorkerDetailsLite.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// PUT /workers/{id}/activate
  Future<void> activate(String workerId) async {
    await _dio.put('/workers/$workerId/activate');
  }

  /// PUT /workers/{id}/deactivate
  Future<void> deactivate(String workerId) async {
    await _dio.put('/workers/$workerId/deactivate');
  }
}
