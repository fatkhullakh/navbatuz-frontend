// lib/services/favorites_service.dart
import 'package:dio/dio.dart';
import 'api_service.dart';

class FavoriteService {
  final Dio _dio = ApiService.client;

  /// Returns favourite provider IDs (UUID strings).
  /// Supports BOTH shapes:
  ///  - [ "id1", "id2", ... ]
  ///  - [ {id: "...", name: "...", ...}, ... ]
  Future<List<String>> listFavoriteIds() async {
    final r = await _dio.get('/customers/favourites');
    final data = r.data;

    if (data is List) {
      if (data.isEmpty) return <String>[];

      // Case A: list of objects
      if (data.first is Map) {
        final out = <String>[];
        for (final e in data) {
          final m = Map<String, dynamic>.from(e as Map);
          final id = m['id']?.toString();
          if (id != null && id.isNotEmpty) out.add(id);
        }
        return out;
      }

      // Case B: list of strings/uuids
      return data.map((e) => e.toString()).toList();
    }

    return <String>[];
  }

  Future<void> addFavorite(String providerId) async {
    await _dio.post('/customers/favourites/$providerId');
  }

  Future<void> removeFavorite(String providerId) async {
    await _dio.delete('/customers/favourites/$providerId');
  }

  /// Convenience
  Future<bool> isFavorite(String providerId) async {
    final ids = await listFavoriteIds();
    return ids.contains(providerId);
  }
}
