import 'package:dio/dio.dart';
import '../api_service.dart';

/// Tries several likely endpoints to get the current user's providerId.
/// Returns null if none work. Safe to keep as-is and refine later.
class ProviderResolverService {
  final Dio _dio = ApiService.client;

  // Future<String?> resolveMyProviderId() async {
  //   // Ordered guesses (stop at first that returns an id)
  //   final candidates = <Future<String?> Function()>[
  //     _from('/providers/me'),
  //   ];

  //   for (final fn in candidates) {
  //     try {
  //       final id = await fn();
  //       if (id != null && id.isNotEmpty) return id;
  //     } catch (_) {
  //       // ignore and try next
  //     }
  //   }
  //   return null;
  // }

  Future<String> resolveMyProviderId() async {
    try {
      final r = await _dio.get('/providers/me');
      final id = r.data?['id'];
      if (id is String && id.isNotEmpty) return id;
    } on DioException catch (e) {
      // fall through for 401/403/404
      final sc = e.response?.statusCode ?? 0;
      if (sc != 401 && sc != 403 && sc != 404) rethrow;
    }

    // receptionist path
    final r2 = await _dio.get('/receptionists/my-provider');
    final pid = r2.data?['providerId'];
    if (pid is String && pid.isNotEmpty) return pid;

    throw StateError('No provider mapped to current user.');
  }

  // Helper to build a getter for a specific path.
  Future<String?> Function() _from(String path) {
    return () async {
      final r = await _dio.get(path);
      // Expecting a JSON object with an "id" field.
      if (r.data is Map && (r.data as Map)['id'] != null) {
        return (r.data as Map)['id'].toString();
      }
      // Some endpoints might wrap it like { "provider": { "id": "..." } }
      if (r.data is Map &&
          (r.data as Map)['provider'] is Map &&
          ((r.data as Map)['provider'] as Map)['id'] != null) {
        return ((r.data as Map)['provider'] as Map)['id'].toString();
      }
      return null;
    };
  }
}
