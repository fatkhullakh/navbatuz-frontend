import 'package:dio/dio.dart';
import '../api_service.dart';
import '../providers/provider_owner_services_service.dart'; // for OwnerServiceItem model

class WorkerServicesService {
  final Dio _dio = ApiService.client;

  Future<List<OwnerServiceItem>> getAllByWorker(String workerId) async {
    final r = await _dio.get('/services/worker/all/$workerId');
    final list = (r.data as List? ?? []);
    return list
        .map((e) =>
            OwnerServiceItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
