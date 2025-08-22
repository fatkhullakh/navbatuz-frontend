import 'package:dio/dio.dart';
import '../../services/api_service.dart';

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

String? _isoFromDuration(Duration? d) {
  if (d == null) return null;
  if (d == Duration.zero) return 'PT0S';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final buf = StringBuffer('PT');
  if (h > 0) buf.write('${h}H');
  if (m > 0) buf.write('${m}M');
  if (s > 0 && h == 0) buf.write('${s}S'); // optional
  return buf.toString();
}

class OwnerServiceItem {
  final String? id;
  final String name;
  final String? description;
  final String? category;
  final num? price;
  final Duration? duration;
  final bool? isActive;
  final bool? deleted;
  final String? imageUrl;
  final String? logoUrl; // sometimes backend uses this
  final String? providerId;
  final List<String>? workerIds;

  OwnerServiceItem({
    this.id,
    required this.name,
    this.description,
    this.category,
    this.price,
    this.duration,
    this.isActive,
    this.deleted,
    this.imageUrl,
    this.logoUrl,
    this.providerId,
    this.workerIds,
  });

  factory OwnerServiceItem.fromJson(Map<String, dynamic> j) => OwnerServiceItem(
        id: j['id']?.toString(),
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        category: j['category']?.toString(),
        price: (j['price'] is num) ? j['price'] as num : null,
        duration: _parseIsoDuration(j['duration']?.toString()),
        isActive: j['isActive'] as bool? ?? j['active'] as bool?,
        imageUrl: j['imageUrl']?.toString(),
        logoUrl: j['logoUrl']?.toString(),
        providerId: j['providerId']?.toString(),
        workerIds: ((j['workerIds'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJsonForUpdate(String providerId) => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'price': price,
        'duration': _isoFromDuration(duration),
        'isActive': isActive ?? true,
        'providerId': providerId,
        'workerIds': workerIds ?? const <String>[],
        // backend field is logoUrl; keep both for tolerance
        if (imageUrl != null) 'logoUrl': imageUrl,
      };
}

class ProviderOwnerServicesService {
  final Dio _dio = ApiService.client;

  Future<List<OwnerServiceItem>> getAllByProvider(String providerId) async {
    final r = await _dio.get('/services/provider/all/$providerId',
        queryParameters: {'includeInactive': true}); // <— THIS
    final list = (r.data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((m) => OwnerServiceItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> setImage(String serviceId, String url) async {
    await _dio.put('/services/$serviceId/image', data: {'url': url});
  }

  Future<void> activate(String serviceId) async {
    await _dio.put('/services/activate/$serviceId');
  }

  Future<void> deactivate(String serviceId) async {
    await _dio.put('/services/deactivate/$serviceId');
  }

  Future<void> delete(String serviceId) async {
    await _dio.delete('/services/$serviceId');
  }

  Future<void> create({
    required String providerId,
    required String name,
    String? description,
    String? category,
    num? price,
    Duration? duration,
    bool isActive = true,
    String? imageUrl,
    List<String> workerIds = const [],
  }) async {
    final body = {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'duration': _isoFromDuration(duration),
      'providerId': providerId,
      'workerIds': workerIds,
      if (imageUrl != null) 'logoUrl': imageUrl,
    };
    await _dio.post('/services', data: body);
  }

  Future<void> update({
    required String id,
    required String providerId,
    required String name,
    String? description,
    String? category,
    num? price,
    Duration? duration,
    bool isActive = true,
    String? imageUrl,
    List<String> workerIds = const [],
  }) async {
    final item = OwnerServiceItem(
      id: id,
      name: name,
      description: description,
      category: category,
      price: price,
      duration: duration,
      isActive: isActive,
      imageUrl: imageUrl,
      workerIds: workerIds,
    );
    await _dio.put('/services/$id', data: item.toJsonForUpdate(providerId));
  }
}
