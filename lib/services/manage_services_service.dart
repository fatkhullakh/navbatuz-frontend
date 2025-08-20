import 'package:dio/dio.dart';
import 'api_service.dart';

Duration? _parseIsoDuration(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    final str = s.toUpperCase();
    if (!str.startsWith('PT')) return null;
    var h = 0, m = 0, sec = 0;

    final hIdx = str.indexOf('H');
    final mIdx = str.indexOf('M');
    final sIdx = str.indexOf('S');

    if (hIdx != -1) h = int.tryParse(str.substring(2, hIdx)) ?? 0;
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

String? _toIso(Duration? d) {
  if (d == null) return null;
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final buf = StringBuffer('PT');
  if (h > 0) buf.write('${h}H');
  if (m > 0) buf.write('${m}M');
  if (s > 0 && h == 0) buf.write('${s}S');
  if (buf.length == 2) buf.write('0S'); // PT0S
  return buf.toString();
}

/// Backend DTO used on the provider(OWNER) side.
class ProviderServiceItem {
  final String id;
  final String name;
  final String? description;
  final String category; // backend enum name
  final num? price; // BigDecimal on server (nullable)
  final Duration? duration; // ISO on server
  final bool isActive;
  final String providerId;
  final List<String> workerIds;
  final String? logoUrl;

  ProviderServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.duration,
    required this.isActive,
    required this.providerId,
    required this.workerIds,
    this.logoUrl,
  });

  factory ProviderServiceItem.fromJson(Map<String, dynamic> j) {
    return ProviderServiceItem(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      description: j['description']?.toString(),
      category: (j['category'] ?? '').toString(),
      price: (j['price'] is num)
          ? (j['price'] as num)
          : num.tryParse('${j['price'] ?? ''}'),
      duration: _parseIsoDuration(j['duration']?.toString()),
      isActive: (j['isActive'] as bool?) ?? false,
      providerId: (j['providerId'] ?? '').toString(),
      workerIds: ((j['workerIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      logoUrl: j['logoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'duration': _toIso(duration),
        'isActive': isActive,
        'providerId': providerId,
        'workerIds': workerIds,
        'logoUrl': logoUrl,
      };
}

class CreateServiceRequest {
  final String name;
  final String? description;
  final String category; // enum name
  final num? price; // nullable
  final Duration? duration;
  final String providerId;
  final List<String> workerIds;

  CreateServiceRequest({
    required this.name,
    this.description,
    required this.category,
    this.price,
    this.duration,
    required this.providerId,
    required this.workerIds,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'duration': _toIso(duration),
        'providerId': providerId,
        'workerIds': workerIds,
      };
}

class ManageServicesService {
  final Dio _dio = ApiService.client;

  Future<List<ProviderServiceItem>> listAllByProvider(String providerId) async {
    final r = await _dio.get('/services/provider/all/$providerId');
    final list = (r.data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => ProviderServiceItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ProviderServiceItem> create(CreateServiceRequest req) async {
    final r = await _dio.post('/services', data: req.toJson());
    return ProviderServiceItem.fromJson(Map<String, dynamic>.from(r.data));
    // NOTE: backend returns detailed response
  }

  Future<void> update(ProviderServiceItem item) async {
    await _dio.put('/services/${item.id}', data: item.toUpdateJson());
  }

  Future<void> activate(String id) async {
    await _dio.put('/services/activate/$id');
  }

  Future<void> deactivate(String id) async {
    await _dio.put('/services/deactivate/$id');
  }

  Future<void> delete(String id) async {
    await _dio.delete('/services/$id');
  }

  Future<void> setImageUrl(String id, String url) async {
    await _dio.put('/services/$id/image', data: {'url': url});
  }

  Future<void> addWorker(String serviceId, String workerId) async {
    await _dio.put('/services/$serviceId/add-worker/$workerId');
  }

  Future<void> removeWorker(String serviceId, String workerId) async {
    await _dio.put('/services/$serviceId/remove-worker/$workerId');
  }
}
