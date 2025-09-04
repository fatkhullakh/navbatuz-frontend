import 'package:dio/dio.dart';
import '../api_service.dart';
import '../providers/provider_resolver_service.dart';

class ProviderClientHit {
  final String id;
  final String? name;
  final String? phoneMasked;
  final String personType; // "CUSTOMER" | "GUEST"
  final String linkId; // customerId or guestId depending on personType

  ProviderClientHit({
    required this.id,
    required this.name,
    required this.phoneMasked,
    required this.personType,
    required this.linkId,
  });

  factory ProviderClientHit.fromJson(Map<String, dynamic> j) {
    return ProviderClientHit(
      id: (j['id'] ?? '').toString(),
      name: j['name']?.toString(),
      phoneMasked: j['phoneMasked']?.toString(),
      personType: (j['personType'] ?? '').toString(),
      linkId: (j['linkId'] ?? '').toString(),
    );
  }
}

class ProviderClientsService {
  final Dio _dio = ApiService.client;
  final _resolver = ProviderResolverService();

  /// If providerId is wrong for the logged-in user (403), we retry
  /// with the user's own provider (from /providers/me).
  /// If that still 403s, we throw StateError('not_staff') for the UI to handle.
  Future<List<ProviderClientHit>> search({
    String? providerId,
    required String q,
  }) async {
    // Prefer caller's id, but we’ll fall back if it’s not allowed.
    String pid = providerId ?? await _resolver.resolveMyProviderId();

    try {
      final r = await _dio.get(
        '/providers/$pid/clients/search',
        queryParameters: {'q': q},
      );
      final list = (r.data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => ProviderClientHit.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    } on DioException catch (e) {
      final sc = e.response?.statusCode ?? 0;
      if (sc == 403) {
        // Only retry if caller passed a pid that might not match the logged-in user's provider.
        try {
          final myPid = await _resolver.resolveMyProviderId();
          if (myPid != pid) {
            final r2 = await _dio.get(
              '/providers/$myPid/clients/search',
              queryParameters: {'q': q},
            );
            final list = (r2.data as List?) ?? const [];
            return list
                .whereType<Map>()
                .map((e) => ProviderClientHit.fromJson(
                      Map<String, dynamic>.from(e),
                    ))
                .toList();
          }
        } catch (_) {
          // fall through to not_staff
        }
        throw StateError('not_staff');
      }
      rethrow;
    }
  }
}
