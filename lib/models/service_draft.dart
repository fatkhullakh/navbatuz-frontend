// lib/models/service_draft.dart
enum ServiceCategory {
  BARBERSHOP,
  DENTAL,
  CLINIC,
  SPA,
  GYM,
  NAIL_SALON,
  BEAUTY_CLINIC,
  BEAUTY_SALON,
  TATTOO_STUDIO,
  MASSAGE_CENTER,
  PHYSIOTHERAPY_CLINIC,
  MAKEUP_STUDIO,
  OTHER,
}

class ServiceDraft {
  String name;
  int durationMinutes;
  double? price; // UZS
  ServiceCategory category;
  String? description; // optional

  ServiceDraft({
    required this.name,
    required this.durationMinutes,
    this.price,
    this.category = ServiceCategory.OTHER,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'durationMinutes': durationMinutes,
        'price': price,
        'category': category.name,
        'description': description,
      }..removeWhere((_, v) => v == null);

  factory ServiceDraft.fromJson(Map<String, dynamic> json) {
    final catName = (json['category'] as String?) ?? 'OTHER';
    ServiceCategory cat;
    try {
      cat = ServiceCategory.values.firstWhere(
        (e) => e.name == catName,
        orElse: () => ServiceCategory.OTHER,
      );
    } catch (_) {
      cat = ServiceCategory.OTHER;
    }
    return ServiceDraft(
      name: (json['name'] ?? '').toString(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
      price: (json['price'] as num?)?.toDouble(),
      category: cat,
      description: json['description'] as String?,
    );
  }

  get imageUrl => null;
}
