import 'package:dio/dio.dart';
import '../api_service.dart';

class WorkerDetails {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final String? email;
  final String? providerId;
  final bool isActive;

  WorkerDetails({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.phone,
    this.email,
    this.providerId,
    required this.isActive,
  });

  factory WorkerDetails.fromJson(Map<String, dynamic> j) {
    String? _providerId() {
      final p = j['provider'];
      if (p is Map && p['id'] != null) return p['id'].toString();
      if (j['providerId'] != null) return j['providerId'].toString();
      return null;
    }

    String _name() {
      if (j['name'] != null) return j['name'].toString();
      if (j['displayName'] != null) return j['displayName'].toString();
      final fn = (j['firstName'] ?? '').toString();
      final ln = (j['lastName'] ?? '').toString();
      final s = ('$fn $ln').trim();
      return s.isEmpty ? 'Worker' : s;
    }

    return WorkerDetails(
      id: (j['id'] ?? j['workerId'] ?? '').toString(),
      name: _name(),
      avatarUrl: (j['avatarUrl'] ?? j['photoUrl'])?.toString(),
      phone: (j['phoneNumber'] ?? j['phone'])?.toString(),
      email: j['email']?.toString(),
      providerId: _providerId(),
      isActive: (j['isActive'] as bool?) ??
          (j['active'] as bool?) ??
          true, // default true
    );
  }
}

class WorkerMe {
  final String id;
  WorkerMe(this.id);
}

class WorkersApi {
  final Dio _dio = ApiService.client;

  // Future<WorkerDetails> me() async {
  //   final r = await _dio.get('/workers/me');
  //   return WorkerDetails.fromJson(Map<String, dynamic>.from(r.data as Map));
  // }

  Future<WorkerMe> me() async {
    final r = await _dio.get('/workers/me');
    final id = r.data?['id'] as String;
    return WorkerMe(id);
  }

  Future<WorkerDetails> byId(String id) async {
    final r = await _dio.get('/workers/$id');
    return WorkerDetails.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
