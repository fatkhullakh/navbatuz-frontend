// lib/services/providers/provider_owner_api.dart
import 'package:dio/dio.dart';
import '../../services/api_service.dart';

class ProviderDetailsDto {
  final String id;
  final String name;
  final String? description;
  final String category; // enum string (e.g., "CLINIC")
  final String? email;
  final String? phoneNumber;
  final String? logoUrl;

  ProviderDetailsDto({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.email,
    this.phoneNumber,
    this.logoUrl,
  });

  factory ProviderDetailsDto.fromJson(Map<String, dynamic> j) =>
      ProviderDetailsDto(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        category: (j['category'] ?? '').toString(),
        email: j['email']?.toString(),
        phoneNumber: j['phoneNumber']?.toString(),
        logoUrl: j['logoUrl']?.toString(),
      );
}

class LocationDetailsDto {
  final String? id;
  final String? addressLine1;
  final String? addressLine2;
  final String? district;
  final String? city;
  final String? countryIso2;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final bool? active;

  LocationDetailsDto({
    this.id,
    this.addressLine1,
    this.addressLine2,
    this.district,
    this.city,
    this.countryIso2,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.active,
  });

  factory LocationDetailsDto.fromJson(Map<String, dynamic> j) =>
      LocationDetailsDto(
        id: j['id']?.toString(),
        addressLine1: j['addressLine1']?.toString(),
        addressLine2: j['addressLine2']?.toString(),
        district: j['district']?.toString(),
        city: j['city']?.toString(),
        countryIso2: j['countryIso2']?.toString(),
        postalCode: j['postalCode']?.toString(),
        latitude:
            (j['latitude'] is num) ? (j['latitude'] as num).toDouble() : null,
        longitude:
            (j['longitude'] is num) ? (j['longitude'] as num).toDouble() : null,
        active: j['active'] as bool?,
      );
}

class ProviderOwnerApi {
  final Dio _dio = ApiService.client;

  /// Read a rich provider details dto
  /// GET /api/providers/public/{id}/details
  Future<ProviderDetailsDto> getDetails(String providerId) async {
    final r = await _dio.get('/providers/public/$providerId/details');
    final data = (r.data as Map).cast<String, dynamic>();
    return ProviderDetailsDto(
      id: data['id'].toString(),
      name: (data['name'] ?? '').toString(),
      description: data['description']?.toString(),
      category: (data['category'] ?? '').toString(),
      email: data['email']?.toString(),
      phoneNumber: data['phoneNumber']?.toString(),
      logoUrl: data['logoUrl']?.toString(),
    );
  }

  /// PUT /api/providers/{id}
  Future<void> updateProvider({
    required String providerId,
    required String name,
    required String description,
    required String category,
    required String email,
    required String phoneNumber,
  }) async {
    final body = {
      'name': name,
      'description': description,
      'category': category,
      'email': email,
      'phoneNumber': phoneNumber,
    };
    await _dio.put('/providers/$providerId', data: body);
  }

  /// PUT /api/providers/{providerId}/logo { "url": "..." }
  Future<void> setLogo({
    required String providerId,
    required String url,
  }) async {
    await _dio.put('/providers/$providerId/logo', data: {'url': url});
  }

  /// GET /api/providers/admin/{providerId}/location -> full details incl. lat/lng
  Future<LocationDetailsDto?> getLocationDetails(String providerId) async {
    try {
      final r = await _dio.get('/providers/admin/$providerId/location');
      return LocationDetailsDto.fromJson(
          (r.data as Map).cast<String, dynamic>());
    } catch (_) {
      // If not set yet, server may 404 -> return null to show empty form
      return null;
    }
  }

  /// PUT /api/providers/{providerId}/location
  Future<void> updateLocation({
    required String providerId,
    String? addressLine1,
    String? addressLine2,
    String? district,
    String? city,
    String? countryIso2,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? provider, // external geocoder provider name if you have
    String? providerPlaceId, // external place id if you have
  }) async {
    final body = {
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'district': district,
      'city': city,
      'countryIso2': (countryIso2 ?? 'UZ').toUpperCase(),
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'provider': provider,
      'providerPlaceId': providerPlaceId,
    }..removeWhere((_, v) => v == null);

    await _dio.put('/providers/$providerId/location', data: body);
  }
}
