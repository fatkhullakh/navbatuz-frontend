import 'package:dio/dio.dart';
import '../services/api_service.dart';

class ProviderPublicService {
  final _dio = ApiService.client;

  Future<ProviderPublic> getProvider(String id) async {
    final r = await _dio.get('/providers/public/$id');
    return ProviderPublic.fromJson(r.data as Map<String, dynamic>, id);
  }

  Future<LocationSummary> getLocation(String providerId) async {
    final r = await _dio.get('/providers/public/$providerId/location');
    return LocationSummary.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<BusinessHourItem>> getBusinessHours(String providerId) async {
    final r = await _dio.get('/providers/public/$providerId/business-hours');
    final list = (r.data as List).cast<Map<String, dynamic>>();
    return list.map(BusinessHourItem.fromJson).toList();
  }

  Future<List<ServiceSummary>> getServices(String providerId) async {
    // Adjust base if your service controller is /services/...
    final r = await _dio.get('/services/public/provider/$providerId');
    final list = (r.data as List).cast<Map<String, dynamic>>();
    return list.map(ServiceSummary.fromJson).toList();
  }

  Future<Set<String>> getFavouriteIds() async {
    final r = await _dio.get('/customers/favourites');
    final list = (r.data as List).map((e) => e.toString()).toList();
    return Set<String>.from(list);
  }

  Future<void> setFavourite(String providerId, bool fav) async {
    if (fav) {
      await _dio.post('/customers/favourites/$providerId');
    } else {
      await _dio.delete('/customers/favourites/$providerId');
    }
  }
}

/// MODELS

class ProviderPublic {
  final String id;
  final String name;
  final String? description;
  final double rating;
  final String category;

  ProviderPublic({
    required this.id,
    required this.name,
    required this.description,
    required this.rating,
    required this.category,
  });

  factory ProviderPublic.fromJson(Map<String, dynamic> j, String id) {
    return ProviderPublic(
      id: id,
      name: (j['name'] ?? '').toString(),
      description: j['description']?.toString(),
      rating:
          (j['avgRating'] is num) ? (j['avgRating'] as num).toDouble() : 0.0,
      category: j['category']?.toString() ?? '',
    );
    // NOTE: your /providers/public/{id} returns ProvidersDetails.
    // If field names differ, map accordingly here.
  }
}

class LocationSummary {
  final String? addressLine1;
  final String? city;
  final String? countryIso2;

  LocationSummary({this.addressLine1, this.city, this.countryIso2});

  String get compact {
    final p = <String>[];
    if ((addressLine1 ?? '').isNotEmpty) p.add(addressLine1!);
    if ((city ?? '').isNotEmpty) p.add(city!);
    if ((countryIso2 ?? '').isNotEmpty) p.add(countryIso2!);
    return p.join(', ');
  }

  factory LocationSummary.fromJson(Map<String, dynamic> j) => LocationSummary(
        addressLine1: j['addressLine1']?.toString(),
        city: j['city']?.toString(),
        countryIso2: j['countryIso2']?.toString(),
      );
}

class BusinessHourItem {
  final String day; // e.g., "MONDAY"
  final String start; // "HH:mm:ss"
  final String end; // "HH:mm:ss"

  BusinessHourItem({required this.day, required this.start, required this.end});

  factory BusinessHourItem.fromJson(Map<String, dynamic> j) => BusinessHourItem(
        day: j['day']?.toString() ?? '',
        start: j['startTime']?.toString() ?? '',
        end: j['endTime']?.toString() ?? '',
      );
}

class ServiceSummary {
  final String id;
  final String name;
  final String category;
  final double price;
  final Duration? duration;

  ServiceSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.duration,
  });

  static Duration? _parseIsoDuration(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    // Expect "PTxxHxxMxxS" (Jackson)
    final r = RegExp(r'^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$');
    final m = r.firstMatch(iso);
    if (m == null) return null;
    final h = int.tryParse(m.group(1) ?? '0') ?? 0;
    final mm = int.tryParse(m.group(2) ?? '0') ?? 0;
    final s = int.tryParse(m.group(3) ?? '0') ?? 0;
    return Duration(hours: h, minutes: mm, seconds: s);
  }

  factory ServiceSummary.fromJson(Map<String, dynamic> j) => ServiceSummary(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        category: j['category']?.toString() ?? '',
        price: (j['price'] is num) ? (j['price'] as num).toDouble() : 0.0,
        duration: _parseIsoDuration(j['duration']?.toString()),
      );
}
