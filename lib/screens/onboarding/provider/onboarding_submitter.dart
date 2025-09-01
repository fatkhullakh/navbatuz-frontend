import 'package:dio/dio.dart';
import 'package:frontend/models/onboarding_data.dart';
import 'package:frontend/services/api_service.dart';

class OnboardingSubmitResult {
  final String token;
  final String ownerUserId;
  final String providerId;
  final bool ownerWorkerCreated;
  OnboardingSubmitResult({
    required this.token,
    required this.ownerUserId,
    required this.providerId,
    required this.ownerWorkerCreated,
  });
}

class OnboardingSubmitter {
  final Dio _dio = ApiService.client;

  Future<OnboardingSubmitResult> submitAll(OnboardingData d) async {
    // Normalize explicit defaults
    d = d.copyWith(
      languageCode: (d.languageCode ?? 'en').toLowerCase(),
      countryIso2: (d.countryIso2 ?? 'UZ').toUpperCase(),
      role: (d.role ?? 'OWNER').toUpperCase(),
    );

    // --- A) Register OWNER (include DOB & gender) ---
    final ownerPhone = _composeOwnerPhone(d);
    final regBody = <String, dynamic>{
      'name': (d.ownerName ?? '').trim(),
      'surname': (d.ownerSurname ?? '').trim(),
      'email': (d.ownerEmail ?? '').trim(),
      'phoneNumber': ownerPhone,
      'password': (d.ownerPassword ?? '').trim(),
      'language': d.languageCode?.toUpperCase(), // EN | RU | UZ (backend style)
      'country': d.countryIso2,
      'role': 'OWNER',
      'dateOfBirth': d.ownerDateOfBirth, // YYYY-MM-DD
      'gender': d.ownerGender, // MALE|FEMALE|OTHER
    }..removeWhere((_, v) => v == null || (v is String && v.trim().isEmpty));

    if ((regBody['password'] as String?)?.length != null &&
        (regBody['password'] as String).length < 6) {
      throw StateError('Owner password must be at least 6 chars');
    }
    if (regBody['name'] == null ||
        regBody['surname'] == null ||
        regBody['email'] == null ||
        regBody['phoneNumber'] == null) {
      throw StateError('Owner registration data is incomplete');
    }

    final regRes = await _dio.post('/auth/register', data: regBody);
    final String token =
        (regRes.data is Map ? regRes.data['token'] : null)?.toString() ?? '';
    final String ownerUserId =
        (regRes.data is Map ? regRes.data['userId'] : null)?.toString() ?? '';

    if (token.isEmpty || ownerUserId.isEmpty) {
      throw StateError('Register failed: token/userId missing');
    }

    // set token immediately so subsequent calls are authorized
    await ApiService.setToken(token);
    await ApiService.setUserId(ownerUserId);

    // --- B) Login (optional but mirrors your logs; will refresh token if needed) ---
    try {
      final login = await _dio.post('/auth/login', data: {
        'email': (d.ownerEmail ?? '').trim(),
        'password': (d.ownerPassword ?? '').trim(),
      });
      final String t2 =
          (login.data is Map ? login.data['token'] : null)?.toString() ?? '';
      if (t2.isNotEmpty) await ApiService.setToken(t2);
    } catch (_) {
      // Ignore if login fails; you already have a token from /auth/register
    }

    // --- C) Create provider ---
    final providerId = await _createProvider(ownerUserId, d);

    // --- D) Location ---
    await _updateLocation(providerId, d);

    // --- E) Business hours ---
    final hours = _mapWeeklyHours(d.weeklyHours);
    if (hours.isNotEmpty) {
      await _dio.put('/providers/$providerId/business-hours', data: hours);
    }

    // --- F) Owner-as-worker (optional) ---
    bool ownerWorkerCreated = false;
    String? workerId;
    if (d.ownerAlsoWorker == true) {
      final resp = await _dio.post(
        '/providers/$providerId/owner-as-worker',
        data: {
          if ((d.ownerWorkerType ?? '').trim().isNotEmpty)
            'workerType': d.ownerWorkerType!.trim().toUpperCase(),
          'status': 'AVAILABLE',
          'isActive': true,
        },
      );
      ownerWorkerCreated = resp.statusCode == 200 || resp.statusCode == 201;
      // Worker id may be same as user id (MapsId); try to read it
      workerId = (resp.data is Map && resp.data['id'] != null)
          ? resp.data['id'].toString()
          : ownerUserId;

      // Planned availability mirrored from business weeklyHours
      final planned =
          _mapPlannedAvailability(d.ownerWorkerWeeklyHours ?? d.weeklyHours);
      if (planned.isNotEmpty && workerId != null && workerId.isNotEmpty) {
        await _dio.post('/workers/availability/planned/$workerId',
            data: planned);
      }
    }

    // --- G) Services (attach to worker if created) ---
    for (final s in d.services) {
      await _dio.post('/services',
          data: {
            'name': s.name,
            'description': s.description,
            'category': _mapServiceCategory(d.providerCategoryCode),
            'price': s.price,
            'duration': _isoFromMinutes(s.durationMinutes ?? 0),
            'providerId': providerId,
            'workerIds': (workerId == null || workerId.isEmpty)
                ? const <String>[]
                : <String>[workerId],
            if (s.imageUrl != null) 'imageUrl': s.imageUrl,
          }..removeWhere((_, v) => v == null));
    }

    return OnboardingSubmitResult(
      token:
          (await ApiService.client.options.headers['Authorization'] as String?)
                  ?.replaceFirst('Bearer ', '') ??
              token,
      ownerUserId: ownerUserId,
      providerId: providerId,
      ownerWorkerCreated: ownerWorkerCreated,
    );
  }

  /* ---------------- Provider ---------------- */

  Future<String> _createProvider(String ownerId, OnboardingData d) async {
    final phone =
        _composeE164(d.businessPhoneDialCode, d.businessPhoneNumber) ??
            d.ownerPhoneE164;

    final res = await _dio.post('/providers/public/register',
        data: <String, dynamic>{
          'ownerId': ownerId,
          'name': d.businessName ?? 'My Business',
          'description': d.businessDescription,
          'category': (d.providerCategoryCode ?? 'OTHER').toUpperCase(),
          'teamSize': d.teamSize ?? 1,
          'email': d.businessEmail,
          'phoneNumber': phone,
        }..removeWhere(
            (_, v) => v == null || (v is String && v.trim().isEmpty)));

    final id = (res.data is Map) ? res.data['id']?.toString() : null;
    if (id == null || id.isEmpty) {
      throw StateError('Provider id missing in /providers/public/register');
    }
    return id;
  }

  /* ---------------- Location ---------------- */

  Future<void> _updateLocation(String providerId, OnboardingData d) async {
    String _firstNonEmpty(List<String?> xs) => xs
        .firstWhere((v) => v != null && v.trim().isNotEmpty,
            orElse: () => 'Unknown')!
        .trim();

    final city = _firstNonEmpty(
        [d.providerCityNameEn, d.providerCityCode, d.cityNameEn, d.cityCode]);
    final district = _firstNonEmpty([
      d.providerDistrictNameEn,
      d.providerDistrictCode,
      d.districtNameEn,
      d.districtCode,
      null
    ]);

    final body = <String, dynamic>{
      'addressLine1': d.providerAddressLine1,
      'addressLine2': d.providerAddressLine2,
      'district': district == 'Unknown' ? null : district,
      'city': city.isEmpty ? 'Unknown' : city,
      'countryIso2':
          (d.countryIso2 ?? d.businessPhoneIso2 ?? 'UZ').toUpperCase(),
      'postalCode': d.providerZipCode,
      'latitude': d.providerLat,
      'longitude': d.providerLng,
    }..removeWhere((_, v) => v == null);

    await _dio.put('/providers/$providerId/location', data: body);
  }

  /* ---------------- Hours helpers ---------------- */

  List<Map<String, dynamic>> _mapWeeklyHours(Map<String, String>? weekly) {
    if (weekly == null || weekly.isEmpty) return const [];
    final List<Map<String, dynamic>> out = [];
    weekly.forEach((day, val) {
      final d = day.toString().toUpperCase();
      final v = (val).toString().trim();
      if (v.isEmpty || v.toUpperCase() == 'CLOSED') return;
      final parts = v.split('-');
      if (parts.length != 2) return;
      final start = parts[0].trim();
      final end = parts[1].trim();
      out.add({
        'day': d,
        'startTime': start.length == 5 ? '$start:00' : start,
        'endTime': end.length == 5 ? '$end:00' : end,
      });
    });
    return out;
  }

  List<Map<String, dynamic>> _mapPlannedAvailability(
      Map<String, String>? weekly,
      {int bufferMinutes = 0}) {
    if (weekly == null || weekly.isEmpty) return const [];
    final out = <Map<String, dynamic>>[];
    weekly.forEach((day, val) {
      final d = day.toString().toUpperCase();
      final v = (val).toString().trim();
      if (v.isEmpty || v.toUpperCase() == 'CLOSED') return;
      final parts = v.split('-');
      if (parts.length != 2) return;
      final start = parts[0].trim();
      final end = parts[1].trim();
      out.add({
        'day': d,
        'startTime': start.length == 5 ? '$start:00' : start,
        'endTime': end.length == 5 ? '$end:00' : end,
        'bufferBetweenAppointments': 'PT${bufferMinutes}M',
      });
    });
    return out;
  }

  /* ---------------- Misc utils ---------------- */

  String? _composeOwnerPhone(OnboardingData d) {
    final explicit = (d.ownerPhoneE164 ?? '').trim();
    if (explicit.isNotEmpty) return _normalizePlusDigits(explicit);
    final owner = _composeE164(d.ownerPhoneDialCode, d.ownerPhoneNumber);
    if ((owner ?? '').isNotEmpty) return owner;
    return _composeE164(d.businessPhoneDialCode, d.businessPhoneNumber);
  }

  String? _composeE164(String? dial, String? local) {
    final localDigits = (local ?? '').replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (localDigits.isEmpty) return null;
    var d = (dial ?? '').trim();
    if (d.isEmpty) d = '+';
    if (!d.startsWith('+')) d = '+$d';
    final dialDigits = d.replaceAll(RegExp(r'[^0-9\+]'), '');
    return '$dialDigits$localDigits';
  }

  String _normalizePlusDigits(String s) {
    var v = s.trim();
    if (!v.startsWith('+')) v = '+$v';
    return '+' + v.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _isoFromMinutes(int minutes) {
    if (minutes <= 0) return 'PT0S';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final b = StringBuffer('PT');
    if (h > 0) b.write('${h}H');
    if (m > 0) b.write('${m}M');
    if (h == 0 && m == 0) b.write('0S');
    return b.toString();
  }

  String _mapServiceCategory(dynamic c) {
    if (c == null) return 'OTHER';
    final s = c is String ? c : c.toString();
    final last = s.contains('.') ? s.split('.').last : s;
    return last.trim().toUpperCase();
  }
}
