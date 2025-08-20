import '../services/api_service.dart';

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

String? isoFromDuration(Duration? d) {
  if (d == null) return null;
  if (d.inSeconds == 0) return 'PT0S';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final buf = StringBuffer('PT');
  if (h > 0) buf.write('${h}H');
  if (m > 0) buf.write('${m}M');
  if (s > 0) buf.write('${s}S');
  return buf.toString();
}

class ProviderService {
  final String id;
  final String name;
  final String? description;
  final String category; // enum name
  final int? price; // integer money (UZS) or null
  final Duration? duration;
  final bool isActive;
  final String providerId;
  final List<String> workerIds;
  final String? logoUrl;

  ProviderService({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.duration,
    required this.isActive,
    required this.providerId,
    required this.workerIds,
    required this.logoUrl,
  });

  factory ProviderService.fromJson(Map<String, dynamic> j) {
    int? toIntMoney(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.round();
      final n = num.tryParse(v.toString());
      return n?.round();
    }

    return ProviderService(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      description: j['description']?.toString(),
      category: (j['category'] ?? '').toString(),
      price: toIntMoney(j['price']),
      duration: _parseIsoDuration(j['duration']?.toString()),
      isActive: (j['isActive'] as bool?) ?? false,
      providerId: (j['providerId'] ?? '').toString(),
      workerIds: ((j['workerIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      logoUrl: ApiService.normalizeMediaUrl(j['logoUrl']?.toString()),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'price': price, // backend expects BigDecimal — send int/num
        'duration': isoFromDuration(duration),
        'isActive': isActive,
        'providerId': providerId,
        'workerIds': workerIds,
        'logoUrl': logoUrl,
      };
}

class CreateServicePayload {
  final String name;
  final String? description;
  final String category; // enum name
  final int? price; // integer money (UZS) or null
  final Duration? duration;
  final String providerId;
  final List<String> workerIds;

  CreateServicePayload({
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.duration,
    required this.providerId,
    required this.workerIds,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'category': category,
        'price': price, // BigDecimal in backend; int -> JSON number is fine
        'duration': isoFromDuration(duration),
        'providerId': providerId,
        'workerIds': workerIds,
      };
}
