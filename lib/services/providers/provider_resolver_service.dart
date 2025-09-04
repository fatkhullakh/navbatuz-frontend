import 'package:dio/dio.dart';
import '../api_service.dart';

/// Resolve the current user's providerId using your existing endpoint.
/// Your backend already allows OWNER/RECEPTIONIST/WORKER here.
class ProviderResolverService {
  final Dio _dio = ApiService.client;

  Future<String> resolveMyProviderId() async {
    // Primary path: /providers/me returns { id, ... }
    final r = await _dio.get('/providers/me');
    final data = r.data;
    final id = (data is Map) ? data['id'] : null;
    if (id is String && id.isNotEmpty) return id;

    throw StateError('No provider mapped to current user.');
  }
}
