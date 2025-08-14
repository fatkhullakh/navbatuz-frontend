// lib/services/home_service.dart
import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/appointment.dart';
import '../models/provider.dart' as models;
import 'appointment_service.dart';

class HomeData {
  final List<CategoryItem> categories;
  final AppointmentItem? upcomingAppointment;
  final List<models.ProviderItem> favoriteShops;
  final List<models.ProviderItem> recommendedShops;

  HomeData({
    required this.categories,
    required this.upcomingAppointment,
    required this.favoriteShops,
    required this.recommendedShops,
  });
}

class CategoryItem {
  final String id;
  final String name;
  CategoryItem({required this.id, required this.name});
  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? 'Unknown').toString());
}

class HomeService {
  final Dio _dio = DioClient.build();
  final AppointmentService _appt = AppointmentService();

  Future<HomeData> loadAll() async {
    final catsF = _loadCategories();
    final upF = _appt.nextUpcoming(); // needs JWT
    final recF = _loadRecommended(); // public
    final favF = _loadFavorites(); // needs JWT

    final categories = await catsF;
    final upcoming = await upF;
    final recommended = await recF;
    final favorites = await favF;

    return HomeData(
      categories: categories,
      upcomingAppointment: upcoming,
      favoriteShops: favorites,
      recommendedShops: recommended,
    );
  }

  Future<List<CategoryItem>> _loadCategories() async {
    try {
      final r = await _dio.get('/categories');
      final d = r.data;
      if (d is List) {
        final list =
            d.cast<Map<String, dynamic>>().map(CategoryItem.fromJson).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    // fallback so UI isn’t blank while backend catches up
    return [
      CategoryItem(id: 'BARBERSHOP', name: 'Barbershop'),
      CategoryItem(id: 'DENTAL', name: 'Dental'),
      CategoryItem(id: 'SPA', name: 'Spa'),
      CategoryItem(id: 'CLINIC', name: 'Clinic'),
    ];
  }

  Future<AppointmentItem?> _loadUpcoming() async {
    try {
      final r = await _dio
          .get('/appointments/me', queryParameters: {'onlyNext': true});
      final d = r.data;
      if (d is Map) return AppointmentItem.fromJson(d.cast<String, dynamic>());
    } catch (_) {}
    return null;
  }

  Future<List<models.ProviderItem>> _loadRecommended() async {
    try {
      final r = await _dio.get('/providers/public/all',
          queryParameters: {'page': 0, 'size': 20, 'sortBy': 'name'});
      final d = r.data;
      final list = (d is Map && d['content'] is List)
          ? d['content'] as List
          : (d is List ? d : const []);
      return list.cast<Map<String, dynamic>>().map(_toProvider).toList();
    } catch (_) {
      return const <models.ProviderItem>[];
    }
  }

  Future<List<models.ProviderItem>> _loadFavorites() async {
    try {
      final favIdsRes = await _dio.get('/customers/favourites'); // List<UUID>
      final ids = ((favIdsRes.data as List?) ?? const [])
          .map((e) => e.toString())
          .toSet();
      if (ids.isEmpty) return const <models.ProviderItem>[];
      final all = await _loadRecommended();
      return all.where((p) => ids.contains(p.id)).toList();
    } catch (_) {
      return const <models.ProviderItem>[];
    }
  }

  models.ProviderItem _toProvider(Map<String, dynamic> j) {
    return models.ProviderItem(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? 'Unnamed').toString(),
      description: j['description'] as String?,
      rating: (j['avgRating'] as num?)?.toDouble() ?? 0.0,
      category: (j['category'] ?? j['categoryName'] ?? '').toString(),
      location: models.ProviderLocation.fromJson(
          j['location'] as Map<String, dynamic>?),
    );
  }
}
