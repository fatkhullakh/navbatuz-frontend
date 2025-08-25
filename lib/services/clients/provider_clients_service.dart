import 'package:dio/dio.dart';
import '../api_service.dart';

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

  Future<List<ProviderClientHit>> search(String providerId, String q) async {
    final r = await _dio.get('/providers/$providerId/clients/search',
        queryParameters: {'q': q});
    final list = (r.data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => ProviderClientHit.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
