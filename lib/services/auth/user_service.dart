import 'package:dio/dio.dart';
import '../../core/dio_client.dart';

class UserService {
  final Dio _dio = DioClient.build();

  Future<String> getMyUserId() async {
    final res = await _dio.get('/users/me');
    // adjust if your field is different:
    return (res.data['id'] as String);
  }
}
