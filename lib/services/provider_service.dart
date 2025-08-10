import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/provider.dart';

class ProviderService {
  final Dio _dio = DioClient.build();

  Future<PageResponse<ProviderItem>> getProviders({
    int page = 0,
    int size = 10,
    String sortBy = 'name',
  }) async {
    final res = await _dio.get(
      // FIXED PATH:
      '/providers/public/all',
      queryParameters: {'page': page, 'size': size, 'sortBy': sortBy},
    );
    return PageResponse.fromJson(
      res.data as Map<String, dynamic>,
      (json) => ProviderItem.fromJson(json),
    );
  }
}
