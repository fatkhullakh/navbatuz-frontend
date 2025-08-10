class ProviderLocation {
  final String? city;
  final String? district;
  ProviderLocation({this.city, this.district});

  factory ProviderLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ProviderLocation();
    return ProviderLocation(
      city: json['city'] as String?,
      district: json['district'] as String?,
    );
  }
}

class ProviderItem {
  final String name;
  final String? description;
  final double rating;
  final ProviderLocation location;

  ProviderItem({
    required this.name,
    this.description,
    required this.rating,
    required this.location,
  });

  factory ProviderItem.fromJson(Map<String, dynamic> json) {
    return ProviderItem(
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      rating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      location:
          ProviderLocation.fromJson(json['location'] as Map<String, dynamic>?),
    );
  }
}

class PageResponse<T> {
  final List<T> content;
  final bool last;
  PageResponse({required this.content, required this.last});

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final list = (json['content'] as List).cast<Map<String, dynamic>>();
    return PageResponse<T>(
      content: list.map(fromJsonT).toList(),
      last: json['last'] as bool? ?? true,
    );
  }
}
