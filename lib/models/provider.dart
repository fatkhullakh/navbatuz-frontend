class ProviderLocation {
  final String? addressLine1;
  final String? city;
  final String? countryIso2;

  const ProviderLocation({this.addressLine1, this.city, this.countryIso2});

  factory ProviderLocation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProviderLocation();
    return ProviderLocation(
      addressLine1: json['addressLine1'] as String?,
      city: json['city'] as String?,
      countryIso2: json['countryIso2'] as String?,
    );
  }

  String get compact {
    final parts = <String>[
      if ((addressLine1 ?? '').trim().isNotEmpty) addressLine1!.trim(),
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
      if ((countryIso2 ?? '').trim().isNotEmpty) countryIso2!.trim(),
    ];
    return parts.join(', ');
  }
}

class ProviderItem {
  final String id;
  final String name;
  final String? description;
  final double rating;
  final String category;
  final ProviderLocation location;
  final String? imageUrl;

  ProviderItem({
    required this.id,
    required this.name,
    this.description,
    required this.rating,
    required this.category,
    required this.location,
    this.imageUrl,
  });

  factory ProviderItem.fromJson(Map<String, dynamic> j) => ProviderItem(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: j['description'] as String?,
        rating: (j['avgRating'] as num?)?.toDouble() ?? 0.0,
        category: (j['category'] ?? '').toString(),
        // new backend shape: nested `location` OR null
        location: ProviderLocation.fromJson(
          j['location'] as Map<String, dynamic>?,
        ),
        imageUrl: j['imageUrl'] as String?,
      );
}

// If you don’t already have it elsewhere:
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
