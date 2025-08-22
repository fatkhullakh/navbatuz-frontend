import 'package:dio/dio.dart';

class ProviderDetailsDto {
  final String? name, description, category, email, phoneNumber, logoUrl;
  ProviderDetailsDto({
    this.name,
    this.description,
    this.category,
    this.email,
    this.phoneNumber,
    this.logoUrl,
  });

  factory ProviderDetailsDto.fromJson(Map<String, dynamic> j) =>
      ProviderDetailsDto(
        name: j['name']?.toString(),
        description: j['description']?.toString(),
        category: j['category']?.toString(),
        email: j['email']?.toString(),
        phoneNumber: j['phoneNumber']?.toString(),
        logoUrl: j['logoUrl']?.toString(),
      );
}

class ProviderOwnerService {
  final Dio _dio;
  ProviderOwnerService(this._dio);

  Future<ProviderDetailsDto> getDetails(String providerId) async {
    final r = await _dio.get('/providers/public/$providerId/details');
    return ProviderDetailsDto.fromJson((r.data as Map).cast<String, dynamic>());
    // If that endpoint returns more than you need, adapt mapping.
  }

  Future<void> updateProvider(
      {required String id, required Map<String, dynamic> body}) async {
    await _dio.put('/providers/$id', data: body);
  }

  Future<void> updateLocation(
      {required String providerId, required Map<String, dynamic> body}) async {
    await _dio.put('/providers/$providerId/location', data: body);
  }
}
