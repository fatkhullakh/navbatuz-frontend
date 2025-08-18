import 'package:dio/dio.dart';
import 'api_service.dart';

class ServiceSummary {
  final String id;
  final String name;
  final String category;
  final int price; // integer “sum”
  final Duration? duration;
  ServiceSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.duration,
  });

  factory ServiceSummary.fromJson(Map<String, dynamic> j) => ServiceSummary(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        price: (j['price'] is num) ? (j['price'] as num).toInt() : 0,
        duration: _parseIsoDuration(j['duration']?.toString()),
      );

  static Duration? _parseIsoDuration(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    // Accepts "PT30M", "PT1H", "PT1H30M"
    final re = RegExp(r'^PT(?:(\d+)H)?(?:(\d+)M)?$');
    final m = re.firstMatch(iso);
    if (m == null) return null;
    final h = int.tryParse(m.group(1) ?? '0') ?? 0;
    final mnts = int.tryParse(m.group(2) ?? '0') ?? 0;
    return Duration(hours: h, minutes: mnts);
  }
}

class ServiceDetail {
  final String id;
  final String name;
  final String? description;
  final String category;
  final int price;
  final Duration duration;
  final String providerId;
  final List<String> workerIds;

  ServiceDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.duration,
    required this.providerId,
    required this.workerIds,
  });

  factory ServiceDetail.fromJson(Map<String, dynamic> j) => ServiceDetail(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        category: (j['category'] ?? '').toString(),
        price: (j['price'] is num) ? (j['price'] as num).toInt() : 0,
        duration: ServiceSummary._parseIsoDuration(j['duration']?.toString()) ??
            const Duration(minutes: 30),
        providerId: (j['providerId'] ?? '').toString(),
        workerIds: ((j['workerIds'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class ServiceCatalogService {
  final _dio = ApiService.client;

  Future<List<ServiceSummary>> byProvider(String providerId) async {
    final r = await _dio.get('/services/public/provider/$providerId/services');
    return (r.data as List)
        .map((e) => ServiceSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceDetail> getDetail(String serviceId) async {
    final r = await _dio.get('/services/public/$serviceId');
    return ServiceDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> setImage(String serviceId, String url) async {
    await _dio.put('/services/$serviceId/image', data: {'url': url});
  }
}
