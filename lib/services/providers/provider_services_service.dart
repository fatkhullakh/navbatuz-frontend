// lib/services/providers/provider_services_service.dart
import 'package:dio/dio.dart';
import '../../services/api_service.dart';

class ProviderServiceItem {
  final String id;
  final String name;
  final int durationMinutes;
  ProviderServiceItem(
      {required this.id, required this.name, required this.durationMinutes});

  factory ProviderServiceItem.fromJson(Map<String, dynamic> m) =>
      ProviderServiceItem(
        id: m['id'],
        name: m['name'],
        durationMinutes: (m['duration'] is int)
            ? m['duration']
            : int.tryParse('${m['duration']}') ?? 30,
      );
}

class ProviderServicesService {
  final Dio _dio = ApiService.client;

  Future<List<ProviderServiceItem>> getAllByWorker(String workerId) async {
    final r = await _dio.get('/services/worker/all/$workerId');
    final List data = r.data as List;
    return data
        .map((m) => ProviderServiceItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}
