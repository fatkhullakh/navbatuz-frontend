import 'package:dio/dio.dart';
import '../../services/api_service.dart';

enum WorkerStatus { AVAILABLE, UNAVAILABLE, ON_BREAK, ON_LEAVE }

WorkerStatus? statusFromString(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'AVAILABLE':
      return WorkerStatus.AVAILABLE;
    case 'UNAVAILABLE':
      return WorkerStatus.UNAVAILABLE;
    case 'ON_BREAK':
      return WorkerStatus.ON_BREAK;
    case 'ON_LEAVE':
      return WorkerStatus.ON_LEAVE;
  }
  return null;
}

String? statusToString(WorkerStatus? s) => s?.name;

class ProviderStaffService {
  final Dio _dio = ApiService.client;

  Future<List<StaffMember>> getProviderStaff(String providerId) async {
    final r = await _dio.get('/workers/provider/$providerId');
    final list = (r.data as List? ?? []);
    return list
        .whereType<Map>()
        .map((e) => StaffMember.fromWorkerJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Full details
  Future<StaffMember> getWorker(String workerId) async {
    final r = await _dio.get('/workers/$workerId');
    final m = (r.data as Map).cast<String, dynamic>();
    return StaffMember.fromWorkerJson(m);
  }

  /// Update worker using your UpdateWorkerRequest
  Future<StaffMember> updateWorker(
    String workerId, {
    String? name,
    String? surname,
    String? gender, // MALE/FEMALE/OTHER
    String? phoneNumber,
    String? email,
    String? avatarUrl,
    String? workerType, // DOCTOR, ...
    WorkerStatus? status, // AVAILABLE/UNAVAILABLE/ON_BREAK/ON_LEAVE
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    void put(String k, Object? v) {
      if (v == null) return;
      body[k] = v;
    }

    put('name', name);
    put('surname', surname);
    put('gender', gender);
    put('phoneNumber', phoneNumber);
    put('email', email);
    put('avatarUrl', avatarUrl);
    put('workerType', workerType);
    put('status', statusToString(status));
    put('isActive', isActive);

    final r = await _dio.put('/workers/$workerId', data: body);
    final m = (r.data as Map).cast<String, dynamic>();
    return StaffMember.fromWorkerJson(m);
  }

  /// Soft-delete (remove from team)
  Future<void> deactivate(String workerId) async {
    await updateWorker(workerId, isActive: false);
  }

  // availability (planned)
  Future<List<PlannedDay>> getPlanned(String workerId) async {
    final r = await _dio.get('/workers/public/availability/planned/$workerId');
    final list = (r.data as List? ?? []);
    return list.map((e) => PlannedDay.fromJson(e as Map)).toList();
  }

  Future<void> savePlanned(String workerId, List<PlannedDay> days) async {
    await _dio.post(
      '/workers/availability/planned/$workerId',
      data: days.map((d) => d.toApi()).toList(),
    );
  }

  // exceptions (actual availability)
  Future<List<ActualItem>> getActual(
      String workerId, DateTime from, DateTime to) async {
    String f = _d(from), t = _d(to);
    final r = await _dio.get('/workers/public/availability/actual/$workerId',
        queryParameters: {'from': f, 'to': t});
    final list = (r.data as List? ?? []);
    return list.map((e) => ActualItem.fromJson(e as Map)).toList();
  }

  Future<void> upsertActual(
    String workerId, {
    required DateTime date,
    required String startHHmm,
    required String endHHmm,
    int bufferMinutes = 0,
  }) async {
    await _dio.post('/workers/availability/actual/$workerId', data: {
      'date': _d(date),
      'startTime': _t(startHHmm),
      'endTime': _t(endHHmm),
      'bufferBetweenAppointments': 'PT${bufferMinutes}M',
    });
  }

  Future<void> deleteActual(String workerId, int availabilityId) async {
    await _dio.delete('/workers/availability/actual/$workerId/$availabilityId');
  }

  // breaks
  Future<List<BreakItem>> getBreaks(String workerId, DateTime day) async {
    final r = await _dio.get('/workers/public/availability/break/$workerId',
        queryParameters: {'from': _d(day), 'to': _d(day)});
    final list = (r.data as List? ?? []);
    return list.map((e) => BreakItem.fromJson(e as Map)).toList();
  }

  Future<void> addBreak(
    String workerId, {
    required DateTime date,
    required String startHHmm,
    required String endHHmm,
  }) async {
    await _dio.post('/workers/availability/break/$workerId', data: {
      'date': _d(date),
      'startTime': _t(startHHmm),
      'endTime': _t(endHHmm),
    });
  }

  Future<void> deleteBreak(String workerId, int breakId) async {
    await _dio.delete('/workers/availability/break/$workerId/$breakId');
  }

  // ---- helpers
  static String _d(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// backend accepts `HH:mm` or `HH:mm:ss` – send seconds to be safe
  static String _t(String hhmm) => hhmm.length == 5 ? '$hhmm:00' : hhmm;
}

class StaffMember {
  final String id; // workerId
  final String name; // fullName
  final String? providerName;
  final String? gender; // MALE/FEMALE/OTHER
  final String? phoneNumber;
  final String? email;
  final String? avatarUrl;
  final String? role; // workerType
  final WorkerStatus? status; // AVAILABLE/UNAVAILABLE/ON_BREAK/ON_LEAVE
  final double? avgRating;
  final String? hireDate;
  final bool isActive; // used only for "remove from team" (soft delete)

  const StaffMember({
    required this.id,
    required this.name,
    required this.isActive,
    this.providerName,
    this.gender,
    this.phoneNumber,
    this.email,
    this.avatarUrl,
    this.role,
    this.status,
    this.avgRating,
    this.hireDate,
  });

  String get displayName => name.trim().isEmpty ? '—' : name;

  StaffMember copyWith({
    String? name,
    String? providerName,
    String? gender,
    String? phoneNumber,
    String? email,
    String? avatarUrl,
    String? role,
    WorkerStatus? status,
    double? avgRating,
    String? hireDate,
    bool? isActive,
  }) {
    return StaffMember(
      id: id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      providerName: providerName ?? this.providerName,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      avgRating: avgRating ?? this.avgRating,
      hireDate: hireDate ?? this.hireDate,
    );
  }

  /// Works for both list (WorkerResponse) and details (WorkerDetailsDto).
  factory StaffMember.fromWorkerJson(Map<String, dynamic> m) {
    String? str(dynamic v) => v == null ? null : v.toString().trim();
    double? toD(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return StaffMember(
      id: str(m['id']) ?? '',
      name: str(m['fullName']) ?? str(m['name']) ?? '',
      providerName: str(m['providerName']),
      gender: str(m['gender']),
      phoneNumber: str(m['phoneNumber']),
      email: str(m['email']),
      avatarUrl: str(m['avatarUrl']),
      role: str(m['workerType']) ?? str(m['role']),
      status: statusFromString(str(m['status'])),
      avgRating: toD(m['avgRating']),
      hireDate: str(m['hireDate']),
      isActive: (m['isActive'] == true) || (m['active'] == true),
    );
  }

  /// Used when we only know workerId (e.g., worker self mode)
  static StaffMember stub(String id) => StaffMember(
        id: id,
        name: '—',
        isActive: true,
        providerName: null,
        gender: null,
        phoneNumber: null,
        email: null,
        avatarUrl: null,
        role: null,
        status: null,
        avgRating: null,
        hireDate: null,
      );
}

class PlannedDay {
  final String day; // MONDAY..SUNDAY
  String? start; // "HH:mm"
  String? end; // "HH:mm"
  int bufferMinutes;

  PlannedDay(this.day, {this.start, this.end, this.bufferMinutes = 0});

  factory PlannedDay.fromJson(Map m) {
    String _toHHmm(String s) {
      s = (s).toString();
      if (s.isEmpty) return '';
      return s.length >= 5 ? s.substring(0, 5) : s;
    }

    int _parseBuf(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      final s = v.toString(); // "PT15M" or "00:15:00"
      if (s.startsWith('PT') && s.endsWith('M')) {
        return int.tryParse(s.substring(2, s.length - 1)) ?? 0;
      }
      if (s.contains(':')) {
        final parts = s.split(':');
        return (int.tryParse(parts[0]) ?? 0) * 60 +
            (int.tryParse(parts[1]) ?? 0);
      }
      return int.tryParse(s) ?? 0;
    }

    return PlannedDay(
      (m['day'] ?? '').toString(),
      start: _toHHmm(m['startTime'] ?? ''),
      end: _toHHmm(m['endTime'] ?? ''),
      bufferMinutes: _parseBuf(m['bufferBetweenAppointments']),
    );
  }

  Map<String, dynamic> toApi() => {
        'day': day,
        'startTime': start == null || start!.isEmpty ? null : '${start!}:00',
        'endTime': end == null || end!.isEmpty ? null : '${end!}:00',
        'bufferBetweenAppointments': 'PT${bufferMinutes}M',
      }..removeWhere((k, v) => v == null);
}

class ActualItem {
  final int id;
  final DateTime date;
  String start; // "HH:mm"
  String end; // "HH:mm"
  int bufferMinutes;

  ActualItem(this.id, this.date, this.start, this.end, this.bufferMinutes);

  factory ActualItem.fromJson(Map m) {
    String _hhmm(String s) => s.length >= 5 ? s.substring(0, 5) : s;
    int _buf(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      final s = v.toString();
      if (s.startsWith('PT') && s.endsWith('M')) {
        return int.tryParse(s.substring(2, s.length - 1)) ?? 0;
      }
      if (s.contains(':')) {
        final p = s.split(':');
        return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
      }
      return int.tryParse(s) ?? 0;
    }

    return ActualItem(
      int.tryParse('${m['id']}') ?? 0,
      DateTime.parse(m['date']),
      _hhmm(m['startTime'] ?? ''),
      _hhmm(m['endTime'] ?? ''),
      _buf(m['bufferBetweenAppointments']),
    );
  }
}

class BreakItem {
  final int id;
  final DateTime date;
  final String start; // "HH:mm"
  final String end; // "HH:mm"

  BreakItem(this.id, this.date, this.start, this.end);

  factory BreakItem.fromJson(Map m) {
    String _hhmm(String s) => s.length >= 5 ? s.substring(0, 5) : s;
    return BreakItem(
      int.tryParse('${m['id']}') ?? 0,
      DateTime.parse(m['date']),
      _hhmm(m['startTime'] ?? ''),
      _hhmm(m['endTime'] ?? ''),
    );
  }
}
