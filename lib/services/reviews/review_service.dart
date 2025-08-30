// lib/services/reviews/review_service.dart
import 'package:dio/dio.dart';
import '../api_service.dart';

class ReviewService {
  final Dio _dio = ApiService.client;

  Future<void> create({
    required String appointmentId,
    required int rating, // 1..5
    String? comment,
  }) async {
    await _dio.post('/reviews', data: {
      'appointmentId': appointmentId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<Map<String, dynamic>> getProviderSummary(String providerId) async {
    final r = await _dio.get('/reviews/provider/$providerId/summary');
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<List<Map<String, dynamic>>> listByProvider(String providerId,
      {int page = 0, int size = 20}) async {
    final r = await _dio.get('/reviews/provider/$providerId',
        queryParameters: {'page': page, 'size': size});
    return ((r.data as List?) ?? [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listByWorker(String workerId,
      {int page = 0, int size = 20}) async {
    final r = await _dio.get('/reviews/worker/$workerId',
        queryParameters: {'page': page, 'size': size});
    return ((r.data as List?) ?? [])
        .cast<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
