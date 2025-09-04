class LocationSummary {
  final String? id;
  final String? addressLine1;
  final String? city;
  final String? countryIso2;

  const LocationSummary(
      {this.id, this.addressLine1, this.city, this.countryIso2});

  String get compact {
    final parts = [addressLine1, city, countryIso2]
        .where((e) => (e ?? '').trim().isNotEmpty);
    return parts.isEmpty ? '' : parts.join(', ');
  }

  factory LocationSummary.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const LocationSummary();
    return LocationSummary(
      id: j['id']?.toString(),
      addressLine1: j['addressLine1'] as String?,
      city: j['city'] as String?,
      countryIso2: j['countryIso2'] as String?,
    );
  }
}

class ProviderItem {
  final String id;
  final String name;
  final String description;
  final double rating;
  final String category;
  final LocationSummary? location;

  ProviderItem({
    required this.id,
    required this.name,
    required this.description,
    required this.rating,
    required this.category,
    required this.location,
  });

  factory ProviderItem.fromJson(Map<String, dynamic> j) {
    return ProviderItem(
      id: j['id'].toString(),
      name: (j['name'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      rating:
          (j['avgRating'] is num) ? (j['avgRating'] as num).toDouble() : 0.0,
      category: (j['category'] ?? '').toString(),
      location: j['location'] == null
          ? null
          : LocationSummary.fromJson(j['location']),
    );
  }
}
