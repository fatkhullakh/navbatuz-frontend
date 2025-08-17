import 'package:dio/dio.dart';
import 'api_service.dart';

class LocationSummary {
  final String id;
  final String? addressLine1;
  final String? city;
  final String? countryIso2;

  LocationSummary({
    required this.id,
    this.addressLine1,
    this.city,
    this.countryIso2,
  });

  factory LocationSummary.fromJson(Map<String, dynamic> j) => LocationSummary(
        id: (j['id'] ?? '').toString(),
        addressLine1: j['addressLine1'] as String?,
        city: j['city'] as String?,
        countryIso2: j['countryIso2'] as String?,
      );

  String get compact {
    final parts = <String>[];
    if ((addressLine1 ?? '').isNotEmpty) parts.add(addressLine1!);
    if ((city ?? '').isNotEmpty) parts.add(city!);
    if ((countryIso2 ?? '').isNotEmpty) parts.add(countryIso2!);
    return parts.join(', ');
  }
}

class BusinessHourItem {
  final String day; // e.g. "MONDAY"
  final String? start; // "HH:mm:ss" OR null
  final String? end; // "HH:mm:ss" OR null
  BusinessHourItem({required this.day, this.start, this.end});

  factory BusinessHourItem.fromJson(Map<String, dynamic> j) => BusinessHourItem(
        day: (j['day'] ?? '').toString(),
        start: (j['startTime'] as String?)?.toString(),
        end: (j['endTime'] as String?)?.toString(),
      );
}

class WorkerLite {
  final String id;
  final String name;
  final String? surname;
  WorkerLite({required this.id, required this.name, this.surname});

  factory WorkerLite.fromJson(Map<String, dynamic> j) => WorkerLite(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        surname: j['surname']?.toString(),
      );
}

class ProviderResponse {
  final String id;
  final String name;
  final String? description;
  final double avgRating;
  final String category;
  final LocationSummary? location;

  ProviderResponse({
    required this.id,
    required this.name,
    this.description,
    required this.avgRating,
    required this.category,
    this.location,
  });

  factory ProviderResponse.fromJson(Map<String, dynamic> j) => ProviderResponse(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        avgRating:
            (j['avgRating'] is num) ? (j['avgRating'] as num).toDouble() : 0,
        category: (j['category'] ?? '').toString(),
        location: (j['location'] != null)
            ? LocationSummary.fromJson(j['location'])
            : null,
      );
}

class ProvidersDetailsLite {
  final String id;
  final String name;
  final List<WorkerLite> workers;

  ProvidersDetailsLite({
    required this.id,
    required this.name,
    required this.workers,
  });

  factory ProvidersDetailsLite.fromJson(Map<String, dynamic> j) =>
      ProvidersDetailsLite(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        workers: ((j['workers'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(WorkerLite.fromJson)
            .toList(),
      );
}

class ProviderPublicService {
  final _dio = ApiService.client;

  Future<ProviderResponse> getById(String id) async {
    final r = await _dio.get('/providers/public/$id');
    return ProviderResponse.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ProvidersDetailsLite> getDetails(String providerId) async {
    final r = await _dio.get('/providers/public/$providerId/details');
    return ProvidersDetailsLite.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<String>> getFavouriteIds() async {
    final r = await _dio.get('/customers/favourites');
    return (r.data as List).map((e) => e.toString()).toList();
  }

  Future<void> setFavourite(String providerId, bool fav) async {
    if (fav) {
      await _dio.post('/customers/favourites/$providerId');
    } else {
      await _dio.delete('/customers/favourites/$providerId');
    }
  }
}
