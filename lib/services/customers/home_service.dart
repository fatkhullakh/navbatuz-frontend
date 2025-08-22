import 'package:dio/dio.dart';
import '../api_service.dart';

class CategoryItem {
  final String id; // e.g. "CLINIC"
  final String name; // display name
  CategoryItem({required this.id, required this.name});
  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
      id: (j['id'] ?? '').toString(), name: (j['name'] ?? '').toString());
}

class ProviderLocation {
  final String? addressLine1;
  final String? city;
  final String? countryIso2;
  ProviderLocation({this.addressLine1, this.city, this.countryIso2});

  factory ProviderLocation.fromJson(Map<String, dynamic> j) => ProviderLocation(
        addressLine1: j['addressLine1'] as String?,
        city: j['city'] as String?,
        countryIso2: j['countryIso2'] as String?,
      );

  String get compact {
    final parts = <String>[];
    if ((addressLine1 ?? '').trim().isNotEmpty) parts.add(addressLine1!.trim());
    if ((city ?? '').trim().isNotEmpty) parts.add(city!.trim());
    if ((countryIso2 ?? '').trim().isNotEmpty) parts.add(countryIso2!.trim());
    return parts.join(', ');
  }
}

class ProviderItem {
  final String id;
  final String name;
  final String description;
  final double rating;
  final String category;
  final ProviderLocation? location;
  final String? logoUrl; // <-- NEW

  ProviderItem({
    required this.id,
    required this.name,
    required this.description,
    required this.rating,
    required this.category,
    required this.location,
    this.logoUrl,
  });

  factory ProviderItem.fromJson(Map<String, dynamic> m) {
    ProviderLocation? loc;
    final raw = m['location'];
    if (raw is Map) {
      loc = ProviderLocation.fromJson(Map<String, dynamic>.from(raw));
    }
    final rawLogo = m['logoUrl']?.toString();
    return ProviderItem(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      rating:
          (m['avgRating'] is num) ? (m['avgRating'] as num).toDouble() : 0.0,
      category: (m['category'] ?? '').toString(),
      location: loc,
      logoUrl: ApiService.normalizeMediaUrl(rawLogo),
    );
  }
}

class HomeAppointment {
  final String id;
  final String serviceName;
  final String providerName;
  final DateTime start;
  HomeAppointment({
    required this.id,
    required this.serviceName,
    required this.providerName,
    required this.start,
  });

  Null get date => null;
  Null get startTime => null;
}

class HomeData {
  final List<CategoryItem> categories;
  final HomeAppointment? upcomingAppointment;
  final List<ProviderItem> favoriteShops;
  final List<ProviderItem> recommendedShops;
  HomeData({
    required this.categories,
    required this.upcomingAppointment,
    required this.favoriteShops,
    required this.recommendedShops,
  });
}

class HomeService {
  final Dio _dio = ApiService.client;

  Future<HomeData> loadAll() async {
    final results = await Future.wait([
      _dio.get('/providers'), // categories
      _dio.get('/appointments/me', queryParameters: {'onlyNext': true}),
      _dio.get('/customers/favourites'), // favorites
      _dio.get('/providers/public/all',
          queryParameters: {'page': 0, 'size': 50, 'sortBy': 'name'}),
    ]);

    // ---------- Categories ----------
    final catsRaw = results[0].data;
    final categories = (catsRaw is List)
        ? catsRaw
            .whereType<Map>()
            .map((e) =>
                CategoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <CategoryItem>[];

    // ---------- Upcoming appointment ----------
    final apptsRaw = results[1].data;
    HomeAppointment? upcoming;
    final now = DateTime.now();
    if (apptsRaw is List) {
      for (final it in apptsRaw) {
        final m = Map<String, dynamic>.from(it as Map);
        final date = (m['date'] ?? '').toString(); // yyyy-MM-dd
        final startTime = (m['startTime'] ?? '').toString(); // HH:mm:ss
        DateTime? start;
        try {
          start = DateTime.parse('${date}T$startTime');
        } catch (_) {}
        if (start == null) continue;

        final status = (m['status'] ?? '').toString().toUpperCase();
        if ((status == 'BOOKED' || status == 'CONFIRMED') &&
            start.isAfter(now)) {
          final cand = HomeAppointment(
            id: (m['id'] ?? '').toString(),
            serviceName: (m['serviceName'] ?? '').toString(),
            providerName: (m['providerName'] ?? '').toString(),
            start: start,
          );
          if (upcoming == null || cand.start.isBefore(upcoming.start)) {
            upcoming = cand;
          }
        }
      }
    }

    // ---------- Providers page (recommended/fallback) ----------
    final provRaw = results[3].data;
    final content = (provRaw is Map && provRaw['content'] is List)
        ? (provRaw['content'] as List)
        : const <dynamic>[];
    final providers = content
        .whereType<Map>()
        .map<ProviderItem>(
            (e) => ProviderItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    // ---------- Favorites ----------
    final favRaw = results[2].data;
    late final List<ProviderItem> favorites;

    if (favRaw is List && favRaw.isNotEmpty && favRaw.first is Map) {
      favorites = favRaw
          .map(
              (e) => ProviderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (favRaw is List) {
      final favIds = favRaw.map((e) => e.toString()).toSet();
      favorites = providers.where((p) => favIds.contains(p.id)).toList();
    } else {
      favorites = <ProviderItem>[];
    }

    final recommended = providers; // simple placeholder

    return HomeData(
      categories: categories,
      upcomingAppointment: upcoming,
      favoriteShops: favorites,
      recommendedShops: recommended,
    );
  }
}
