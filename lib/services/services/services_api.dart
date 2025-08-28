import 'package:dio/dio.dart';
import '../../services/api_service.dart';

class ServiceItem {
  final String id;
  final String name;
  final int durationMinutes;
  final num? price;

  ServiceItem({
    required this.id,
    required this.name,
    required this.durationMinutes,
    this.price,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> m) {
    int _dur(dynamic v) {
      if (v == null) return 30;
      if (v is num) return v.toInt();
      final s = v.toString();
      if (s.startsWith('PT') && s.endsWith('M')) {
        return int.tryParse(s.substring(2, s.length - 1)) ?? 30;
      }
      if (s.contains(':')) {
        final p = s.split(':');
        return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
      }
      return int.tryParse(s) ?? 30;
    }

    num? _price(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    return ServiceItem(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? 'Service').toString(),
      durationMinutes: _dur(m['duration'] ?? m['durationMinutes']),
      price: _price(m['price']),
    );
  }
}

class ServicesApi {
  final Dio _dio = ApiService.client;

  Future<List<ServiceItem>> listForWorker(String workerId) async {
    final r = await _dio.get('/services/worker/all/$workerId');
    final list = (r.data as List? ?? const []);
    return list
        .whereType<Map>()
        .map((e) => ServiceItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ServiceItem>> listForProvider(String providerId) async {
    final r = await _dio.get('/services/provider/$providerId');
    final list = (r.data as List? ?? const []);
    return list
        .whereType<Map>()
        .map((e) => ServiceItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
