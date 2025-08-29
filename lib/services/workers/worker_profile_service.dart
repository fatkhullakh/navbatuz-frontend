import 'package:dio/dio.dart';
import '../../services/api_service.dart';

enum WorkerStatus { AVAILABLE, UNAVAILABLE, ON_BREAK, ON_LEAVE }

WorkerStatus _statusFrom(String? s) {
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

String _statusToString(WorkerStatus s) => s.name; // matches backend enum

class WorkerDetailsLite {
  final String id;
  final String? fullName;
  final String? providerName;
  final WorkerStatus status;
  final bool isActive;
  final String? avatarUrl;

  WorkerDetailsLite({
    required this.id,
    required this.fullName,
    required this.providerName,
    required this.status,
    required this.isActive,
    required this.avatarUrl,
  });

  factory WorkerDetailsLite.fromJson(Map<String, dynamic> j) =>
      WorkerDetailsLite(
        id: j['id']?.toString() ?? '',
        fullName: j['fullName']?.toString(),
        providerName: j['providerName']?.toString(),
        status: _statusFrom(j['status']?.toString()),
        isActive: (j['isActive'] as bool?) ?? true,
        avatarUrl: j['avatarUrl']?.toString(),
      );
}

class WorkerProfileService {
  final Dio _dio = ApiService.client;

  /// Current logged-in worker
  Future<WorkerDetailsLite> getMe() async {
    final r = await _dio.get('/workers/me');
    return WorkerDetailsLite.fromJson(Map<String, dynamic>.from(r.data as Map));
    // response example:
    // {"id":"...","fullName":"...","providerName":"...","status":"AVAILABLE", ...}
  }

  /// Any worker by id
  Future<WorkerDetailsLite> getById(String workerId) async {
    final r = await _dio.get('/workers/$workerId');
    return WorkerDetailsLite.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// Partial update: only status (server accepts partial UpdateWorkerRequest)
  Future<WorkerDetailsLite> updateStatus(
      String workerId, WorkerStatus status) async {
    final r = await _dio.put('/workers/$workerId', data: {
      'status': _statusToString(status),
    });
    return WorkerDetailsLite.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
