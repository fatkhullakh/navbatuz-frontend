import 'package:dio/dio.dart';
import 'api_service.dart';

class Me {
  final String id;
  Me(this.id);

  factory Me.fromJson(Map<String, dynamic> j) => Me((j['id'] ?? '').toString());
}

class ProfileService {
  final Dio _dio = ApiService.client;

  Future<Me> getMe({bool force = false}) async {
    final r = await _dio.get(
      '/users/me',
      queryParameters:
          force ? {'_': DateTime.now().millisecondsSinceEpoch} : null,
      options: Options(headers: {'Cache-Control': 'no-cache'}),
    );
    return Me.fromJson(r.data as Map<String, dynamic>);
  }
}
