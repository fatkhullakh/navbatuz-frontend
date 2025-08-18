// lib/services/upload_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class UploadResult {
  final String url;
  final String path;
  final String contentType;
  final int size;
  UploadResult({
    required this.url,
    required this.path,
    required this.contentType,
    required this.size,
  });
  factory UploadResult.fromJson(Map<String, dynamic> j) => UploadResult(
        url: (j['url'] ?? '').toString(),
        path: (j['path'] ?? '').toString(),
        contentType: (j['contentType'] ?? '').toString(),
        size: (j['size'] is num) ? (j['size'] as num).toInt() : 0,
      );
}

enum UploadScope { provider, user, service }

extension _S on UploadScope {
  String get text => switch (this) {
        UploadScope.provider => 'provider',
        UploadScope.user => 'user',
        UploadScope.service => 'service',
      };
}

class UploadService {
  final Dio _dio = ApiService.client;
  final _picker = ImagePicker();

  /// Lets user pick an image (gallery/camera), uploads to /api/uploads,
  /// returns UploadResult (with public URL).
  Future<UploadResult?> pickAndUpload({
    required UploadScope scope,
    required String ownerId,
    bool useCamera = false,
    void Function(int sent, int total)? onProgress,
  }) async {
    final XFile? x = await _picker.pickImage(
        source: useCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 92);
    if (x == null) return null;

    final file = File(x.path);
    final name = x.name; // keeps original file name where possible

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: name),
    });

    final r = await _dio.post(
      '/uploads',
      queryParameters: {'scope': scope.text, 'ownerId': ownerId},
      data: form,
      onSendProgress: onProgress,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
    return UploadResult.fromJson((r.data as Map).cast<String, dynamic>());
  }
}
