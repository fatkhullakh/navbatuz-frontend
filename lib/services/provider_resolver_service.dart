import 'package:dio/dio.dart';
import 'api_service.dart';

/// Tries several likely endpoints to get the current user's providerId.
/// Returns null if none work. Safe to keep as-is and refine later.
class ProviderResolverService {
  final Dio _dio = ApiService.client;

  Future<String?> resolveMyProviderId() async {
    // Ordered guesses (stop at first that returns an id)
    final candidates = <Future<String?> Function()>[
      _from('/providers/me'),
    ];

    for (final fn in candidates) {
      try {
        final id = await fn();
        if (id != null && id.isNotEmpty) return id;
      } catch (_) {
        // ignore and try next
      }
    }

    // As a last resort, you can try to fetch a list and pick the first
    // provider the user owns — but only if your payload contains ownership info.
    // Leaving it out for safety.
    return null;
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
