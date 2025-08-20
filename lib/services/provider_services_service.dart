import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/provider_service.dart';

class ProviderServicesService {
  final Dio _dio = ApiService.client;

  Future<List<ProviderService>> listByProvider(String providerId) async {
    final r = await _dio.get('/services/provider/all/$providerId');
    final list = (r.data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((m) => ProviderService.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<ProviderService> create(CreateServicePayload body) async {
    final r = await _dio.post('/services', data: body.toJson());
    return ProviderService.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<void> update(String serviceId, ProviderService service) async {
    await _dio.put('/services/$serviceId', data: service.toUpdateJson());
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

  Future<void> setImage(String serviceId, String url) async {
    await _dio.put('/services/$serviceId/image', data: {'url': url});
  }
}
