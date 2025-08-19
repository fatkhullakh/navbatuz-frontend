import 'package:dio/dio.dart';
import 'api_service.dart';
import 'provider_public_service.dart'; // WorkerLite

Duration? _parseIsoDuration(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    final str = s.toUpperCase();
    if (!str.startsWith('PT')) return null;
    var h = 0, m = 0, sec = 0;

    final hIdx = str.indexOf('H');
    final mIdx = str.indexOf('M');
    final sIdx = str.indexOf('S');

    if (hIdx != -1) {
      h = int.tryParse(str.substring(2, hIdx)) ?? 0;
    }
    if (mIdx != -1) {
      final start = (hIdx == -1) ? 2 : hIdx + 1;
      m = int.tryParse(str.substring(start, mIdx)) ?? 0;
    }
    if (sIdx != -1) {
      final start = (mIdx != -1) ? mIdx + 1 : (hIdx != -1 ? hIdx + 1 : 2);
      sec = int.tryParse(str.substring(start, sIdx)) ?? 0;
    }

    return Duration(hours: h, minutes: m, seconds: sec);
  } catch (_) {
    return null;
  }
}

class ServiceSummary {
  final String id;
  final String name;
  final String category; // keep for later use if needed
  final String? description; // NEW
  final int price; // integer money
  final Duration? duration;

  ServiceSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.duration,
    this.description, // NEW
  });

  factory ServiceSummary.fromJson(Map<String, dynamic> j) => ServiceSummary(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        description: j['description']?.toString(), // NEW
        price: ((j['price'] is num) ? (j['price'] as num).round() : 0),
        duration: _parseIsoDuration(j['duration']?.toString()),
      );
}

class ServiceDetails {
  final String id;
  final String name;
  final String? description;
  final String category;
  final int price;
  final Duration? duration;
  final List<String> imageUrls;
  final List<WorkerLite> workers;
  final List<String> workerIds;
  final String? providerId; // NEW

  ServiceDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.duration,
    required this.imageUrls,
    required this.workers,
    required this.workerIds,
    this.providerId, // NEW
  });

  factory ServiceDetails.fromJson(Map<String, dynamic> j) {
    List<String> parseImages(dynamic raw) {
      if (raw is List && raw.isNotEmpty) {
        if (raw.first is String) {
          return raw.cast<String>();
        }
        if (raw.first is Map) {
          return raw
              .map<String>((e) => (e['url'] ?? '').toString())
              .where((u) => u.isNotEmpty)
              .toList();
        }
      }
      return const [];
    }

    final List<String> collected = [
      ...parseImages(j['images'] ?? j['imageUrls']),
    ];
    final String? single = (j['logoUrl'] as String?)?.toString();
    if (single != null && single.isNotEmpty) collected.add(single);

    final List<String> normalized =
        collected.map((u) => ApiService.fixPublicUrl(u)).toList();

    final List<WorkerLite> workers = ((j['workers'] as List?) ?? const [])
        .whereType<Map>()
        .map((w) => WorkerLite.fromJson(Map<String, dynamic>.from(w)))
        .toList();

    final List<String> workerIds = ((j['workerIds'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final List<String> derived =
        workers.map((w) => w.id).where((id) => id.isNotEmpty).toList();
    final List<String> finalIds = workerIds.isNotEmpty ? workerIds : derived;

    return ServiceDetails(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      description: j['description']?.toString(),
      category: (j['category'] ?? '').toString(),
      price: ((j['price'] is num) ? (j['price'] as num).round() : 0),
      duration: _parseIsoDuration(j['duration']?.toString()),
      imageUrls: normalized,
      workers: workers,
      workerIds: finalIds,
      providerId: j['providerId']?.toString(), // NEW
    );
  }
}

/// Simple page wrapper for search results
class PageResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int totalElements;
  final bool last;
  PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.last,
  });
}

class ServiceCatalogService {
  final Dio _dio = ApiService.client;

  Future<List<ServiceSummary>> byProvider(String providerId) async {
    final r = await _dio.get('/services/public/provider/$providerId/services');
    final list = (r.data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((m) => ServiceSummary.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Get providerId for a given service (from fallback endpoint).
  Future<String?> getProviderIdForService(String serviceId) async {
    final r = await _dio.get('/services/public/$serviceId');
    if (r.data is Map && (r.data as Map)['providerId'] != null) {
      return (r.data as Map)['providerId'].toString();
    }
    return null;
    // NOTE: if your backend adds providerId to search response, you can drop this extra call.
  }

  /// Search services via `/services/public/search`
  Future<PageResult<ServiceSummary>> searchServices({
    String? keyword, // optional; backend may ignore if not supported
    String? category, // enum name e.g. "CLINIC"
    num? minPrice,
    num? maxPrice,
    int page = 0,
    int size = 20,
  }) async {
    final qp = <String, dynamic>{
      if (category != null && category.isNotEmpty) 'category': category,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      // If your backend adds a `q` or `keyword` param, just pass it; Spring will ignore unknown params.
      if (keyword != null && keyword.trim().isNotEmpty) 'q': keyword.trim(),
      'page': page,
      'size': size,
    };

    final r = await _dio.get('/services/public/search', queryParameters: qp);

    final content = (r.data is Map && (r.data as Map)['content'] is List)
        ? ((r.data as Map)['content'] as List)
        : const <dynamic>[];

    final items = content
        .whereType<Map>()
        .map((m) => ServiceSummary.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    final m = Map<String, dynamic>.from(r.data as Map);
    return PageResult<ServiceSummary>(
      items: items,
      page: (m['number'] as int?) ?? page,
      size: (m['size'] as int?) ?? size,
      totalElements: (m['totalElements'] as int?) ?? items.length,
      last: (m['last'] as bool?) ?? true,
    );
  }

  /// Main details fetcher used by UI
  Future<ServiceDetails> details({
    required String serviceId,
    required String providerId,
  }) async {
    Map<String, dynamic>? json;

    try {
      final r = await _dio.get('/services/public/$serviceId/details');
      if (r.data is Map) {
        json = Map<String, dynamic>.from(r.data as Map);
      }
    } catch (_) {}

    if (json == null) {
      try {
        final r = await _dio.get('/services/public/$serviceId');
        if (r.data is Map) {
          json = Map<String, dynamic>.from(r.data as Map);
        }
      } catch (_) {}
    }

    if (json == null) {
      // Fallback: build from provider’s list + provider workers
      final all = await byProvider(providerId);
      final s = all.firstWhere((e) => e.id == serviceId);
      final providerSvc = ProviderPublicService();
      final pd = await providerSvc.getDetails(providerId);
      json = {
        'id': s.id,
        'name': s.name,
        'description': s.description, // was null
        'category': s.category,
        'price': s.price,
        'duration': s.duration == null
            ? null
            : 'PT${s.duration!.inHours > 0 ? '${s.duration!.inHours}H' : ''}${s.duration!.inMinutes % 60}M',
        'imageUrls': const [],
        'workers': pd.workers.map((w) => {'id': w.id, 'name': w.name}).toList(),
        'workerIds': pd.workers.map((w) => w.id).toList(),
        'providerId': providerId,
      };
    }

    return ServiceDetails.fromJson(json);
  }

  /// Backwards-compat alias
  Future<ServiceDetails> getDetail(String serviceId, String providerId) =>
      details(serviceId: serviceId, providerId: providerId);
}
