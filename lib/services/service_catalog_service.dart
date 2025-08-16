import 'package:dio/dio.dart';
import 'api_service.dart';

class ServiceSummary {
  final String id;
  final String name;
  final String category;
  final double price; // BigDecimal -> number
  final Duration? duration;

  ServiceSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.duration,
  });

  factory ServiceSummary.fromJson(Map<String, dynamic> j) {
    Duration? dur;
    final rawDur = j['duration'];
    if (rawDur != null) {
      // Accept ISO-8601 PTxxHxxMxxS or "HH:MM:SS" (server choice)
      final s = rawDur.toString();
      if (s.startsWith('PT')) {
        // rough parse
        final h = RegExp(r'(\d+)H').firstMatch(s)?.group(1);
        final m = RegExp(r'(\d+)M').firstMatch(s)?.group(1);
        final sec = RegExp(r'(\d+)S').firstMatch(s)?.group(1);
        dur = Duration(
          hours: int.tryParse(h ?? '0') ?? 0,
          minutes: int.tryParse(m ?? '0') ?? 0,
          seconds: int.tryParse(sec ?? '0') ?? 0,
        );
      } else if (s.contains(':')) {
        final p = s.split(':');
        dur = Duration(
          hours: int.tryParse(p[0]) ?? 0,
          minutes: (p.length > 1) ? int.tryParse(p[1]) ?? 0 : 0,
          seconds: (p.length > 2) ? int.tryParse(p[2]) ?? 0 : 0,
        );
      }
    }
    return ServiceSummary(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      price: (j['price'] is num) ? (j['price'] as num).toDouble() : 0,
      duration: dur,
    );
  }
}

class ServiceCatalogService {
  final Dio _dio = ApiService.client;

  /// GET /services/public/provider/{providerId}/services
  Future<List<ServiceSummary>> byProvider(String providerId) async {
    final r = await _dio.get('/services/public/provider/$providerId/services');
    return (r.data as List)
        .cast<Map<String, dynamic>>()
        .map(ServiceSummary.fromJson)
        .toList();
  }

  /// Optional future: by worker
  Future<List<ServiceSummary>> byWorker(String workerId) async {
    final r = await _dio.get('/services/public/worker/$workerId/services');
    return (r.data as List)
        .cast<Map<String, dynamic>>()
        .map(ServiceSummary.fromJson)
        .toList();
  }
}
