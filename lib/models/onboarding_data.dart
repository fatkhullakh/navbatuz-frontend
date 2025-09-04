import 'service_draft.dart';

/// Central model passed between onboarding screens.
/// Keep values in *stable EN/ISO* form for backend (codes & EN names).
class OnboardingData {
  // ---------- App / user ----------
  /// 'en' | 'ru' | 'uz'
  String? languageCode;

  /// CUSTOMER | OWNER | WORKER
  String? role;

  // ---------- Owner (account to create first) ----------
  String? ownerName;
  String? ownerSurname;
  String? ownerEmail;

  /// Owner phone split (preferred). If absent, fall back to business phone.
  String? ownerPhoneDialCode; // e.g. '+998'
  String? ownerPhoneNumber; // local part without dial code

  /// Plain E.164 owner phone (optional override). Example: '+998901112233'
  String? ownerPhoneE164;

  /// Registration password (required by BE)
  String? ownerPassword;

  /// Optional worker type for "ownerAlsoWorker" flow (e.g. 'BARBER', 'GENERAL')
  String? ownerWorkerType;

  /// Owner date of birth as ISO yyyy-MM-dd (used whether or not owner is a worker).
  String? ownerDateOfBirth;

  /// Owner gender code: 'MALE' | 'FEMALE' | 'OTHER' (backend enum-friendly).
  String? ownerGender;

  // ---------- Residence (user) ----------
  /// Country ISO2 (e.g., 'UZ', 'KZ', 'RU', ...).
  String? countryIso2;

  /// Country name (EN) for readability & display-only persistence.
  String? countryNameEn;

  /// City code (internal stable key, EN/slug) — for user residence.
  String? cityCode;

  /// City name (EN) for readability — for user residence.
  String? cityNameEn;

  /// District code — for user residence.
  String? districtCode;

  /// District name (EN) — for user residence.
  String? districtNameEn;

  /// DEPRECATED: User location pin (legacy). Use providerLat/providerLng for business.
  @Deprecated('Use providerLat/providerLng for provider location')
  double? lat;
  @Deprecated('Use providerLat/providerLng for provider location')
  double? lng;

  // ---------- Provider (business) ----------
  /// Stable provider category code (e.g., 'BARBERSHOP', 'CLINIC', ...).
  String? providerCategoryCode;

  /// Category name (EN) for readability.
  String? providerCategoryNameEn;

  /// Public-facing business info
  String? businessName;
  String? businessDescription;

  /// Contact
  String? businessEmail;

  /// Phone split for reliable formatting
  String? businessPhoneIso2; // e.g., 'UZ'
  String? businessPhoneDialCode; // e.g., '+998'
  String? businessPhoneNumber; // local part without dial code

  /// Provider (business) physical address (structured)
  String? providerCityCode; // slug/key (if you use a catalog)
  String? providerCityNameEn; // EN name for DB readability
  String? providerDistrictCode; // slug/key
  String? providerDistrictNameEn; // EN name for DB readability

  /// Free-text address lines (display)
  String? providerAddressLine1; // required in onboarding
  String? providerAddressLine2; // optional
  String? providerZipCode; // optional

  /// Exact business coordinates (mandatory before continuing)
  double? providerLat;
  double? providerLng;

  /// Team size (optional during onboarding)
  int? teamSize;

  /// Weekly hours. Keys are 'MONDAY'..'SUNDAY'.
  /// Value is "HH:mm-HH:mm" or "CLOSED".
  Map<String, String>? weeklyHours;

  /// Services drafted during onboarding.
  /// (Each ServiceDraft is a local-only draft until submitted.)
  List<ServiceDraft> services;

  // ---------- Owner-as-worker (optional shortcut flow) ----------
  /// If owner is also a worker/staff.
  bool? ownerAlsoWorker;

  /// Owner worker display name.
  String? ownerFullName;

  /// Owner worker contact phone.
  String? ownerWorkerPhone;

  /// Owner worker personal working hours (defaults copied from business weeklyHours).
  Map<String, String>? ownerWorkerWeeklyHours;

  /// Owner worker services (defaults copied from business services) — serialized list items.
  List<Map<String, dynamic>>? ownerWorkerServices;

  OnboardingData({
    this.languageCode,
    this.role,
    // owner
    this.ownerName,
    this.ownerSurname,
    this.ownerEmail,
    this.ownerPhoneDialCode,
    this.ownerPhoneNumber,
    this.ownerPhoneE164,
    this.ownerPassword,
    this.ownerWorkerType,
    this.ownerDateOfBirth,
    this.ownerGender,
    // user residence
    this.countryIso2,
    this.countryNameEn,
    this.cityCode,
    this.cityNameEn,
    this.districtCode,
    this.districtNameEn,
    @Deprecated('Use providerLat/providerLng') this.lat,
    @Deprecated('Use providerLat/providerLng') this.lng,
    // provider category & info
    this.providerCategoryCode,
    this.providerCategoryNameEn,
    this.businessName,
    this.businessDescription,
    this.businessEmail,
    this.businessPhoneIso2,
    this.businessPhoneDialCode,
    this.businessPhoneNumber,
    // provider address
    this.providerCityCode,
    this.providerCityNameEn,
    this.providerDistrictCode,
    this.providerDistrictNameEn,
    this.providerAddressLine1,
    this.providerAddressLine2,
    this.providerZipCode,
    this.providerLat,
    this.providerLng,
    // team/hours/services
    this.teamSize,
    this.weeklyHours,
    List<ServiceDraft>? services,
    // owner-as-worker
    this.ownerAlsoWorker,
    this.ownerFullName,
    this.ownerWorkerPhone,
    this.ownerWorkerWeeklyHours,
    this.ownerWorkerServices,
  }) : services = services ?? <ServiceDraft>[] {
    // Back-compat: if new providerLat/providerLng are missing but legacy lat/lng exist, copy them forward.
    providerLat ??= lat;
    providerLng ??= lng;
  }

  // ---------- Helpers ----------
  void setWeeklyHour(String day,
      {required bool open, String? start, String? end}) {
    weeklyHours ??= <String, String>{};
    if (!open) {
      weeklyHours![day] = 'CLOSED';
      return;
    }
    final s = (start ?? '').trim();
    final e = (end ?? '').trim();
    if (s.isEmpty || e.isEmpty) return;
    weeklyHours![day] = '$s-$e';
  }

  void addService(ServiceDraft draft) => services.add(draft);

  void removeServiceAt(int index) {
    if (index >= 0 && index < services.length) services.removeAt(index);
  }

  // Shallow clone
  OnboardingData copyWith({
    String? languageCode,
    String? role,
    // owner
    String? ownerName,
    String? ownerSurname,
    String? ownerEmail,
    String? ownerPhoneDialCode,
    String? ownerPhoneNumber,
    String? ownerPhoneE164,
    String? ownerPassword,
    String? ownerWorkerType,
    String? ownerDateOfBirth,
    String? ownerGender,
    // user residence
    String? countryIso2,
    String? countryNameEn,
    String? cityCode,
    String? cityNameEn,
    String? districtCode,
    String? districtNameEn,
    double? lat, // deprecated
    double? lng, // deprecated
    // provider
    String? providerCategoryCode,
    String? providerCategoryNameEn,
    String? businessName,
    String? businessDescription,
    String? businessEmail,
    String? businessPhoneIso2,
    String? businessPhoneDialCode,
    String? businessPhoneNumber,
    // provider address
    String? providerCityCode,
    String? providerCityNameEn,
    String? providerDistrictCode,
    String? providerDistrictNameEn,
    String? providerAddressLine1,
    String? providerAddressLine2,
    String? providerZipCode,
    double? providerLat,
    double? providerLng,
    // team/hours/services
    int? teamSize,
    Map<String, String>? weeklyHours,
    List<ServiceDraft>? services,
    // owner-as-worker
    bool? ownerAlsoWorker,
    String? ownerFullName,
    String? ownerWorkerPhone,
    Map<String, String>? ownerWorkerWeeklyHours,
    List<Map<String, dynamic>>? ownerWorkerServices,
  }) {
    final clonedWeekly = weeklyHours ??
        (this.weeklyHours == null
            ? null
            : Map<String, String>.from(this.weeklyHours!));
    final clonedServices = services ?? List<ServiceDraft>.from(this.services);
    final clonedOwnerWeekly = ownerWorkerWeeklyHours ??
        (this.ownerWorkerWeeklyHours == null
            ? null
            : Map<String, String>.from(this.ownerWorkerWeeklyHours!));
    final clonedOwnerServices = ownerWorkerServices ??
        (this.ownerWorkerServices == null
            ? null
            : List<Map<String, dynamic>>.from(this.ownerWorkerServices!));

    final data = OnboardingData(
      languageCode: languageCode ?? this.languageCode,
      role: role ?? this.role,
      // owner
      ownerName: ownerName ?? this.ownerName,
      ownerSurname: ownerSurname ?? this.ownerSurname,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhoneDialCode: ownerPhoneDialCode ?? this.ownerPhoneDialCode,
      ownerPhoneNumber: ownerPhoneNumber ?? this.ownerPhoneNumber,
      ownerPhoneE164: ownerPhoneE164 ?? this.ownerPhoneE164,
      ownerPassword: ownerPassword ?? this.ownerPassword,
      ownerWorkerType: ownerWorkerType ?? this.ownerWorkerType,
      ownerDateOfBirth: ownerDateOfBirth ?? this.ownerDateOfBirth,
      ownerGender: ownerGender ?? this.ownerGender,
      // residence
      countryIso2: countryIso2 ?? this.countryIso2,
      countryNameEn: countryNameEn ?? this.countryNameEn,
      cityCode: cityCode ?? this.cityCode,
      cityNameEn: cityNameEn ?? this.cityNameEn,
      districtCode: districtCode ?? this.districtCode,
      districtNameEn: districtNameEn ?? this.districtNameEn,
      lat: lat ?? this.lat, // deprecated
      lng: lng ?? this.lng, // deprecated
      // provider
      providerCategoryCode: providerCategoryCode ?? this.providerCategoryCode,
      providerCategoryNameEn:
          providerCategoryNameEn ?? this.providerCategoryNameEn,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhoneIso2: businessPhoneIso2 ?? this.businessPhoneIso2,
      businessPhoneDialCode:
          businessPhoneDialCode ?? this.businessPhoneDialCode,
      businessPhoneNumber: businessPhoneNumber ?? this.businessPhoneNumber,
      providerCityCode: providerCityCode ?? this.providerCityCode,
      providerCityNameEn: providerCityNameEn ?? this.providerCityNameEn,
      providerDistrictCode: providerDistrictCode ?? this.providerDistrictCode,
      providerDistrictNameEn:
          providerDistrictNameEn ?? this.providerDistrictNameEn,
      providerAddressLine1: providerAddressLine1 ?? this.providerAddressLine1,
      providerAddressLine2: providerAddressLine2 ?? this.providerAddressLine2,
      providerZipCode: providerZipCode ?? this.providerZipCode,
      providerLat: providerLat ?? this.providerLat,
      providerLng: providerLng ?? this.providerLng,
      teamSize: teamSize ?? this.teamSize,
      weeklyHours: clonedWeekly,
      services: clonedServices,
      // owner-as-worker
      ownerAlsoWorker: ownerAlsoWorker ?? this.ownerAlsoWorker,
      ownerFullName: ownerFullName ?? this.ownerFullName,
      ownerWorkerPhone: ownerWorkerPhone ?? this.ownerWorkerPhone,
      ownerWorkerWeeklyHours: clonedOwnerWeekly,
      ownerWorkerServices: clonedOwnerServices,
    );

    // Keep legacy lat/lng mirrored from provider coords if present
    if (data.providerLat != null && data.providerLng != null) {
      data.lat = data.providerLat;
      data.lng = data.providerLng;
    }

    return data;
  }

  // ---------- Serialization ----------
  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'role': role,

        // owner
        'ownerName': ownerName,
        'ownerSurname': ownerSurname,
        'ownerEmail': ownerEmail,
        'ownerPhoneDialCode': ownerPhoneDialCode,
        'ownerPhoneNumber': ownerPhoneNumber,
        'ownerPhoneE164': ownerPhoneE164,
        'ownerPassword': ownerPassword,
        'ownerWorkerType': ownerWorkerType,
        'ownerDateOfBirth': ownerDateOfBirth,
        'ownerGender': ownerGender,

        // user residence
        'countryIso2': countryIso2,
        'countryNameEn': countryNameEn,
        'cityCode': cityCode,
        'cityNameEn': cityNameEn,
        'districtCode': districtCode,
        'districtNameEn': districtNameEn,

        // legacy coords (kept for compatibility)
        'lat': lat,
        'lng': lng,

        // provider
        'providerCategoryCode': providerCategoryCode,
        'providerCategoryNameEn': providerCategoryNameEn,
        'businessName': businessName,
        'businessDescription': businessDescription,
        'businessEmail': businessEmail,
        'businessPhoneIso2': businessPhoneIso2,
        'businessPhoneDialCode': businessPhoneDialCode,
        'businessPhoneNumber': businessPhoneNumber,

        // provider address (new)
        'providerCityCode': providerCityCode,
        'providerCityNameEn': providerCityNameEn,
        'providerDistrictCode': providerDistrictCode,
        'providerDistrictNameEn': providerDistrictNameEn,
        'providerAddressLine1': providerAddressLine1,
        'providerAddressLine2': providerAddressLine2,
        'providerZipCode': providerZipCode,
        'providerLat': providerLat,
        'providerLng': providerLng,

        // team/hours/services
        'teamSize': teamSize,
        'weeklyHours': weeklyHours,
        'services': services.map((e) => e.toJson()).toList(),

        // owner-as-worker
        'ownerAlsoWorker': ownerAlsoWorker,
        'ownerFullName': ownerFullName,
        'ownerWorkerPhone': ownerWorkerPhone,
        'ownerWorkerWeeklyHours': ownerWorkerWeeklyHours,
        'ownerWorkerServices': ownerWorkerServices,
      }..removeWhere((_, v) => v == null);

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    final data = OnboardingData(
      languageCode: json['languageCode'] as String?,
      role: json['role'] as String?,

      // owner
      ownerName: json['ownerName'] as String?,
      ownerSurname: json['ownerSurname'] as String?,
      ownerEmail: json['ownerEmail'] as String?,
      ownerPhoneDialCode: json['ownerPhoneDialCode'] as String?,
      ownerPhoneNumber: json['ownerPhoneNumber'] as String?,
      ownerPhoneE164: json['ownerPhoneE164'] as String?,
      ownerPassword: json['ownerPassword'] as String?,
      ownerWorkerType: json['ownerWorkerType'] as String?,
      ownerDateOfBirth: json['ownerDateOfBirth'] as String?,
      ownerGender: json['ownerGender'] as String?,

      // user residence
      countryIso2: json['countryIso2'] as String?,
      countryNameEn: json['countryNameEn'] as String?,
      cityCode: json['cityCode'] as String?,
      cityNameEn: json['cityNameEn'] as String?,
      districtCode: json['districtCode'] as String?,
      districtNameEn: json['districtNameEn'] as String?,

      // legacy coords (if present)
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),

      // provider
      providerCategoryCode: json['providerCategoryCode'] as String?,
      providerCategoryNameEn: json['providerCategoryNameEn'] as String?,
      businessName: json['businessName'] as String?,
      businessDescription: json['businessDescription'] as String?,
      businessEmail: json['businessEmail'] as String?,
      businessPhoneIso2: json['businessPhoneIso2'] as String?,
      businessPhoneDialCode: json['businessPhoneDialCode'] as String?,
      businessPhoneNumber: json['businessPhoneNumber'] as String?,

      // provider address (new)
      providerCityCode: json['providerCityCode'] as String?,
      providerCityNameEn: json['providerCityNameEn'] as String?,
      providerDistrictCode: json['providerDistrictCode'] as String?,
      providerDistrictNameEn: json['providerDistrictNameEn'] as String?,
      providerAddressLine1: json['providerAddressLine1'] as String?,
      providerAddressLine2: json['providerAddressLine2'] as String?,
      providerZipCode: json['providerZipCode'] as String?,
      providerLat: (json['providerLat'] as num?)?.toDouble(),
      providerLng: (json['providerLng'] as num?)?.toDouble(),

      // team/hours/services
      teamSize: json['teamSize'] as int?,
      weeklyHours: (json['weeklyHours'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
      services: (json['services'] as List?)
              ?.map((e) =>
                  ServiceDraft.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          <ServiceDraft>[],

      // owner-as-worker
      ownerAlsoWorker: json['ownerAlsoWorker'] as bool?,
      ownerFullName: json['ownerFullName'] as String?,
      ownerWorkerPhone: json['ownerWorkerPhone'] as String?,
      ownerWorkerWeeklyHours: (json['ownerWorkerWeeklyHours'] as Map?)
          ?.map((k, v) => MapEntry(k.toString(), v.toString())),
      ownerWorkerServices: (json['ownerWorkerServices'] as List?)
          ?.map((e) => (e as Map).cast<String, dynamic>())
          .toList(),
    );

    // Back-compat fill: if provider coords missing but legacy exist, copy over.
    data.providerLat ??= data.lat;
    data.providerLng ??= data.lng;

    return data;
  }
}
