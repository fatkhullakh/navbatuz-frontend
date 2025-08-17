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
  final String name; // name + surname nicely combined

  WorkerLite({required this.id, required this.name});

  factory WorkerLite.fromJson(Map<String, dynamic> j) {
    final n = (j['name'] ?? '').toString().trim();
    final s = (j['surname'] ?? '').toString().trim();
    final combined = [n, s].where((e) => e.isNotEmpty).join(' ');
    return WorkerLite(
      id: (j['id'] ?? '').toString(),
      name: combined.isNotEmpty
          ? combined
          : (j['fullName'] ?? 'Worker').toString(),
    );
  }
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

class ProvidersDetails {
  final String id;
  final String name;
  final String? description;
  final String category;
  final List<WorkerLite> workers;
  final String email;
  final String phone;
  final double avgRating;
  final List<BusinessHourItem> businessHours;
  final LocationSummary? location;

  ProvidersDetails({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.workers,
    required this.email,
    required this.phone,
    required this.avgRating,
    required this.businessHours,
    this.location,
  });

  factory ProvidersDetails.fromJson(Map<String, dynamic> j) => ProvidersDetails(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        category: (j['category'] ?? '').toString(),
        workers: ((j['workers'] as List?) ?? const [])
            .map((e) => WorkerLite.fromJson(e as Map<String, dynamic>))
            .toList(),
        email: (j['email'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        avgRating:
            (j['avgRating'] is num) ? (j['avgRating'] as num).toDouble() : 0,
        businessHours: ((j['businessHours'] as List?) ?? const [])
            .map((e) => BusinessHourItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        location: (j['location'] != null)
            ? LocationSummary.fromJson(j['location'])
            : null,
      );
}

class ProviderPublicService {
  final _dio = ApiService.client;

  Future<ProviderResponse> getById(String id) async {
    final r = await _dio.get('/providers/public/$id');
    return ProviderResponse.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ProvidersDetails> getDetails(String id) async {
    final r = await _dio.get('/providers/public/$id/details');
    return ProvidersDetails.fromJson(r.data as Map<String, dynamic>);
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
