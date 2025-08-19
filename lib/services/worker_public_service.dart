// lib/services/worker_public_service.dart
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'service_catalog_service.dart';
import 'provider_public_service.dart';

class WorkerDetails {
  final String id;
  final String name; // "Name Surname" prepared
  final String? avatarUrl;
  final String? phone;
  final String? email;
  final String providerId;
  final String providerName;
  final List<ServiceSummary> services;

  WorkerDetails({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.phone,
    required this.email,
    required this.providerId,
    required this.providerName,
    required this.services,
  });
}

class WorkerPublicService {
  final Dio _dio = ApiService.client;

  Future<WorkerDetails> getDetails({
    required String workerId,
    required String providerId, // we pass it from callers when we know it
  }) async {
    Map<String, dynamic>? j;

    // 1) Try a rich public endpoint, if you have it
    try {
      final r = await _dio.get('/workers/public/$workerId/details');
      if (r.data is Map) j = Map<String, dynamic>.from(r.data as Map);
    } catch (_) {}

    // 2) Try a simpler public worker endpoint
    if (j == null) {
      try {
        final r = await _dio.get('/workers/public/$workerId');
        if (r.data is Map) j = Map<String, dynamic>.from(r.data as Map);
      } catch (_) {}
    }

    // 3) Fallback compose from provider details
    final providerSvc = ProviderPublicService();
    final prov = await providerSvc.getDetails(providerId);
    final w = prov.workers.firstWhere((w) => w.id == workerId);

    final String fullName =
        (w.name ?? '').trim().isEmpty ? 'Worker' : w.name!.trim();

    String? avatar;
    String? email;
    String? phone;

    if (j != null) {
      avatar = ApiService.normalizeMediaUrl(j['avatarUrl']?.toString());
      email = j['email']?.toString();
      phone = j['phone']?.toString();
    }

    // Services the worker provides
    List<ServiceSummary> services = [];
    try {
      // Prefer a direct endpoint if it exists:
      final r = await _dio.get('/services/public/worker/$workerId/services');
      if (r.data is List) {
        services = (r.data as List)
            .whereType<Map>()
            .map((m) => ServiceSummary.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}

    if (services.isEmpty) {
      // Fallback: list provider services, keep those that include this worker
      final sc = ServiceCatalogService();
      final byProv = await sc.byProvider(providerId);
      // If your summary doesn’t include workerIds, resolve only a few details:
      final futures = byProv.map((s) async {
        try {
          final d = await sc.details(serviceId: s.id, providerId: providerId);
          return d.workerIds.contains(workerId) ? s : null;
        } catch (_) {
          return null;
        }
      });
      final resolved = await Future.wait(futures);
      services = resolved.whereType<ServiceSummary>().toList();
    }

    return WorkerDetails(
      id: workerId,
      name: fullName.isEmpty ? (j?['name']?.toString() ?? 'Worker') : fullName,
      avatarUrl: avatar,
      phone: phone,
      email: email,
      providerId: prov.id,
      providerName: prov.name,
      services: services,
    );
  }
}
