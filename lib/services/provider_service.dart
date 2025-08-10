import 'package:dio/dio.dart';
import '../models/page_response.dart';
import '../models/provider.dart';
import 'api_service.dart';

class ProviderService {
  final Dio _dio = ApiService.client;

  Future<PageResponse<ProviderItem>> getProviders({
    int page = 0,
    int size = 10,
    String sortBy = 'name',
  }) async {
    final res = await _dio.get(
      '/providers/public/all',
      queryParameters: {
        'page': page,
        'size': size,
        'sortBy': sortBy,
      },
    );

    return PageResponse<ProviderItem>.fromJson(
      res.data as Map<String, dynamic>,
      (json) => ProviderItem.fromJson(json),
    );
  }
}
