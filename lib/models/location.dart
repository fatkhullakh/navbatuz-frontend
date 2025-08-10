class Location {
  final String? id;
  final String? address;
  final String? district;
  final String? city;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  Location({
    this.id,
    this.address,
    this.district,
    this.city,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      address: json['address'],
      district: json['district'],
      city: json['city'],
      country: json['country'],
      postalCode: json['postalCode'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
