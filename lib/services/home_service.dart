import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../models/appointment.dart';
import '../models/provider.dart' as models;

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

  Future<HomeData> loadAll() async {
    // Make each call safe so one failure doesn't nuke the whole screen
    final catsF = _loadCategories().catchError((_) => <CategoryItem>[]);
    final upF = _loadUpcomingFromList().catchError((_) => null);
    final favIdsF = _loadFavouriteIds().catchError((_) => <String>[]);
    final providersF =
        _loadProvidersPage().catchError((_) => <models.ProviderItem>[]);

    final results = await Future.wait([catsF, upF, favIdsF, providersF]);

    final categories = results[0] as List<CategoryItem>;
    final upcoming = results[1] as AppointmentItem?;
    final favIds = (results[2] as List).map((e) => e.toString()).toSet();
    final providers = results[3] as List<models.ProviderItem>;

    final favorites = providers.where((p) => favIds.contains(p.id)).toList();
    final recommended =
        providers.where((p) => !favIds.contains(p.id)).take(10).toList();

    return HomeData(
      categories: categories,
      upcomingAppointment: upcoming,
      favoriteShops: favorites,
      recommendedShops: recommended,
    );
  }

  // ---------- helpers ----------

  // BACKEND: ProviderController @GetMapping("/api/providers")
  // returns [{id,name}] list from enum values
  Future<List<CategoryItem>> _loadCategories() async {
    final r = await _dio.get('/providers'); // << moved from /categories
    final data = r.data;
    if (data is List) {
      return data
          .cast<Map<String, dynamic>>()
          .map(CategoryItem.fromJson)
          .toList();
    }
    return const <CategoryItem>[];
  }

  Future<AppointmentItem?> _loadUpcomingFromList() async {
    final r =
        await _dio.get('/appointments/me', queryParameters: {'onlyNext': true});
    final data = r.data;
    final list = <AppointmentItem>[];

    if (data is List) {
      for (final it in data) {
        if (it is Map)
          list.add(AppointmentItem.fromJson(it.cast<String, dynamic>()));
      }
    } else if (data is Map) {
      list.add(AppointmentItem.fromJson(data.cast<String, dynamic>()));
    }

    final now = DateTime.now();
    list.removeWhere((a) {
      final s = a.status.toUpperCase();
      return !(s == 'BOOKED' || s == 'CONFIRMED') || !a.start.isAfter(now);
    });
    list.sort((a, b) => a.start.compareTo(b.start));
    return list.isNotEmpty ? list.first : null;
  }

  Future<List<String>> _loadFavouriteIds() async {
    final r = await _dio.get('/customers/favourites');
    final data = r.data;
    if (data is List) return data.map((e) => e.toString()).toList();
    return const <String>[];
  }

  Future<List<models.ProviderItem>> _loadProvidersPage() async {
    // Paged response: { content: [ {id, name, ..., location: {...}|null } ], ... }
    final r = await _dio.get(
      '/providers/public/all',
      queryParameters: {'page': 0, 'size': 50, 'sortBy': 'name'},
      options: Options(
          responseType: ResponseType.plain), // defensive against text/plain
    );
    dynamic body = r.data;
    if (body is String) body = jsonDecode(body);
    if (body is Map && body['content'] is List) {
      final list = (body['content'] as List).cast<Map<String, dynamic>>();
      return list.map(models.ProviderItem.fromJson).toList();
    }
    return const <models.ProviderItem>[];
  }
}
