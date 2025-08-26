import 'package:dio/dio.dart';
import '../../services/api_service.dart';

class WorkerResolverService {
  final Dio _dio = ApiService.client;

  /// Returns current worker's id (via /workers/me).
  Future<String> resolveMyWorkerId() async {
    final r = await _dio.get('/workers/me');
    final id = (r.data is Map) ? (r.data['id']?.toString() ?? '') : '';
    if (id.isEmpty) {
      throw StateError('Could not resolve worker id');
    }
    return id;
  }
}
