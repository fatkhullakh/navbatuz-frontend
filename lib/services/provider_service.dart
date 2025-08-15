// lib/services/provider_service.dart
import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/provider.dart';

class PageResponse<T> {
  final List<T> content;
  final bool last;
  PageResponse({required this.content, required this.last});

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final list = (json['content'] as List).cast<Map<String, dynamic>>();
    return PageResponse<T>(
      content: list.map(fromJsonT).toList(),
      last: json['last'] as bool? ?? true,
    );
  }
}

class ProviderService {
  final Dio _dio = DioClient.build();

  Future<PageResponse<ProviderItem>> getProviders({
    int page = 0,
    int size = 10,
    String sortBy = 'name',
  }) async {
    final res = await _dio.get(
      '/providers/public/all',
      queryParameters: {'page': page, 'size': size, 'sortBy': sortBy},
    );
    return PageResponse.fromJson(
      res.data as Map<String, dynamic>,
      (json) => ProviderItem.fromJson(json),
    );
  }
}
