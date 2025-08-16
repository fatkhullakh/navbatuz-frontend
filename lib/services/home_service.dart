// lib/services/home_service.dart
import 'package:dio/dio.dart';
import 'api_service.dart';

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
  ProviderItem({
    required this.id,
    required this.name,
    required this.description,
    required this.rating,
    required this.category,
    required this.location,
  });
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

  get date => null;

  get startTime => null;
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
  static const _prefix = ''; // see note in ProfileService

  Future<HomeData> loadAll() async {
    final results = await Future.wait([
      _dio.get('$_prefix/providers'), // categories
      _dio.get('$_prefix/appointments/me', queryParameters: {'onlyNext': true}),
      _dio.get('$_prefix/customers/favourites'),
      _dio.get('$_prefix/providers/public/all',
          queryParameters: {'page': 0, 'size': 50, 'sortBy': 'name'}),
    ]);

    // Categories
    final catsRaw = results[0].data;
    final categories = (catsRaw is List)
        ? catsRaw
            .map((e) =>
                CategoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <CategoryItem>[];

    // Upcoming (pick the earliest future BOOKED/CONFIRMED)
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
          if (upcoming == null || cand.start.isBefore(upcoming!.start)) {
            upcoming = cand;
          }
        }
      }
    }

    // Favourites: list of provider IDs
    final favIds = <String>{};
    final favRaw = results[2].data;
    if (favRaw is List) {
      for (final e in favRaw) {
        favIds.add(e.toString());
      }
    }

    // Providers (page content)
    final provRaw = results[3].data;
    final content = (provRaw is Map && provRaw['content'] is List)
        ? (provRaw['content'] as List)
        : const <dynamic>[];

    final providers = content.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      ProviderLocation? loc;
      final locRaw = m['location'];
      if (locRaw is Map) {
        loc = ProviderLocation.fromJson(Map<String, dynamic>.from(locRaw));
      }
      return ProviderItem(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        description: (m['description'] ?? '').toString(),
        rating:
            (m['avgRating'] is num) ? (m['avgRating'] as num).toDouble() : 0.0,
        category: (m['category'] ?? '').toString(),
        location: loc,
      );
    }).toList();

    final favorites = providers.where((p) => favIds.contains(p.id)).toList();
    final recommended = providers; // naive

    return HomeData(
      categories: categories,
      upcomingAppointment: upcoming,
      favoriteShops: favorites,
      recommendedShops: recommended,
    );
  }
}
