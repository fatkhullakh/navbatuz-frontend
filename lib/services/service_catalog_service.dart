import 'package:dio/dio.dart';
import 'api_service.dart';

/// Small ISO-8601 duration parser (PT30M, PT1H30M, PT45M → minutes)
int _parseIsoDurationToMinutes(String? iso) {
  if (iso == null || iso.isEmpty) return 0;
  final s = iso.toUpperCase();
  final tIndex = s.indexOf('T');
  if (tIndex == -1) return 0;
  final part = s.substring(tIndex + 1);
  int minutes = 0;

  final hIndex = part.indexOf('H');
  if (hIndex != -1) {
    final h = int.tryParse(part.substring(0, hIndex)) ?? 0;
    minutes += h * 60;
  }
  final mIndex = part.indexOf('M');
  if (mIndex != -1) {
    final start = (hIndex == -1) ? 0 : hIndex + 1;
    final m = int.tryParse(part.substring(start, mIndex)) ?? 0;
    minutes += m;
  }
  return minutes;
}

class ServiceSummary {
  final String id;
  final String name;
  final String category;
  final int price; // sums
  final int durationMinutes;

  ServiceSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.durationMinutes,
  });

  factory ServiceSummary.fromJson(Map<String, dynamic> j) => ServiceSummary(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        price: (j['price'] is num) ? (j['price'] as num).round() : 0,
        durationMinutes: _parseIsoDurationToMinutes(j['duration']?.toString()),
      );
}

class ServiceDetail extends ServiceSummary {
  final String? description;
  final bool isActive;
  final String providerId;
  final List<String> workerIds;

  ServiceDetail({
    required super.id,
    required super.name,
    required super.category,
    required super.price,
    required super.durationMinutes,
    required this.description,
    required this.isActive,
    required this.providerId,
    required this.workerIds,
  });

  factory ServiceDetail.fromJson(Map<String, dynamic> j) => ServiceDetail(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        category: (j['category'] ?? '').toString(),
        price: (j['price'] is num) ? (j['price'] as num).round() : 0,
        durationMinutes: _parseIsoDurationToMinutes(j['duration']?.toString()),
        isActive: (j['isActive'] == true),
        providerId: (j['providerId'] ?? '').toString(),
        workerIds: ((j['workerIds'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// For “Anyone”: a slot time paired with a worker who can serve at that time.
class SlotOption {
  final String hhmmss; // "HH:mm:ss"
  final String workerId;
  SlotOption({required this.hhmmss, required this.workerId});
}

class ServiceCatalogService {
  final Dio _dio = ApiService.client;

  Future<ServiceDetail> getDetail(String serviceId) async {
    final r = await _dio.get('/services/public/$serviceId');
    return ServiceDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<String>> freeSlotsRaw({
    required String workerId,
    required String dateIso, // "yyyy-MM-dd"
    required int serviceDurationMinutes,
  }) async {
    try {
      final r = await _dio.get(
        '/workers/free-slots/$workerId',
        queryParameters: {
          'date': dateIso,
          'serviceDurationMinutes': serviceDurationMinutes,
        },
      );
      final list = r.data as List<dynamic>? ?? const [];
      return list.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      // If no planned availability → some backends answer 403; treat as “no slots”
      if (e.response?.statusCode == 403) return const [];
      rethrow;
    }
  }

  /// Aggregate slots across multiple workers (first-come winner per time).
  Future<List<SlotOption>> freeSlotsForAny({
    required List<String> workerIds,
    required String dateIso,
    required int serviceDurationMinutes,
  }) async {
    final map = <String, String>{}; // time → workerId
    for (final wid in workerIds) {
      final times = await freeSlotsRaw(
        workerId: wid,
        dateIso: dateIso,
        serviceDurationMinutes: serviceDurationMinutes,
      );
      for (final t in times) {
        map.putIfAbsent(t, () => wid);
      }
    }
    final sorted = map.keys.toList()..sort();
    return [for (final t in sorted) SlotOption(hhmmss: t, workerId: map[t]!)];
  }
}
