import 'location.dart';

class ProviderItem {
  final String name;
  final String description;
  final double avgRating;
  final Location? location;

  ProviderItem({
    required this.name,
    required this.description,
    required this.avgRating,
    this.location,
  });

  factory ProviderItem.fromJson(Map<String, dynamic> json) {
    return ProviderItem(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
    );
  }
}
