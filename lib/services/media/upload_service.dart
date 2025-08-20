// lib/services/upload_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';

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

  Future<String> uploadUserAvatar({
    required String userId,
    required String filePath,
  }) async {
    final fileName = filePath.split('/').last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final res = await _dio.post(
      '/uploads',
      queryParameters: {'scope': 'user', 'ownerId': userId},
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    final url = (res.data['url'] ?? res.data['path'])?.toString();
    return ApiService.normalizeMediaUrl(url) ?? url!;
  }

  Future<String> uploadServiceCover({
    required String providerId,
    String? serviceId,
    required String filePath,
  }) async {
    // Use a generic uploads endpoint you already have.
    // If you already use something like /api/uploads/service/{serviceId},
    // switch URL accordingly. Here’s a tolerant variant:
    final fileName = filePath.split(Platform.pathSeparator).last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'providerId': providerId,
      if (serviceId != null) 'serviceId': serviceId,
    });

    // pick the correct path for your backend:
    // 1) a dedicated service-upload endpoint (preferred)
    // final r = await _dio.post('/uploads/service', data: form);

    // 2) or a generic file upload returning a public URL
    final r = await _dio.post('/uploads', data: form);

    // Expect backend returns {"url": "http://..."}
    final url = (r.data is Map) ? (r.data['url']?.toString() ?? '') : '';
    if (url.isEmpty) {
      throw Exception('Upload failed: empty URL');
    }
    return url;
  }

  Future<String> uploadServiceDraft({
    required String providerId,
    required String filePath,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split(Platform.pathSeparator).last,
      ),
    });

    final res = await _dio.post(
      '/uploads',
      data: form,
      queryParameters: {'scope': 'service', 'ownerId': providerId},
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = (res.data as Map).cast<String, dynamic>();
    final raw =
        (data['publicUrl'] ?? data['url'] ?? data['path'] ?? '').toString();
    if (raw.isEmpty) throw Exception('Upload failed: empty URL');
    return ApiService.normalizeMediaUrl(raw) ?? raw;
  }

  // EDIT flow: store under service folder
  Future<String> uploadServiceImage({
    required String serviceId,
    required String filePath,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split(Platform.pathSeparator).last,
      ),
    });

    final res = await _dio.post(
      '/uploads',
      data: form,
      queryParameters: {'scope': 'service', 'ownerId': serviceId},
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = (res.data as Map).cast<String, dynamic>();
    final raw =
        (data['publicUrl'] ?? data['url'] ?? data['path'] ?? '').toString();
    if (raw.isEmpty) throw Exception('Upload failed: empty URL');
    return ApiService.normalizeMediaUrl(raw) ?? raw;
  }
}
